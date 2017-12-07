package Lab::Moose::Instrument::OI_Mercury::Magnet;

#ABSTRACT: Oxford Instruments Mercury Cryocontrol magnet power supply

use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate 'validated_hash';
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use YAML::XS;

extends 'Lab::Moose::Instrument';

=head1 METHODS

The default channels are as follows:

=over

=item *

Temperature measurement: B<MB1.T1>.

=item *

Level meter: B<DB5.L1>

=item *

Magnet: B<GRPZ> (cannot be customized yet)

=back

=head2 get_catalogue

   $mcat = $m->get_catalogue();
   print "$mcat\n";

Returns the hardware configuration of the Mercury system. A typical response would be

   STAT:SYS:CAT:DEV:GRPX:PSU:DEV:MB1.T1:TEMP:DEV:GRPY:PSU:DEV:GRPZ:PSU:DEV:PSU.M1:PSU:DEV:PSU.M2:PSU:DEV:GRPN:PSU:DEV:DB5.L1:LVL
   
Here, each group starting with "DEV:" describes one hardware component.
In this case, we obtain for example:
  
   DEV:GRPX:PSU     |
   DEV:GRPY:PSU     |- a 3-axis magnet power supply unit
   DEV:GRPZ:PSU     |
   DEV:MB1.T1:TEMP  -- a temperature sensor
   DEV:DB5.L1:LVL   -- a cryogen level sensor
   
In each of these blocks, the second component after "DEV:" is the UID of the device;
it can be used in other commands such as get_level to address it.

=cut

sub get_catalogue {
    my ( $self, %args ) = validated_getter( \@_ );

    my $catalogue = $self->query( command => "READ:SYS:CAT", %args );
    return $catalogue;
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

    my $channel = delete $args{channel};

    my $temp
        = $self->query( command => "READ:DEV:$channel:TEMP:SIG:TEMP", %args );

    # typical response: STAT:DEV:MB1.T1:TEMP:SIG:TEMP:813.1000K

    $temp =~ s/^.*:SIG:TEMP://;
    $temp =~ s/K.*$//;
    return $temp;
}

=head2 get_he_level

   $level = $m->get_he_level(channel => 'DB5.L1');

Read out the designated liquid helium level meter channel. Result is in percent as calibrated.

=cut

sub get_he_level {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};

    my $level
        = $self->query( command => "READ:DEV:$channel:LVL:SIG:HEL", %args );

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:HEL:LEV:56.3938%:RES:47.8665O

    $level =~ s/^.*:LEV://;
    $level =~ s/%.*$//;
    return $level;
}

=head2 get_he_level_resistance

   $res = $m->get_he_level_resistance(channel => 'DB5.L1');

Read out the designated liquid helium level meter channel. Result is the raw sensor resistance.

=cut

sub get_he_level_resistance {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};

    my $res
        = $self->query( command => "READ:DEV:$channel:LVL:SIG:HEL", %args );

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:HEL:LEV:56.3938%:RES:47.8665O

    $res =~ s/^.*:RES://;

    $res =~ s/O$//;
    return $res;
}

=head2 get_n2_level

   $level = $m->get_n2_level(channel => 'DB5.L1');

Read out the designated liquid nitrogen level meter channel. Result is in percent as calibrated.

=cut

sub get_n2_level {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};
    my $level
        = $self->query( command => "READ:DEV:$channel:LVL:SIG:NIT", %args );

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:NIT:COUN:10125.0000n:FREQ:472867:LEV:52.6014%

    $level =~ s/^.*:LEV://;
    $level =~ s/%.*$//;
    return $level;
}

=head2 get_n2_level_frequency

   $frq = $m->get_n2_level_frequency(channel => 'DB5.L1');

Read out the designated liquid nitrogen level meter channel. Result is the raw internal frequency value.

=cut

sub get_n2_level_frequency {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str', default => 'DB5.L1' }
    );
    my $channel = delete $args{channel};
    my $level
        = $self->query( command => "READ:DEV:$channel:LVL:SIG:NIT", %args );

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:NIT:COUN:10125.0000n:FREQ:472867:LEV:52.6014%

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
        = $self->query( command => "READ:DEV:$channel:LVL:SIG:NIT", %args );

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:NIT:COUN:10125.0000n:FREQ:472867:LEV:52.6014%

    $level =~ s/^.*:COUN://;
    $level =~ s/n:.*$//;
    return $level;
}

#
# now follow the core magnet functions
#

=head2 oim_get_current

  $curr = $m->oim_get_current();

Reads out the momentary current of the PSU in Ampere. Only Z for now. 

TODO: what happens if we're in persistent mode?

=cut

sub oim_get_current {
    my ( $self, %args ) = validated_getter( \@_ );

    my $current
        = $self->query( command => "READ:DEV:GRPZ:PSU:SIG:CURR", %args );

    $current =~ s/^STAT:DEV:GRPZ:PSU:SIG:CURR://;
    $current =~ s/A$//;
    return $current;
}

=head2 oim_get_field

 $field = $m->oim_get_field();

Read PSU field in Tesla.

TODO: what happens if we're in persistent mode?

=cut

sub oim_get_field {
    my ( $self, %args ) = validated_getter( \@_ );

    my $field = $self->query( command => "READ:DEV:GRPZ:PSU:SIG:FLD", %args );

    $field =~ s/^STAT:DEV:GRPZ:PSU:SIG:FLD://;
    $field =~ s/T$//;
    return $field;
}

=head2 oim_get_heater

  $t = $m->oim_get_heater();

Returns the persistent mode switch heater status as B<ON> or B<OFF>. 

=cut

sub oim_get_heater {
    my ( $self, %args ) = validated_getter( \@_ );

    my $heater
        = $self->query( command => "READ:DEV:GRPZ:PSU:SIG:SWHT", %args );

    # typical response:
    # STAT:DEV:GRPZ:PSU:SIG:SWHT:OFF

    $heater =~ s/^STAT:DEV:GRPZ:PSU:SIG:SWHT://;
    return $heater;
}

=head2 oim_set_heater

 $m->oim_set_heater(value => 'ON');
 $m->oim_set_heater(value => 'OFF');

Switches the persistent mode switch heater.
Nothing happens if the power supply thinks the magnet current and the lead current are different.

=cut

sub oim_set_heater {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) },
    );

    my $heater = $self->query(
        command => "SET:DEV:GRPZ:PSU:SIG:SWHT:$value",
        %args
    );

    # typical response:
    # STAT:DEV:GRPZ:PSU:SIG:SWHT:OFF

    $heater =~ s/^STAT:DEV:GRPZ:PSU:SIG:SWHT://;
    return $heater;
}

=head2 oim_force_heater


Switches the persistent mode switch heater. Parameter is "ON" or "OFF". 

Dangerous. Works also if magnet and lead current are differing.

=cut

sub oim_force_heater {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) },
    );

    my $heater = $self->query(
        command => "SET:DEV:GRPZ:PSU:SIG:SWHN:$value",
        %args
    );

    # typical response:
    # STAT:DEV:GRPZ:PSU:SIG:SWHN:OFF

    $heater =~ s/^STAT:DEV:GRPZ:PSU:SIG:SWHN://;
    return $heater;
}

=head2 oim_get_current_sweeprate

 $rate = $m->oim_get_current_sweeprate();

Gets the current target sweep rate (i.e., the sweep rate with which we want to 
go to the target; may be bigger than the actual rate if it is hardware limited), 
in Ampere per minute.

=cut

sub oim_get_current_sweeprate {
    my ( $self, %args ) = validated_getter( \@_ );

    my $sweeprate
        = $self->query( command => "READ:DEV:GRPZ:PSU:SIG:RCST", %args );

    # this returns amps per minute
    $sweeprate =~ s/^STAT:DEV:GRPZ:PSU:SIG:RCST://;
    $sweeprate =~ s/A\/m$//;
    return $sweeprate;
}

=head2 oim_set_current_sweeprate

 $m->oim_set_current_sweeprate(value => 0.01);

Sets the desired target sweep rate, parameter is in Amperes per minute.

=cut

sub oim_set_current_sweeprate {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    my $result = $self->query(
        command => "SET:DEV:GRPZ:PSU:SIG:RCST:$value",
        %args
    );

    # this returns amps per minute
    $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:RCST://;
    $result =~ s/A\/m$//;
    return $result;
}

=head2 oim_get_field_sweeprate

 $rate = $m->oim_get_field_sweeprate();

Get sweep rate (Tesla/min).

=cut

sub oim_get_field_sweeprate {
    my ( $self, %args ) = validated_getter( \@_ );

    my $sweeprate
        = $self->query( command => "READ:DEV:GRPZ:PSU:SIG:RFST", %args );

    # this returns amps per minute
    $sweeprate =~ s/^STAT:DEV:GRPZ:PSU:SIG:RFST://;
    $sweeprate =~ s/T\/m$//;
    return $sweeprate;
}

=head2 oim_set_field_sweeprate

 $m->oim_set_field_sweeprate(value => 0.001); # 1mT / min

Set sweep rate (Tesla/min).

=cut

sub oim_set_field_sweeprate {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    my $result = $self->query(
        command => "SET:DEV:GRPZ:PSU:SIG:RFST:$value",
        %args
    );

    # this returns amps per minute
    $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:RFST://;
    $result =~ s/T\/m$//;
    return $result;
}

=head2 oim_get_activity

Retrieves the current power supply activity. See oim_set_activity for values.

=cut

sub oim_get_activity {
    my ( $self, %args ) = validated_getter( \@_ );

    my $action = $self->query( command => "READ:DEV:GRPZ:PSU:ACTN", %args );

    # typical response: STAT:DEV:GRPZ:PSU:ACTN:HOLD
    $action =~ s/^STAT:DEV:GRPZ:PSU:ACTN://;
    return $action;
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
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/HOLD RTOS RTOZ CLMP/] ) },
    );

    my $result
        = $self->query( command => "SET:DEV:GRPZ:PSU:ACTN:$value", %args );
    $result =~ s/^STAT:SET:DEV:GRPZ:PSU:SIG:ACTN://;
    return $result;
}

=head2 oim_set_current_setpoint

 $m->oim_set_current_setpoint(value => 0.001);

Sets the current set point in Ampere.

=cut

sub oim_set_current_setpoint {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    my $result = $self->query(
        command => "SET:DEV:GRPZ:PSU:SIG:CSET:$value",
        %args
    );
    $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:CSET://;
    $result =~ s/A$//;
    return $result;
}

=head2 oim_get_current_setpoint

 $sp = $m->oim_get_current_setpoint();

Get the current set point in Ampere.

=cut

sub oim_get_current_setpoint {
    my ( $self, $value, %args ) = validated_getter( \@_ );

    my $result = $self->query(
        command => "READ:DEV:GRPZ:PSU:SIG:CSET",
        %args
    );
    $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:CSET://;
    $result =~ s/A$//;
    return $result;
}

=head2 oim_set_field_setpoint

 $m->oim_set_field_setpoint(value => 0.01); # 10 mT

Set the field setpoint in Tesla.

=cut

sub oim_set_field_setpoint {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    my $result = $self->query(
        command => "SET:DEV:GRPZ:PSU:SIG:FSET:$value",
        %args
    );
    $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:FSET://;
    $result =~ s/T$//;
    return $result;
}

=head2 oim_get_field_setpoint

 $sp = $m->oim_get_field_setpoint();

Get the field setpoint in Tesla.

=cut

sub oim_get_field_setpoint {
    my ( $self, $value, %args ) = validated_getter( \@_ );

    my $result = $self->query(
        command => "READ:DEV:GRPZ:PSU:SIG:FSET",
        %args
    );
    $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:FSET://;
    $result =~ s/T$//;
    return $result;
}

=head2 oim_get_fieldconstant

Returns the current to field factor (A/T)

=cut

sub oim_get_fieldconstant {
    my ( $self, %args ) = validated_getter( \@_ );
    my $result = $self->query( command => "READ:DEV:GRPZ:PSU:ATOB", %args );
    $result =~ s/^STAT:DEV:GRPZ:PSU:ATOB://;
    return $result;
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
    return $self->oim_get_field();
}

sub set_persistent_mode {
    croak "persistent mode is not yet implemented";
}

sub get_persistent_field {
    croak "persistent mode is not yet implemented";
}

sub sweep_to_field {
    my ( $self, %args ) = validated_hash(
        \@_,
        target => { isa => 'Num' },
        rate   => { isa => 'Num' },
    );
    my $target = delete $args{target};
    my $rate   = delete $args{rate};

    $self->oim_set_field_sweeprate( value => $rate, %args );
    $self->oim_set_field_setpoint( value => $target, %args );
    $self->oim_set_activity( value => 'RTOS' );

    # wait until setpoint is reached
    while (1) {
        sleep 1;
        my $field = $self->oim_get_field(%args);

        if ( abs( $field - $target ) < $self->max_field_deviation() ) {
            last;
        }
    }
    return $self->oim_get_field(%args);
}

# This config_sweep can just handle step/list sweeps
sub config_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        points => { isa => 'Num' },
        rates  => { isa => 'Num' },
    );

    my $target = delete $args{points};
    my $rate   = delete $args{rates};

    return $self->sweep_to_field( target => $target, rate => $rate );
}

# In go_to_next_step, the XPRESS will call the sequence
# config_sweep(...);
# trg();
# wait();

# In our case, config sweep does it all; trg and wait are just stub functions.

sub trg {

    # do nothing
}

sub wait {

    # do nothing
}

sub active {

    # would be required for continous sweep
    return 0;
}

sub exit {
    my $self = shift;
    $self->oim_set_activity( value => 'HOLD' );
}

__PACKAGE__->meta()->make_immutable();

1;
