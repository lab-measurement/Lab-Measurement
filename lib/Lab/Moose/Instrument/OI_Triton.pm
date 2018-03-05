package Lab::Moose::Instrument::OI_Triton;

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

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

# default connection options:
around default_connection_options => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = $self->$orig();

    #  TODO: insert port
    #    $options->{Socket}{port}    = 7020;
    $options->{Socket}{timeout} = 10;
    return $options;
};

with 'Lab::Moose::Instrument::OI_Common';

=head1 SYNOPSIS

 use Lab::Moose;


=head1 METHODS

=cut

=head2 get_temperature

=cut

sub get_temperature {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Int', default => 1 }
    );
    $args{channel} = 'T' . $args{channel};

    return $self->get_temperature_channel(%args);
}

sub get_T {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->get_temperature( channel => 5, %args );
}

sub set_user {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/NORM GUEST/] ) },
    );
    my $cmd = "SET:SYS:USER";
    my $rv = $self->query( command => "$cmd:$value", %args );
    return $self->parse_setter_retval( $cmd, $rv );
}

sub enable_control {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_user( value => 'NORM', %args );
}

sub disable_control {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_user( value => 'GUEST', %args );
}

sub set_temp_pid {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) },
    );
    my $cmd = "SET:DEV:T5:TEMP:LOOP:MODE";
    my $rv = $self->query( command => "$cmd:$value", %args );
    return $self->parse_setter_retval( $cmd, $rv );
}

sub enable_temp_pid {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_temp_pid( value => 'ON', %args );
}

sub disable_temp_pid {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_temp_pid( value => 'OFF', %args );
}

sub set_max_current {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' },
    );
    if ( $value > 0.0101 ) {
        croak "current $value is too large";
    }
    $value *= 1000;    # in mA
    my $cmd = "SET:DEV:T5:TEMP:LOOP:RANGE";
    my $rv = $self->query( command => "$cmd:$value", %args );
    return $self->parse_setter_retval( $cmd, $rv );
}

sub t_set {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );
    my $cmd = "SET:DEV:T5:TEMP:LOOP:TSET";
    my $rv = $self->query( command => "$cmd:$value", %args );
    return $self->parse_setter_retval( $cmd, $rv );
}

sub set_T {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    if ( $value > 0.7 ) {
        croak "setting temperatures above 0.7K is forbidden\n";
    }

    # Adjust heater setting.
    if ( $value < 0.035 ) {
        $self->set_max_current( value => 0.000316 );
    }
    elsif ( $value < 0.07 ) {
        $self->set_max_current( value => 0.001 );
    }
    elsif ( $value < 0.35 ) {
        $self->set_max_current( value => 0.00316 );
    }
    else {
        $self->set_max_current( value => 0.01 );
    }

    # Why call t_set twice? (Taken from old Lab::Instrument code)
    $self->t_set( value => $value );
    $self->enable_temp_pid();
    return $self->t_set( value => $value );
}

sub get_P {
    my ( $self, %args ) = validated_getter( \@_ );
    my $cmd = "READ:DEV:H1:HTR:SIG:POWR";
    my $rv = $self->query( command => $cmd, %args );
    return $self->parse_getter_retval( $cmd, $rv );
}

sub set_P {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    my $cmd = "SET:DEV:H1:HTR:SIG:POWR";
    my $rv = $self->query( command => "$cmd:$value", %args );
    return $self->parse_setter_retval( $cmd, $rv );
}

__PACKAGE__->meta()->make_immutable();

1;
