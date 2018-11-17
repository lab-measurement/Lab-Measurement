package Lab::Moose::Instrument::SCPI::Sense::Null;

#ABSTRACT: Role for the HP/Agilent/Keysight SCPI SENSe:$function:NULL subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Moose::Util::TypeConstraints 'enum';
use Carp;
use namespace::autoclean;

=head1 METHODS

=head2 sense_null_state_query

=head2 sense_null_state

 $self->sense_null_state(value => 1);

Query/Set state of null function.

=cut

requires 'cached_sense_function';

sub sense_null_state_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();
    return $self->cached_sense_null_state(
        $self->query( command => "SENS:$func:NULL:STAT?", %args ) );
}

sub sense_null_state {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );

    my $func = $self->cached_sense_function();
    $self->write( command => "SENS:$func:NULL:STATE $value", %args );

    $self->cached_sense_null_state($value);
}

=head1 METHODS

=head2 sense_null_value_query

=head2 sense_null_value

 $self->sense_null_value(value => 0.12345);

Query/Set state of null function.

=cut

cache sense_null_value => ( getter => 'sense_null_value_query' );

sub sense_null_value_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();

    return $self->cached_sense_null_value(
        $self->query( command => "SENS:$func:NULL:VAL?", %args ) );
}

sub sense_null_value {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    my $func = $self->cached_sense_function();

    $self->write( command => "SENS:$func:NULL:VAL $value", %args );

    $self->cached_sense_null_value($value);
}

1;
