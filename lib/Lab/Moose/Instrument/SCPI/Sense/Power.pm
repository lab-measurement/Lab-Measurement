package Lab::Moose::Instrument::SCPI::Sense::Power;
#ABSTRACT: Role for the SCPI SENSe:POWer subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

=head1 METHODS

=head2 sense_power_rf_attenuation_query

=head2 sense_power_rf_attenuation

Query/Set the input attenuation.

=cut

cache sense_power_rf_attenuation => ( getter => 'sense_power_rf_attenuation_query' );

sub sense_power_rf_attenuation_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_sense_power_rf_attenuation(
        $self->query( command => "SENS:POW:RF:ATT?", %args ) );
}

sub sense_power_rf_attenuation {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    $self->write( command => "SENS:POW:RF:ATT $value", %args );
    $self->cached_sense_power_rf_attenuation($value);
}

1;
