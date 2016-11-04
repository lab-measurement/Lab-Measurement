package Lab::Moose::Instrument::SCPI::Sense::Average;

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

our $VERSION = '3.530';

cache sense_average_state => ( getter => 'sense_average_state_query' );

sub sense_average_state_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_average_state(
        $self->query( command => "SENS${channel}:AVER?", %args ) );
}

sub sense_average_state {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write( command => "SENS${channel}:AVER $value", %args );
    return $self->cached_sense_average_state($value);
}

cache sense_average_count => (
    getter => 'sense_average_count_query',
    isa    => 'Int'
);

sub sense_average_count_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_average_count(
        $self->query( command => "SENS${channel}:AVER:COUN?", %args ) );
}

sub sense_average_count {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write( command => "SENS${channel}:AVER:COUN $value", %args );
    return $self->cached_sense_average_count($value);
}

1;
