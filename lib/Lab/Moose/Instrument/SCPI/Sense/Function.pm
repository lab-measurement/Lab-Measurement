package Lab::Moose::Instrument::SCPI::Sense::Function;

#ABSTRACT: Role for the SCPI SENSe:FUNCtion subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

=head1 METHODS

=head2 sense_function_query

=head2 sense_function

Query/Enable the sense function used by the instrument. Assumes that only a
single functions is in use. Concurrent sense would need slightly more difficult
implementation

=cut

# Cache used by multiple functions in sense subsystem
cache sense_function => ( getter => 'sense_function_query' );

sub sense_function_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $value = $self->query( command => "SENS${channel}:FUNC?", %args );
    $value =~ s/["']//g;
    return $self->cached_sense_function($value);
}

sub sense_function {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "SENS${channel}:FUNC '$value'", %args );
    return $self->cached_sense_function($value);
}

=head2 sense_function_concurrent_query/sense_function_concurrent

Concurrent sense is not yet really supported.
Set/Get concurrent property of sensor block. Allowed values: C<0> or C<1>.

=cut

cache sense_function_concurrent => ( getter => 'sense_function_concurrent' );

sub sense_function_concurrent_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $value = $self->query( command => "SENS${channel}:FUNC:CONC?", %args );
    return $self->cached_sense_function_concurrent($value);
}

sub sense_function_concurrent {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Bool' }
    );

    $self->write( command => "SENS${channel}:FUNC:CONC $value", %args );
    return $self->cached_sense_function_concurrent($value);
}

1;
