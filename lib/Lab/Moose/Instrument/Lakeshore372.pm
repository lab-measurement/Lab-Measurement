package Lab::Moose::Instrument::Lakeshore372;

#ABSTRACT: Lakeshore Model 372 Temperature Controller

#
# TODO:
# HTRSET, HTRST, INNAME
# RAMP, RAMPST, ANALOG, QRDG, CRVHDR, CRVPT, DISPFLD, DISPLAY, DOUT,
use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

#use POSIX qw/log10 ceil floor/;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
);

has input_channel => (
    is      => 'ro',
    isa     => enum( [ 'A', 1 .. 16 ] ),
    default => 5,
);

has default_loop => (
    is      => 'ro',
    isa     => enum( [ 0, 1 ] ),
    default => 0,
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

my %channel_arg = ( channel => { isa => enum( [ 'A', 1 .. 16 ] ) } );
my %loop_arg    = ( loop    => { isa => enum( [ 0,   1 ] ), optional => 1 } );
my %output_arg  = ( output  => { isa => enum( [ 0,   1, 2 ] ) } );

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $lakeshore = instrument(
     type => 'Lakeshore372',
     connection_type => 'Socket',
     connection_options => {host => '192.168.3.24'},
     
     input_channel => '5', # set default input channel for all method calls
 );


 my $temp_5 = $lakeshore->get_T(channel => 5); # Get temperature for channel 5.
 my $resistance_5 = TODO


Example: Configure inputs

 # enable channels 1..3
 for my $channel (1..3) {
    $lakeshore->set_inset(
        channel => $channel,
        enabled => 1,
        dwell => 1,
        pause => 3,
        curve_number => 0, # no curve
        tempco => 1, # negative temp coeff
    );
 }
 # disable the other channels
 for my $channel ('A', 4..16) {
      $lakeshore->set_inset(
        channel => $channel,
        enabled => 0,
        dwell => 1,
        pause => 3,
        curve_number => 0, # no curve
        tempco => 1, # negative temp coeff
    );
 }
  
 # setup the enabled input channels 1,2,3 for 20μV voltage excitation:
 for my $channel (1..3) {
     $lakeshore->set_intype(
        channel => $channel,
        mode => 0,
        excitation => 3,
        # control input, ignored:
        autorange => 0,
        range => 1,
    );
 }
 


=head1 METHODS

=head2 get_T

 my $temp = $lakeshore->get_T(channel => $channel);

C<$channel> needs to be one of 'A', 1, ..., 16.


=head2 get_value

alias for C<get_T>.

=cut

sub get_T {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "KRDG? $channel", %args );
}

sub get_value {
    my $self = shift;
    return $self->get_T(@_);
}

=head2 get_sensor_units_reading

 my $reading = $lakeshore->get_sensor_units_reading(channel => $channel);

Get sensor units reading (in  ohm) of an input channel.

=cut

sub get_sensor_units_reading {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "SRDG? $channel", %args );
}

=head2 set_setpoint/get_setpoint

Set/get setpoint for loop 0 in whatever units the setpoint is using

 $lakeshore->set_setpoint(value => 10, loop => 0); 
 my $setpoint1 = $lakeshore->get_setpoint(loop => 0);
 
=cut

sub get_setpoint {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    return $self->query( command => "SETP? $loop", %args );
}

sub set_setpoint {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;

    # Device bug. The 340 cannot parse values with too many digits.
    $value = sprintf( "%.6G", $value );
    $self->write( command => "SETP $loop,$value", %args );
}

=head2 set_T

alias for C<set_setpoint>

=cut

sub set_T {
    my $self = shift;
    $self->set_setpoint(@_);
}

=head2 set_heater_range/get_heater_range

 $lakeshore->set_heater_range(output => 0, value => 1);
 my $range = $lakeshore->get_heater_range(output => 0);

For output 0 (sample heater), value is one of 0 (off), 1, ..., 8.
For outputs 1 and 2, value is one of 0 and 1.

=cut

sub set_heater_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %output_arg,
        value => { isa => enum( [ 0 .. 8 ] ) }
    );
    my $output = delete $args{output};
    $self->write( command => "RANGE $output, $value", %args );
}

sub get_heater_range {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
    );
    my $output = delete $args{output};
    return $self->query( command => "RANGE? $output", %args );
}

=head2 set_outmode/get_outmode

 $lakeshore->set_outmode(
  output => 0, # 0, 1, 2
  mode => 3, # 0, ..., 6
  channel => 5, # A, 1, ..., 16
  powerup_enable => 1, # (default: 0)
  polarity => 1, # (default: 0)
  filter => 1, # (default: 0)
  delay => 1, # 1,...,255
 );
 
 my $args = $lakeshore->get_outmode(output => 0);

=cut

sub set_outmode {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
        mode => { isa => enum( [ 0 .. 6 ] ) },
        %channel_arg,
        powerup_enable => { isa => enum( [ 0, 1 ] ), default => 0 },
        polarity       => { isa => enum( [ 0, 1 ] ), default => 0 },
        filter         => { isa => enum( [ 0, 1 ] ), default => 0 },
        delay => { isa => enum( [ 1 .. 255 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my ( $output, $mode, $powerup_enable, $polarity, $filter, $delay )
        = delete @args{qw/output mode powerup_enable polarity filter delay/};
    $self->write(
        command =>
            "OUTMODE $output, $mode, $channel, $powerup_enable, $polarity, $filter, $delay",
        %args
    );
}

sub get_outmode {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
    );
    my $output = delete $args{output};
    my $rv     = $self->query( command => "OUTMODE? $output", %args );
    my @rv     = split /,/, $rv;
    return (
        mode     => $rv[0], channel => $rv[1], powerup_enable => $rv[2],
        polarity => $rv[3], filter  => $rv[4], delay          => $rv[5]
    );
}

=head2 set_input_curve/get_input_curve

 # Set channel 5 to use curve 25
 $lakeshore->set_input_curve(channel => 5, value => 25);
 my $curve = $lakeshore->get_input_curve(channel => 5);

=cut

sub set_input_curve {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %channel_arg,
        value => { isa => enum( [ 0 .. 60 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    $self->write( command => "INCRV $channel,$value", %args );
}

sub get_input_curve {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "INCRV $channel", %args );
}

=head2 set_remote_mode/get_remote_mode

 $lakeshore->set_remote_mode(value => 0);
 my $mode = $lakeshore->get_remote_mode();

Valid entries: 0 = local, 1 = remote, 2 = remote with local lockout.

=cut

sub set_remote_mode {
    my ( $self, $value, %args )
        = validated_setter( \@_, value => { isa => enum( [ 0 .. 2 ] ) } );
    $self->write( command => "MODE $value", %args );
}

sub get_remote_mode {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "MODE?", %args );
}

=head2 set_pid/get_pid

 $lakeshore->set_pid(loop => 0, P => 1, I => 50, D => 50)
 my %PID = $lakeshore->get_pid(loop => 0);
 # %PID = (P => $P, I => $I, D => $D);
 
=cut

sub set_pid {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        P => { isa => 'Lab::Moose::PosNum' },
        I => { isa => 'Lab::Moose::PosNum' },
        D => { isa => 'Lab::Moose::PosNum' }
    );
    my ( $loop, $P, $I, $D ) = delete @args{qw/loop P I D/};
    $loop = $loop // $self->default_loop();
    $self->write(
        command => sprintf( "PID $loop, %.1f, %d, %d", $P, $I, $D ),
        %args
    );
}

sub get_pid {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    my $pid = $self->query( command => "PID? $loop", %args );
    my %pid;
    @pid{qw/P I D/} = split /,/, $pid;
    return %pid;
}

=head2 set_zone/get_zone

 $lakeshore->set_zone(
     loop => 0,
     zone => 1,
     top  => 10,
     P    => 25,
     I    => 10,
     D    => 20,
     mout => 0, # 0%
     range => 1,
     rate => 1.2, # 1.2 K / min
     relay_1 => 0,
     relay_2 => 0,
 );

 my %zone = $lakeshore->get_zone(loop => 0, zone => 1);
=cut

sub set_zone {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        zone => { isa => enum( [ 1 .. 10 ] ) },
        top  => { isa => 'Lab::Moose::PosNum' },
        P    => { isa => 'Lab::Moose::PosNum' },
        I    => { isa => 'Lab::Moose::PosNum' },
        D    => { isa => 'Lab::Moose::PosNum' },
        mout => { isa => 'Lab::Moose::PosNum', default => 0 },
        range => { isa => enum( [ 0 .. 8 ] ) },
        rate => { isa => 'Lab::Moose::PosNum' },
        relay_1 => { isa => enum( [ 0, 1 ] ), default => 0 },
        relay_2 => { isa => enum( [ 0, 1 ] ), default => 0 },
    );
    my (
        $loop, $zone, $top, $P, $I, $D, $mout, $range, $rate, $relay_1,
        $relay_2
        )
        = delete @args{
        qw/loop zone top P I D mout range rate relay_1 relay_2/};
    $loop = $loop // $self->default_loop;

    # if ( defined $mout ) {
    #     $mout = sprintf( "%.1f", $mout );
    # }
    # else {
    #     $mout = ' ';
    # }

    $self->write(
        command => sprintf(
            "ZONE $loop, $zone, %.6G, %.1f, %.1f, %d, $mout, $range, %.1f, $relay_1, $relay_2",
            $top, $P, $I, $D
        ),
        %args
    );
}

sub get_zone {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        zone => { isa => enum( [ 1 .. 10 ] ) }
    );
    my ( $loop, $zone ) = delete @args{qw/loop zone/};
    $loop = $loop // $self->default_loop;
    my $result = $self->query( command => "ZONE? $loop, $zone", %args );
    my %zone;
    @zone{qw/top P I D mout range rate relay_1 relay_2/} = split /,/, $result;
    return %zone;
}

=head2 set_filter/get_filter

 $lakeshore->set_filter(
     channel => 5,
     on      => 1,
     settle_time => 1, # (1s..200s) 
     window => 2, # % 2 percent of full scale window (1% ... 80%)
 );

 my %filter = $lakeshore->get_filter(channel => 5);

=cut

sub set_filter {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
        on => { isa => enum( [ 0, 1 ] ) },
        settle_time => { isa => enum( [ 1 .. 200 ] ) },
        window      => { isa => enum( [ 1 .. 80 ] ) }
    );
    my ( $channel, $on, $settle_time, $window )
        = delete @args{qw/channel on settle_time window/};
    $channel = $channel // $self->input_channel();

    $self->write(
        command => "FILTER $channel,$on,$settle_time,$window",
        %args
    );
}

sub get_filter {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my $result = $self->query( command => "FILTER? $channel", %args );

    my %filter;
    @filter{qw/on settle_time window/} = split /,/, $result;
    return %filter;
}

=head2 set_freq/get_freq

 # Set input channel 0 (measurement input) excitation frequency to 9.8Hz
 $lakeshore->set_freq(channel => 0, value => 1);

 my $freq = $lakeshore->get_freq(channel => 0);

Allowed channels: 0 (measurement input), 'A' (control input).
Allowed values: 1 = 9.8 Hz, 2 = 13.7 Hz, 3 = 16.2 Hz, 4 = 11.6 Hz, 5 = 18.2 Hz.


=cut

sub set_freq {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %channel_arg,
        value => { isa => enum( [ 1 .. 5 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    $self->write( command => "FREQ $channel,$value", %args );
}

sub get_freq {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "FREQ? $channel", %args );
}

=head2 set_common_mode_reduction/get_common_mode_reduction

 $lakeshore->set_common_mode_reduction(value => 1);
 my $cmr = $lakeshore->get_common_mode_reduction();

Allowed values: 0 and 1.

=cut

sub set_common_mode_reduction {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );
    $self->write( command => "CMR $value", %args );
}

sub get_common_mode_reduction {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "CMR?", %args );
}

=head2 set_mout/get_mout

 $lakeshore->set_mout(output => 0, value => 10);
 my $mout = $lakeshore->get_mout(output => 0);

=cut

sub set_mout {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %output_arg,
        value => { isa => 'Num' }
    );
    my $output = delete $args{output};
    $self->write( command => "MOUT $output, $value", %args );
}

sub get_mout {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
    );
    my $output = delete $args{output};
    return $self->query( command => "MOUT? $output" );
}

=head2 set_inset/get_inset

 $lakeshore->set_inset(
     channel => 1, # A, 1, ..., 16
     enabled => 1,
     dwell => 1,
     pause => 3,
     curve_number => 1,
     tempco => 1, # 1 or 2
 );

 my %inset = $lakeshore->get_inset(channel => 1);

=cut

sub set_inset {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
        enabled => { isa => enum( [ 0, 1 ] ) },
        dwell   => { isa => enum( [ 1 .. 200 ] ) },
        pause   => { isa => enum( [ 3 .. 200 ] ) },
        curve_number => { isa => enum( [ 0 .. 59 ] ) },
        tempco => { isa => enum( [ 1, 2 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my ( $enabled, $dwell, $pause, $curve_number, $tempco )
        = delete @args{qw/enabled dwell pause curve_number tempco/};
    $self->write(
        command =>
            "INSET $channel, $enabled, $dwell, $pause, $curve_number, $tempco",
        %args
    );
}

sub get_inset {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my $rv = $self->query( command => "INSET? $channel" );
    my %inset;
    @inset{qw/enabled dwell pause curve_number tempco/} = split /,/, $rv;
    return %inset;
}

=head2 set_intype/get_intype

 $lakeshore->set_intype(
     channel => 1, 
     mode => 0, # voltage excitation mode
     excitation => 3, # 20μV, only relevant for measurement input
     autorange => 0, # only relevant for control input
     range => 1, # only relevant for control input
     cs_shunt => 0, # default: 0
     units => 1, # Kelvin, default: 1

 my %intype = $lakeshore->get_intype(channel => 1);

=cut

sub set_intype {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
        mode => { isa => enum( [ 0, 1 ] ) },
        excitation => { isa => enum( [ 1 .. 22 ] ) },
        autorange  => { isa => enum( [ 0, 1, 2 ] ) },
        range      => { isa => enum( [ 1 .. 22 ] ) },
        cs_shunt   => { isa => enum( [ 0, 1 ] ), default => 0 },
        units      => { isa => enum( [ 1, 2 ] ), default => 1 },
    );

    my $channel = delete $args{channel} // $self->input_channel();
    my ( $mode, $excitation, $autorange, $range, $cs_shunt, $units )
        = delete @args{qw/mode excitation autorange range cs_shunt units/};
    $self->write(
        command =>
            "INTYPE $channel, $mode, $excitation, $autorange, $range, $cs_shunt, $units",
        %args
    );
}

sub get_intype {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my $rv = $self->query( command => "INTYPE? $channel" );
    my %intype;
    @intype{qw/mode excitation autorange range cs_shunt units/} = split /,/,
        $rv;
    return %intype;
}

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=cut

__PACKAGE__->meta()->make_immutable();

1;
