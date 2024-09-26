package Lab::Moose::Instrument::AMI_430;

#ABSTRACT: American Magnetics magnet power supply
use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params validated_no_param_setter/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Time::HiRes qw (usleep);

extends 'Lab::Moose::Instrument';

=pod

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $magnet_z = instrument(
     type            => 'AMI_430',
     connection_type => 'Socket',
     connection_options => { host => '169.254.226.70' },
     max_field => 1.0,
     max_rate  => 0.1,
 );

 $magnet_sweep = sweep(
    type  => 'Continuous::Magnet',
    instrument => $magnet_z,
    from => -0.2, to => 0.2, interval => 1,
 )

Setting the maximum allowed field strength and the maximum rate are mandatory.
This model allows to change the units for field strength (kG/T) and time
(min/s).
You can check this in the menu on the front panel.
For security purposes this driver does not allow changing those critical
settings.

=head1 METHODS

=cut

has max_field => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosNum',
    required => 1,
);

has max_rate => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosNum',
    required => 1,
);

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has persistent_mode => ( 
    is => 'ro', 
    isa => 'Bool', 
    builder => '_persistent_builder',
    lazy => 1,
);

#subroutines needed: heater_off, in_persistent_mode, get_persistent_field, heater_on

#heater off: turns off the switch heater
#heater on: turns on the switch heater 
#get_persistent_field: gives back the applied persistent field - done
#in_persistent_mode: gives back whether the magnet is in the persistent mode or not - done

sub _persistent_builder {
    my $self = shift;
    return $self -> query( command => " PSwitch:INSTalled?");
}

sub BUILD {
  my $self = shift;

  $self->clear();
  $self->cls();
}

around default_connection_options => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = $self->$orig();
    $options->{Socket}{port}    = 7180;
    $options->{Socket}{timeout} = 10;
    $options->{Socket}{write_termchar} = "\r\n";
    
    return $options;
};

sub cls {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "*CLS", %args );
}

=head2 idn

 say $magnet_z->idn();

Returns the identification string of the device. It contains the AMI model
number and firmware revision code.

=cut

sub idn {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "*IDN?", %args );
}

sub get_field_ramp_rate {
    my ( $self, %args ) = validated_getter(
        \@_
    );
    return $self->query( command => "RAMP:RATE:FIELD:1?", %args );
}

sub set_field_ramp_rate {
    my ( $self, $value, %args )  = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );
    my $max_rate = $self->max_rate();
    if( $value > $max_rate ) {
        croak("Ramp rate $value T/min higher than max rate $max_rate T/min!");
    }
    my $max_field = $self->max_field();
    return $self->write( command => "CONFIGURE:RAMP:RATE:FIELD 1,$value,$max_field", %args );
}

sub get_field {
    my ( $self, %args ) = validated_getter(
        \@_
    );
    return $self->query( command => "FIELD:MAGNET?", %args );
}

sub get_voltage {
    my ( $self, %args ) = validated_getter(
        \@_
    );
    return $self->query( command => "VOLTage:SUPPly?", %args );
}

sub get_persistent_field {
    my ( $self, %args ) = validated_getter( \@_ );
    if ( $self -> persistent_mode == 0) {
        croak ( "No persistent switch installed!" );
    }
    return $self->query( command => "FIELD:MAGnet?");
}

sub in_persistent_mode {
    my ( $self, %args ) = validated_getter( \@_ );
    if ( $self -> persistent_mode == 0) {
        croak ( "No persistent switch installed!" );
    }
    my $status = $self->query( command => "PERSistent?");
    if ( $status == 0) {
        return 0;
    }
    else {
        return 1;
    }
}

sub set_switch_heater {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => {isa => enum( [ 0,1 ] ) },
    );
    if ( $self -> persistent_mode == 0) {
        croak ( "No persistent switch installed!" );
    }
    if ($value == 0) {
        return $self->query( command => "PSwitch 0" );
    }
    else {
        return $self->query( command => "PSwitch 1" );
    }
}

sub heater_on {
   my ( $self, $value, %args ) = validated_setter(
        \@_,
   );
   if ( $self -> persistent_mode == 0) {
        croak ( "No persistent switch installed!" );
   }
   $self ->query( command => "PSwitch?");
   if ($self == 0) {
        return $self->set_switch_heater(value => 1);
   }
   else {
    croak ( "The switch heater is already turned on." );
   }
}

sub heater_off {
   my ( $self, $value, %args ) = validated_setter(
        \@_,
   );
   if ( $self -> persistent_mode == 0) {
        croak ( "No persistent switch installed!" );
   }
   $self ->query( command => "PSwitch?");
   if ($self == 1) {
        return $self->set_switch_heater(value => 0);
   }
   else {
    croak("The switch heater is already turned off.");
   }
}

sub get_value {
    my ( $self, %args ) = validated_getter(
        \@_
    );
    return $self->get_field(@_);
}

sub get_target_field {
    my ( $self, %args ) = validated_getter(
        \@_
    );
    return $self->query( command => "FIELD:TARGET?", %args );  
}

sub set_target_field {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );
    my $max_field = $self->max_field();
    if( $value > $max_field ) {
        croak("Requested field $value T higher than allowed maximum field strength $max_field T!");
    }
    return $self->write( command => "CONFIGURE:FIELD:TARGET $value", %args );
}

=head2 sweep_to_field

 $magnet_z->sweep_to_field( target => 0.5, rate => 0.02 );

Checks the provided field strength and rate and starts a sweep.
This function waits for the device to finish.

=cut

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
    return $self->get_field(%args);
}

sub ramp {
    my ( $self, %args ) = validated_getter( \@_ );
    
    my $ret_val = $self->write( command => "RAMP", %args );
    while ($self->active()) {
        sleep(2);
    }
    return $ret_val;
}

=head2 to_zero

 $magnet_z->to_zero()

Sweeps back to zero with the maximum allowed rate.
This function waits for the device to finish.

=cut

sub to_zero {
    my ( $self, %args ) = validated_getter(
        \@_
    );
    my $ret_val = $self->write( command => "ZERO", %args );
    while ($self->active()) {
        sleep(2);
    }
    return $ret_val;
}

# Methods for sweep

sub config_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        point => { isa => 'Num' },
        rate  => { isa => 'Num' },
    );
    my $target = delete $args{point};
    my $rate   = delete $args{rate};

    $self->set_target_field( value => $target, %args );
    $self->set_field_ramp_rate( value => $rate, %args );

    my $current_field = $self->get_field();
    $self->_check_sweep_parameters(
        current => $current_field, target => $target,
        rate    => $rate
    );
    if ( $self->verbose() ) {
        say "config_sweep: target: $target (T), rate: $rate (T/min)";
    }
}

sub trg {
    my ( $self, %args ) = validated_getter(
        \@_
    );
    return $self->write( command => "RAMP", %args );
}

sub active {
    my ( $self, %args ) = validated_getter(
        \@_,
    );
    my $status = $self->query( command => "STATE?", %args );
    # Holding at the target field OR At zero current
    if($status eq 2 || $status eq 8) {
        return 0
    } else {
        return 1
    }
}

sub wait {
    my ( $self, %args ) = validated_getter(
        \@_,
    );

    my $autoflush = STDOUT->autoflush();

    while ($self->active()) {
        sleep(1);
        printf( "Field: %.3fT\r", $self->get_field(%args) );
    }
    
    STDOUT->autoflush($autoflush);
}

sub _check_sweep_parameters {
    my ( $self, %args ) = validated_hash(
        \@_,
        current => { isa => 'Num' },
        target  => { isa => 'Num' },
        rate    => { isa => 'Num' },
    );

    my $current = abs( delete $args{current} );
    my $target  = abs( delete $args{target} );
    my $rate    = abs( delete $args{rate} );

    my $max_field = ( $current > $target ) ? $current : $target;

    my $maximum_allowed_field = $self->max_field();

    my $i = 0;

    if ( $max_field > $maximum_allowed_field ) {
        croak
            "target field $max_field exceeds absolute maximum field $maximum_allowed_field";
    }


    my $max_rate = $self->max_rate();
    if ( $rate > $max_rate ) {
        croak "Rate $rate exceeds maximum allowed rate $max_rate";
    }
}

__PACKAGE__->meta()->make_immutable();

1;
