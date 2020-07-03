package Lab::Moose::Instrument::SCPI::Sense::Range;

#ABSTRACT: Role for the SCPI SENSe:$function:RANGe subsystem.

use v5.20;

use Moose::Role;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;

=head1 METHODS

=head2 sense_range_query

=head2 sense_range

 $self->sense_range(value => '0.001');

Query/Set the input range.

=cut

requires 'cached_sense_function';

cache sense_range => ( getter => 'sense_range_query' );

sub sense_range_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();

    return $self->cached_sense_range(
        $self->query( command => "SENS:$func:RANG?", %args ) );
}

sub sense_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
    );

    my $func = $self->cached_sense_function();

    $self->write( command => "SENS:$func:RANG $value", %args );

    $self->cached_sense_range($value);
}

1;
