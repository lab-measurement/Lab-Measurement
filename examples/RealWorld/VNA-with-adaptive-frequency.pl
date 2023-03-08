# time per sweep:
# 200 points, BW = 5Hz, Selectivity=High => 120s / sweep

use Lab::Moose;
use Lab::Moose::Countdown;
use Lab::Moose::Stabilizer;
use 5.010;
use List::Util 'sum';

use Time::HiRes qw/time sleep/;

#my $f_center = 4.3e6;
#my $f_span = $f_center / 5;
my $f_start_orientation  = 3.9e6;
my $f_stop_orientation   = 4.6e6;
my $f_points_orientation = 200;
my $f_points             = 50;

my $bw             = 10;
my $bw_selectivity = 'NORM';

#my $T_set = 110e-3;

my $power = -100;

#my @P_vals = (-80, -85, -90, -95, -100, -105);

my $current_to_field_factor_z = 13.919;
my $B_offset                  = -657e-6;
my $B_range                   = 70e-6;

#my (@B_vals) = (0);

my @B_vals = linspace(
    from => $B_offset - $B_range,
    to   => $B_offset + $B_range,
    step => 3e-6,
);

my $pre_resistor_dc = 1e6;
my $I_range         = 3e-6;
my $I_step          = $I_range / 30;
my @I_vals = ( linspace( from => 0, to => $I_range, step => $I_step ) );

#	      linspace(from => $I_range, to => -$I_range, step => $I_step));
#	      linspace(from => -$I_range, to => 0, step => $I_step));

my $pre_attenuators = -70;

my $num_sheets = 2000 / 16;

my $folder = datafolder( path => 'L_of_I_' );

my $lakeshore = instrument(
    type               => 'Lakeshore372',
    connection_type    => 'VISA::GPIB',
    connection_options => { pad => 12 },

    input_channel => '1',    # set default input channel for all method calls
);

say $lakeshore->idn();
$lakeshore->set_heater_range( output => 0, value => 3 );

# $lakeshore->set_setpoint(loop => 0, value => $T_set);

my $magnet_x = instrument(
    type               => 'OI_Mercury::Magnet',
    connection_type    => 'Socket',
    connection_options => { host => '192.168.3.16' },
    magnet => 'X',           # 'X', 'Y' or 'Z'. default is 'Z'
);

my $B_x;
if ( $magnet_x->in_persistent_mode() ) {
    $B_x = $magnet_x->get_persistent_field();
}
else {
    die "magnet not in persistent mode";
}
say "persistent field in x-direction: ${B_x}";
my $magnet_z = instrument(
    type               => 'KeysightB2901A',
    connection_type    => 'VISA::GPIB',
    connection_options => { gpib_address => 24 },

    # mandatory protection settings
    max_units_per_step   => 0.0001,    # 1mA
    max_units_per_second => 0.1,
    min_units            => -3,
    max_units            => 3,
);
say $magnet_z->idn();

# Source current
$magnet_z->source_function( value => 'CURR' );
$magnet_z->source_range( value => 0.1 );

my $yoko_heater = instrument(
    type               => 'YokogawaGS200',
    connection_type    => 'VISA::GPIB',
    connection_options => { gpib_address => 3 },

    # mandatory protection settings
    max_units_per_step   => 32,
    max_units_per_second => 1000,
    min_units            => -32,
    max_units            => 32,
);

my $yoko_dc = instrument(
    type               => 'YokogawaGS200',
    connection_type    => 'VISA::GPIB',
    connection_options => { gpib_address => 2 },

    # mandatory protection settings
    max_units_per_step   => 0.01,
    max_units_per_second => 1,
    min_units            => -32,
    max_units            => 32,
);
say $yoko_dc->idn();

my $vna = instrument(
    type               => 'RS_ZNL',
    connection_type    => 'VISA::GPIB',
    connection_options => { pad => 20 },
);
say $vna->idn();

$vna->sense_bandwidth_resolution( value => $bw );
$vna->sense_bandwidth_resolution_select( value => $bw_selectivity );
$vna->source_power_level_immediate_amplitude(
    value => $power - $pre_attenuators );

my $t0 = time();

for my $B (@B_vals) {
    say "B = $B";

    my $datafile = datafile(
        folder  => $folder, filename => "data_B=${B}.dat",
        columns => [
            qw/B_x B_z T_Ruox time I_DC P_ac freq Re_S21 Im_S21 amplitude phase/
        ]
    );

    $magnet_z->set_level( value => $B * $current_to_field_factor_z );
    my $B_set = $magnet_z->get_level() / $current_to_field_factor_z;

    for my $sign ( -1, 1 ) {

        $yoko_dc->set_level( value => 0 );    # heat pulse with zero current
                                              # 	#apply heat pulse
        $yoko_heater->set_level( value => 1 );    # 1mW
        countdown(6);
        $yoko_heater->set_level( value => 0 );
        countdown( 10 * 60 );

        if ( $sign == -1 ) {
            $yoko_dc->set_level( value => 0 );

            # orientation sweep to find sweep boundaries
            $vna->sense_sweep_points( value => $f_points_orientation );
            $vna->sense_frequency_start( value => $f_start_orientation );
            $vna->sense_frequency_stop( value => $f_stop_orientation );
            say "orientation sweep";
            my $vna_block = $vna->sparam_sweep( timeout => 1000 );

            my ( $f_start, $f_stop ) = find_fstart_fstop($vna_block);
            say "f_start = $f_start, f_stop = $f_stop";
            $vna->sense_sweep_points( value => $f_points );
            $vna->sense_frequency_start( value => $f_start );
            $vna->sense_frequency_stop( value => $f_stop );
        }
        for my $I_DC (@I_vals) {
            my $I = $sign * $I_DC;

            $yoko_dc->set_level( value => $I * $pre_resistor_dc );

            my $I_set = $yoko_dc->get_level() / $pre_resistor_dc;
            say "I = $I_set";
            my $time = time() - $t0;
            say "power: ", $lakeshore->get_sample_heater_output();

            my $T_Ruox = $lakeshore->get_T( channel => 1 );
            say "temp: $T_Ruox";
            say "time: $time, starting sweep...";
            my $vna_block = $vna->sparam_sweep( timeout => 1000 );
            say "finished sweep";

            $datafile->log_block(
                prefix => {
                    B_x  => $B_x,   B_z    => $B_set,  I_DC => $I_set,
                    P_ac => $power, T_Ruox => $T_Ruox, time => $time
                },
                block       => $vna_block,
                add_newline => 1,
            );
        }
    }

}

$yoko_dc->set_level( value => 0 );

#$lakeshore->set_heater_range(output => 0, value => 0);

sub find_fstart_fstop() {
    my $vna_block = shift;
    $vna_block = $vna_block->unpdl;
    my @f_vals = @{ $vna_block->[0] };
    my @s_vals = @{ $vna_block->[3] };
    @s_vals = map { 10**( $_ / 20 ) } @s_vals;    # db to linear voltage
    my $N     = 5;
    my @max_s = (0) x $N;
    my @max_f = (0) x $N;

    # find 5 largest values in spectrum
    for my $i ( 0 .. $#f_vals ) {
        if ( $s_vals[$i] > $max_s[0] ) {
            push @max_s, $s_vals[$i];
            push @max_f, $f_vals[$i];
            shift @max_s;
            shift @max_f;
        }
    }
    my $f_center = sum(@max_f) / $N;
    my $Q        = sum(@max_s) / $N * 760;
    if ( $Q > 45 ) {
        $Q = 30;
    }
    say "estimate for Q = $Q";
    return ( $f_center - $f_center / $Q, $f_center + $f_center / $Q );
}
