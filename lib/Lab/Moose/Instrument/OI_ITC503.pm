package Lab::Moose::Instrument::OI_ITC503;

#ABSTRACT: Oxford Instruments ITC503 Intelligent Temperature Control

use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

has empty_buffer_count =>
    ( is => 'ro', isa => 'Lab::Moose::PosInt', default => 1 );
has auto_pid => ( is => 'ro', isa => 'Bool', default => 1 );
has t_sensor => ( is => 'rw', isa => enum( [qw/1 2 3/] ), default => 3 );

# most function names should be backwards compatible with the
# Lab::Instrument::OI_ITC503 driver

sub BUILD {
    my $self = shift;

    warn "The ITC driver is work in progress. You have been warned";

    if ( $self->auto_pid ) {
        $self->itc_set_PID_auto(1);
    }

    # Unlike modern GPIB equipment, this device does not assert the EOI
    # at end of message. The controller shell stop reading when receiving the
    # eos byte.

    $self->connection->set_termchar( termchar => "\r" );
    $self->connection->enable_read_termchar();

    # Dont clear the instrument since that may make it unresponsive.
    # Instead, set the communication protocol to "Normal", which should
    # also clear all communication buffers.
    $self->write("Q0\r");    # why not use set_control ???
    $self->set_control( value => 3 );
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $itc = instrument(
     type => 'OI_ITC503',
     connection_type => 'LinuxGPIB',
     connection_options => {pad => 10},
 );
 

=head1 METHODS

=cut

# query wrapper with error checking
around query => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $result = $self->$orig(@_);

    chomp $result;
    my $cmd = $args{command};
    my $cmd_char = substr( $cmd, 0, 1 );

    # ITC query answers always start with the command character
    # if successful with a question mark and the command char on failure
    my $status = substr( $result, 0, 1 );
    if ( $status eq '?' ) {
        croak "ITC503 returned error '$result' on command '$cmd'";
    }
    elsif ( defined $cmd_char and ( $status ne $cmd_char ) ) {
        croak
            "ITC503 returned unexpected answer. Expected '$cmd_char' prefix, 
received '$status' on command '$cmd'";
    }
    return substr( $result, 1 );
};

sub set_control {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 1 2 3/] ) },
    );
    my $result = $self->query( command => "C$value\r", %args );
    sleep(1);
    return $result;
}

sub itc_set_PID_auto {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 1/] ) }
    );
    return $self->query( command => "L$value\r", %args );
}

=head2 Consumed Roles

This driver consumes the following roles:

=over


=back

=cut

__PACKAGE__->meta()->make_immutable();

1;
