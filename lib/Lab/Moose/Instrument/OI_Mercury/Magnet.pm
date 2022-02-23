package Lab::Moose::Instrument::OI_Mercury::Magnet;

#ABSTRACT: Oxford Instruments Mercury magnet power supply

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate 'validated_hash';
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use YAML::XS;
use Lab::Moose::Countdown;

extends 'Lab::Moose::Instrument';

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has magnet => (
    is      => 'ro',
    isa     => enum( [qw/X Y Z/] ),
    default => 'Z'
);

has heater_delay => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosInt',
    default => 60
);

has ATOB => (
    is => 'ro',
    isa => 'Lab::Moose::PosNum',
    builder => '_build_ATOB',
    lazy => 1,
    );


sub _build_ATOB {
    my $self = shift;
    my $magnet = $self->magnet();
    return $self->oi_getter(cmd => "READ:DEV:GRP${magnet}:PSU:ATOB");
}



# default connection options:
around default_connection_options => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = $self->$orig();
    $options->{Socket}{port}    = 7020;
    $options->{Socket}{timeout} = 10;
    return $options;
};

with 'Lab::Moose::Instrument::OI_Common';

=head1 SYNOPSIS

 use Lab::Moose;

 my $magnet = instrument(
     type => 'OI_Mercury::Magnet',
     connection_type => 'Socket',
     connection_options => {host => '192.168.3.15'},
     magnet => 'X',    # 'X', 'Y' or 'Z'. default is 'Z'
 );

 say "He level (%): ", $magnet->get_he_level();
 say "N2 level (%): ", $magnet->get_n2_level();
 say "temperature: ",  $magnet->get_temperature();

 $magnet->oim_set_heater(value => 'ON');

 say "Current field (T): ", $magnet->get_field();
 
 # Sweep to 0.1 T with rate of 1 T/min
 $magnet->sweep_to_field(target => 0.1, rate => 1);

See L<https://github.com/lab-measurement/Lab-Measurement/blob/master/examples/RealWorld/level-plot.pl> for an example of a He/N2 level plotter.

=head1 METHODS

The default names for the used board names are as follows. You can
get the values for your instrument with the C<get_catalogue> method
and use the methods with the C<channel> argument.

=over

=item *

Temperature measurement: B<MB1.T1>.

=item *

Level meter: B<DB5.L1>

=item *

Magnet: B<Z> (use DEV:GRPZ:PSU)

The default can be changed to B<X> or B<Y> with the C<magnet> attribute in
the constructor as shown in SYNOPSIS.

=back

=head2 get_catalogue

   $mcat = $m->get_catalogue();
   print "$mcat\n";

Returns the hardware configuration of the Mercury system. A typical response would be

   DEV:GRPX:PSU:DEV:MB1.T1:TEMP:DEV:GRPY:PSU:DEV:GRPZ:PSU:DEV:PSU.M1:PSU:DEV:PSU.M2:PSU:DEV:GRPN:PSU:DEV:DB5.L1:LVL
   
Here, each group starting with "DEV:" describes one hardware component.
In this case, we obtain for example:
  
   DEV:GRPX:PSU     |
   DEV:GRPY:PSU     |- a 3-axis magnet power supply unit
   DEV:GRPZ:PSU     |
   DEV:MB1.T1:TEMP  -- a temperature sensor
   DEV:DB5.L1:LVL   -- a cryoliquid level sensor
   
In each of these blocks, the second component after "DEV:" is the UID of the device;
it can be used in other commands such as get_level to address it.

=cut

sub get_catalogue {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->oi_getter( cmd => "READ:SYS:CAT", %args );
}

=head2 get_temperature

   $t = $m->get_temperature();
   $t = $m->get_temperature(channel => 'MB1.T1'); # default channel is 'MB1.T1'

Read out the designated temperature channel. Result is in Kelvin.

=cut

sub get_temperature {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'MB1.T1' }
    );

    return $self->get_temperature_channel(%args);
}

=head2 get_he_level

   $level = $m->get_he_level(channel => 'DB5.L1');

Read out the designated liquid helium level meter. Result is in percent as calibrated.

=cut

sub get_he_level {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};

    my $rv
        = $self->oi_getter( cmd => "READ:DEV:$channel:LVL:SIG:HEL", %args );
    $rv =~ s/^LEV://;
    $rv =~ s/%.*$//;
    return $rv;
}

=head2 get_he_level_resistance

   $res = $m->get_he_level_resistance(channel => 'DB5.L1');

Read out the designated liquid helium level meter. Result is the raw sensor resistance.

=cut

sub get_he_level_resistance {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};

    my $res
        = $self->oi_getter( cmd => "READ:DEV:$channel:LVL:SIG:HEL", %args );
    $res =~ s/^.*:RES://;
    $res =~ s/O$//;
    return $res;
}

=head2 get_n2_level

   $level = $m->get_n2_level(channel => 'DB5.L1');

Read out the designated liquid nitrogen level meter. Result is in percent as calibrated.

=cut

sub get_n2_level {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};

    my $level
        = $self->oi_getter( cmd => "READ:DEV:$channel:LVL:SIG:NIT", %args );
    $level =~ s/^.*:LEV://;
    $level =~ s/%.*$//;
    return $level;
}

=head2 get_n2_level_frequency

   $frq = $m->get_n2_level_frequency(channel => 'DB5.L1');

Read out the designated liquid nitrogen level meter. Result is the raw internal frequency value.

=cut

sub get_n2_level_frequency {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};
    my $level
        = $self->oi_getter( cmd => "READ:DEV:$channel:LVL:SIG:NIT", %args );
    $level =~ s/^.*:FREQ://;
    $level =~ s/:.*$//;
    return $level;
}

sub get_n2_level_counter {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};

    my $level
        = $self->oi_getter( cmd => "READ:DEV:$channel:LVL:SIG:NIT", %args );
    $level =~ s/^COUN://;
    $level =~ s/n:.*$//;
    return $level;
}

#
# now follow the core magnet functions
#

sub validated_magnet_getter {
    my $args_ref   = shift;
    my %extra_args = @_;
    my ( $self, %args ) = validated_getter(
        $args_ref,
        channel => { isa => enum( [qw/X Y Z/] ), optional => 1 },
        %extra_args,
    );
    my $channel = delete $args{channel} // $self->magnet();
    $channel = "GRP$channel";
    return ( $self, $channel, %args );
}

sub validated_magnet_setter {
    my $args_ref   = shift;
    my %extra_args = @_;
    my ( $self, $value, %args ) = validated_setter(
        $args_ref,
        channel => { isa => enum( [qw/X Y Z/] ), optional => 1 },
        %extra_args,
    );

    my $channel = delete $args{channel} // $self->magnet();
    $channel = "GRP$channel";
    return ( $self, $value, $channel, %args );
}



=head2 oim_get_current

  $curr = $m->oim_get_current();

Reads out the momentary current of the PSU in Ampere.

TODO: what happens if we're in persistent mode?

=cut

sub oim_get_current {
    my ( $self, $channel, %args ) = validated_magnet_getter( \@_ );

    my $current
        = $self->oi_getter( cmd => "READ:DEV:$channel:PSU:SIG:CURR", %args );
    $current =~ s/A$//;
    return $current;
}

=head2 oim_get_persistent_current

 $field = $m->oim_get_persistent_current();

Read PSU current for persistent mode in Amps.

=cut

sub oim_get_persistent_current {
    my ( $self, $channel, %args ) = validated_magnet_getter( \@_ );

    my $current
        = $self->oi_getter( cmd => "READ:DEV:$channel:PSU:SIG:PCUR", %args );
    $current =~ s/A$//;
    return $current;
}


=head2 oim_get_field

 $field = $m->oim_get_field();

Read PSU field in Tesla.
Internally, this uses oim_get_current and calculates the field with the A-to-B factor.

Returns 0 when in persistent mode.

=cut

sub oim_get_field {
    my $self = shift;
    my $current = $self->oim_get_current(@_);
    my $rv = $current / $self->ATOB();
    return sprintf("%.6f", $rv);
}

=head2 oim_get_persistent_field

 $field = $m->oim_get_persistent_field();

Read PSU field for persistent mode in Tesla.
Internally, this uses oim_get_persistent_current and calculates the field with the A-to-B factor.

=cut

sub oim_get_persistent_field {
    my $self = shift;
    my $current = $self->oim_get_persistent_current(@_);

    my $rv = $current / $self->ATOB();
    return sprintf("%.6f", $rv)
}

=head2 oim_get_heater

  $t = $m->oim_get_heater();

Returns the persistent mode switch heater status as B<ON> or B<OFF>. 

=cut

sub oim_get_heater {
    my ( $self, $channel, %args ) = validated_magnet_getter( \@_ );
    return $self->oi_getter( cmd => "READ:DEV:$channel:PSU:SIG:SWHT", %args );
}

=head2 oim_set_heater

 $m->oim_set_heater(value => 'ON');
 $m->oim_set_heater(value => 'OFF');

Switches the persistent mode switch heater.
Nothing happens if the power supply thinks the magnet current and the lead current are different.

=cut

sub oim_set_heater {
    my ( $self, $value, $channel, %args ) = validated_magnet_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) },
    );

    return $self->oi_setter(
        cmd   => "SET:DEV:$channel:PSU:SIG:SWHT",
        value => $value,
        %args
    );
}

=head2 heater_on/heater_off

 $m->heater_on();
 $m->heater_off();

Enable/disable switch heater. Wait for 60s after changing the state of the
heater.

=cut

sub heater_on {
    my $self = shift;
    $self->oim_set_heater( value => 'ON' );
    countdown( $self->heater_delay, "OI Mercury heater ON: " );
}

sub heater_off {
    my $self = shift;
    $self->oim_set_heater( value => 'OFF' );
    countdown( $self->heater_delay(), "OI Mercury heater OFF: " );
}

=head2 in_persistent_mode

 if ($m->in_persistent_mode()) {
    ...
 }

Return 1 if in persistent mode; otherwise return false.

=cut

sub in_persistent_mode {
    my $self = shift;
    my $rv   = $self->oim_get_heater(@_);
    if ( $rv eq 'ON' ) {
        return;
    }
    elsif ( $rv eq 'OFF' ) {
        return 1;
    }
    else {
        croak("unknown heater setting $rv");
    }
}

=head2 oim_force_heater


Switches the persistent mode switch heater. Parameter is "ON" or "OFF". 

Dangerous. Works also if magnet and lead current are differing.

=cut

sub oim_force_heater {
    my ( $self, $value, $channel, %args ) = validated_magnet_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) },
    );

    return $self->oi_setter(
        cmd   => "SET:DEV:$channel:PSU:SIG:SWHN",
        value => $value, %args
    );
}

=head2 oim_get_current_sweeprate

 $rate = $m->oim_get_current_sweeprate();

Gets the current target sweep rate (i.e., the sweep rate with which we want to 
go to the target; may be bigger than the actual rate if it is hardware limited), 
in Ampere per minute.

=cut

sub oim_get_current_sweeprate {
    my ( $self, $channel, %args ) = validated_magnet_getter( \@_ );

    my $sweeprate
        = $self->oi_getter( cmd => "READ:DEV:$channel:PSU:SIG:RCST", %args );
    $sweeprate =~ s/A\/m$//;
    return $sweeprate;
}

=head2 oim_set_current_sweeprate

 $m->oim_set_current_sweeprate(value => 0.01);

Sets the desired target sweep rate, parameter is in Amperes per minute.

=cut

sub oim_set_current_sweeprate {
    my ( $self, $value, $channel, %args ) = validated_magnet_setter( \@_ );

    $value = sprintf("%.3f", $value);
    
    my $rv = $self->oi_setter(
        cmd   => "SET:DEV:$channel:PSU:SIG:RCST",
        value => $value, %args
    );

    # this returns amps per minute
    $rv =~ s/A\/m$//;
    return $rv;
}

=head2 oim_get_field_sweeprate

 $rate = $m->oim_get_field_sweeprate();

Get sweep rate (Tesla/min).

=cut

sub oim_get_field_sweeprate {
    my $self = shift;
    my $current_sweeprate = $self->oim_get_current_sweeprate(@_);
    my $rv = $current_sweeprate / $self->ATOB();
    return sprintf("%.6f", $rv);
}

=head2 oim_set_field_sweeprate

 $rate_setpoint = $m->oim_set_field_sweeprate(value => 0.001); # 1mT / min

Set sweep rate (Tesla/min).

=cut

sub oim_set_field_sweeprate {
    my $self = shift;
    my %args = @_;
    my $value = delete $args{value};
    $value = $value * $self->ATOB();
    my $rv = $self->oim_set_current_sweeprate(value => $value, %args);
    return $rv / $self->ATOB();
}

=head2 oim_get_activity

Retrieves the current power supply activity. See oim_set_activity for values.

=cut

sub oim_get_activity {
    my ( $self, $channel, %args ) = validated_magnet_getter( \@_ );
    return $self->oi_getter( cmd => "READ:DEV:$channel:PSU:ACTN", %args );
}

=head2 oim_set_activity

 $m->oim_set_activity(value => 'HOLD');

Sets the current activity of the power supply. Values are: 

  HOLD - hold current
  RTOS - ramp to set point
  RTOZ - ramp to zero
  CLMP - clamp output if current is zero

=cut

sub oim_set_activity {
    my ( $self, $value, $channel, %args ) = validated_magnet_setter(
        \@_,
        value => { isa => enum( [qw/HOLD RTOS RTOZ CLMP/] ) },
    );
    return $self->oi_setter(
        cmd   => "SET:DEV:$channel:PSU:ACTN",
        value => $value, %args
    );
}

=head2 oim_set_current_setpoint

 $setpoint = $m->oim_set_current_setpoint(value => 0.001);

Sets the current set point in Ampere.

=cut

sub oim_set_current_setpoint {
    my ( $self, $value, $channel, %args ) = validated_magnet_setter(
        \@_,
        value => { isa => 'Num' },
    );

    $value = sprintf("%.4f", $value);
    
    my $rv = $self->oi_setter(
        cmd   => "SET:DEV:$channel:PSU:SIG:CSET",
        value => $value, %args
    );
    $rv =~ s/A$//;
    return $rv;
}

=head2 oim_get_current_setpoint

 $sp = $m->oim_get_current_setpoint();

Get the current set point in Ampere.

=cut

sub oim_get_current_setpoint {
    my ( $self, $channel, %args ) = validated_magnet_getter( \@_ );

    my $result
        = $self->oi_getter( cmd => "READ:DEV:$channel:PSU:SIG:CSET", %args );
    $result =~ s/A$//;
    return $result;
}

=head2 oim_set_field_setpoint

 $m->oim_set_field_setpoint(value => 0.01); # 10 mT

Set the field setpoint in Tesla.

=cut

sub oim_set_field_setpoint {
    my $self = shift;
    my %args = @_;
    my $value = delete $args{value};
    
    $value = $value * $self->ATOB();

    my $rv = $self->oim_set_current_setpoint(value => $value, %args);

    $rv = $rv / $self->ATOB();
    return sprintf("%.6f", $rv);
}

=head2 oim_get_field_setpoint

 $sp = $m->oim_get_field_setpoint();

Get the field setpoint in Tesla.

=cut

sub oim_get_field_setpoint {
    my $self = shift;

    my $rv = $self->oim_get_current_setpoint(@_);

    return $rv / $self->ATOB();
}

=head2 oim_get_fieldconstant

Returns the current to field factor (A/T)

=cut

sub oim_get_fieldconstant {
    my ( $self, $channel, %args ) = validated_magnet_getter( \@_ );
    return $self->oi_getter( cmd => "READ:DEV:$channel:PSU:ATOB", %args );
}


=head2 field_step

Return the minimum field stepwidth of the magnet

=cut

sub field_step {
    my $self = shift;
    return 1e-4 / $self->oim_get_fieldconstant(@_);
}


############### XPRESS interface #####################

has device_settings =>
    ( is => 'ro', isa => 'HashRef', builder => 'build_device_settings' );

has max_field_deviation => ( is => 'ro', isa => 'Num', default => 0.0001 );

sub build_device_settings {
    return {
        has_switchheater => 0,    # for now
    };
}

sub get_field {
    my $self = shift;
    return $self->oim_get_field(@_);
}

sub get_persistent_field {
    my $self = shift;
    return $self->oim_get_persistent_field(@_);
}

sub sweep_to_field {
    my ( $self, %args ) = validated_getter(
        \@_,
        target => { isa => 'Num' },
        rate   => { isa => 'Num' },
    );

    my $point = delete $args{target};
    my $rate  = delete $args{rate};

    $self->config_sweep( point => $point, rate => $rate, %args );

    $self->trg(%args);

    $self->wait(%args);

    return $self->oim_get_field(%args);
}

sub config_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        point => { isa => 'Num' },
        rate  => { isa => 'Num' },
    );
    my $target = delete $args{point};
    my $rate   = delete $args{rate};

    my $setrate = $self->oim_set_field_sweeprate( value => $rate, %args );
    my $setpoint = $self->oim_set_field_setpoint( value => $target, %args );
    if ( $self->verbose() ) {
        say "config_sweep: setpoint: $setpoint (T), rate: $setrate (T/min)";
    }
}

# In go_to_next_step, the XPRESS will call the sequence
# config_sweep(...);
# trg();
# wait();

sub trg {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->oim_set_activity( value => 'RTOS', %args );
}

sub wait {
    my ( $self, %args ) = validated_getter( \@_ );
    my $target  = $self->oim_get_field_setpoint(%args);
    my $verbose = $self->verbose();

    # enable autoflush
    my $autoflush = STDOUT->autoflush();
    my $last_field;
    my $time_step = 1;
    while (1) {
        sleep $time_step;
        my $field = $self->oim_get_field(%args);

        if ($verbose) {
            my $rate;
            if ( defined $last_field ) {
                $rate = ( $field - $last_field ) * 60 / $time_step;
                $rate = sprintf( "%.5g", $rate );
            }
            else {
                $rate = "unknown";
            }
            printf(
                "Field: %.6e T, Estimated rate: $rate T/min       \r",
                $field
            );
            $last_field = $field;
        }

        if ( abs( $field - $target ) < $self->max_field_deviation() ) {
            last;
        }
    }

    if ($verbose) {
        print " " x 70 . "\r";
    }

    # reset autoflush to previous value
    STDOUT->autoflush($autoflush);

}

sub active {
    my $self = shift;

    # with the legacy command set, one could use the "X" command to find
    # whether the magnet has finshed the sweep
    # We do it manually by comparing field and setpoint.
    my $field  = $self->oim_get_field();
    my $target = $self->oim_get_field_setpoint();
    if ( abs( $field - $target ) < $self->max_field_deviation() ) {
        return 0;
    }
    else {
        return 1;
    }
}

sub exit {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->oim_set_activity( value => 'HOLD', %args );
}

__PACKAGE__->meta()->make_immutable();

1;
