package Lab::Moose::Instrument::SCPI::Sense::Impedance;

#ABSTRACT: Role for the HP/Agilent/Keysight SCPI SENSe:$function:IMPedance subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Moose::Util::TypeConstraints 'enum';
use Carp;
use namespace::autoclean;

=head1 METHODS

=head2 sense_impedance_auto_query

=head2 sense_impedance_auto

 $self->sense_impedance_auto(value => 1);

Query/Set input impedance mode. Allowed values: '0' or '1'.

=cut

with 'Lab::Moose::Instrument::SCPI::Sense::Function';

cache sense_impedance_auto => ( getter => 'sense_impedance_auto_query' );

sub sense_impedance_auto_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();
    if ( $func ne 'VOLT' ) {
        croak "query impedance with function $func";
    }
    return $self->cached_sense_impedance_auto(
        $self->query( command => "SENS:$func:IMP:AUTO?", %args ) );
}

sub sense_impedance_auto {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );

    my $func = $self->cached_sense_function();
    if ( $func ne 'VOLT' ) {
        croak "query impedance with function $func";
    }
    $self->write( command => "SENS:$func:IMP:AUTO $value", %args );

    $self->cached_sense_impedance_auto($value);
}

1;
