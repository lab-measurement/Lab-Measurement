use Lab::Moose;
use Lab::Moose::Countdown;
use 5.010;


use Time::HiRes qw/time/;

my $current_to_field_factor_z = 13.919;
my $voltage_gain_femto = 100;

# my $B_offset = -1.427e-3;
# my $B_range = 12e-3;
my @B_vals = linspace(
    from => -1.5e-3,
    to => 7e-3,
    step => 2e-6
    );

my $pre_resistor = 1e6;

my $num_sheets = 2000 / 16;

my $iv_time = 4; # 1 second per IV
my $num_readings = 1000; # 10000 points per IV
my $max_yoko_level = 3; # ramp yoko from 0 to $max_yoko_level
my $sample_time = $iv_time / $num_readings; # 1 ms
my $nplc = 0.2;
my $sleep_time = 5;


my $folder = datafolder(path => 'IV_fast_');
my $datafile = datafile(folder => $folder, filename => 'data.dat',
                        columns => [qw/B T_Ruox time current voltage/]);


# make sure that Mercury-IPS turns switch heater on
#my $switch_heater = instrument(
#    type => 'OI_Mercury::Magnet',
#    connection_type => 'Socket',
#    connection_options => {host => '192.168.3.16'},
#    magnet => 'Z',    # 'X', 'Y' or 'Z'. default is 'Z'
#    );
#say $switch_heater->query(command => "*IDN?");
#if ($switch_heater->oim_get_heater() eq 'OFF') {
#    say "heater is off";
#    $switch_heater->heater_on();
#}


my $lakeshore = instrument(
    type => 'Lakeshore372',
    connection_type => 'VISA::GPIB',
    connection_options => {pad => 12},
     
    input_channel => '1', # set default input channel for all method calls
    );

say $lakeshore->idn();
my $T_Ruox = $lakeshore->get_T(channel => 1);
say "Sample temp: ", $T_Ruox;

my $magnet_z = instrument(
    type => 'KeysightB2901A',
    connection_type => 'VISA::GPIB',
    connection_options => {gpib_address => 23},
    # mandatory protection settings
    max_units_per_step => 0.0001, # 1mA
    max_units_per_second => 0.1,
    min_units => -3,
    max_units => 3,
);
say $magnet_z->idn();

# Source current
$magnet_z->source_function(value => 'CURR');
$magnet_z->source_range(value => 1);


my $yoko = instrument(
    type => 'YokogawaGS200',
    connection_type => 'VISA::GPIB',
    connection_options => {gpib_address => 3},
    # mandatory protection settings
    max_units_per_step => 10,
    max_units_per_second => 10,
    min_units => -32,
    max_units => 32,
    );
say $yoko->idn();


my $dmm = instrument(
    type => 'Keysight34470A',
    connection_type => 'VISA::USB',
    connection_options => {
        serial => 'MY57700806',
        timeout => 5, # if not given, use connection's default timeout
    }
    );

say $dmm->idn();
$dmm->write(command => 'SENS:VOLT:ZERO:AUTO OFF'); # disable auto zero alogrithm
$dmm->sense_range(value => 10); # ensure manual range

# trigger setup
$dmm->sense_nplc(value => 0.06);
$dmm->write(command => "SAMP:COUN  $num_readings"); # measure 25000 points
$dmm->write(command => 'SAMP:SOUR TIM'); # defined time between samples
$dmm->write(command => "SAMP:TIM $sample_time");
$dmm->write(command => 'TRIG:SOUR EXT'); # external 
$dmm->write(command => 'TRIG:COUN 1'); # accept 1 trigger and go to idle again
$dmm->write(command => 'TRIG:DELAY 0'); 
$dmm->write(command => 'FORM:DATA REAL,64');
$dmm->write(command => 'FORM:BORD NORM');

say "sampling time: ", $dmm->query(command => "SAMP:TIM?");


$yoko->write( command => 'PROG:REP 0');
$yoko->write( command => "PROG:INT $iv_time" ); # program interval
$yoko->write( command => "PROG:SLOP $iv_time"); # proram slope time 
$yoko->write( command => 'PROG:EDIT:STAR'); # start editing points
$yoko->write( command => "SOUR:LEV $max_yoko_level"); # source level point
$yoko->write( command => 'PROG:EDIT:END' );
$yoko->set_level(value => 0);
my $t0 = time();

for my $B (@B_vals) {
    say "B = $B";
    $magnet_z->set_level(value => $B * $current_to_field_factor_z);
    my $B_set = $magnet_z->get_level() / $current_to_field_factor_z;
    $yoko->set_level(value => 0);
    $dmm->write(command => 'INIT');
    countdown($sleep_time);
    # do sweep
    $yoko->write(command => 'PROG:RUN');
    my $data = $dmm->binary_query(command => 'FETC?', read_length => $num_readings * 8 + 10, timeout => 5);
    $data = substr($data, 2);
    $data =~ s/\n$//;
    my @readings = unpack('d>*', $data);
    say "number of readings: ", (@readings + 0);
    my @voltages = map {$_ / $voltage_gain_femto} @readings;
    my @currents = map {$_ * $max_yoko_level / ($num_readings * $pre_resistor)} (1..$num_readings);
    $datafile->log_block(
	prefix => {B => $B_set, T_Ruox => $T_Ruox, time => time() - $t0},
	block => [\@currents, \@voltages],
	add_newline => 1,
	);
}


$magnet_z->set_level(value => 0);
$yoko->set_level(value => 0);
