package Lab::Moose::Instrument::SCPI::Sense::Bandwidth;
#ABSTRACT: Role for the SCPI SENSe:BANDwidth subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use Carp;

use namespace::autoclean;

=head1 METHODS

=head2 sense_bandwidth_resolution_query

=head2 sense_bandwidth_resolution

Query/Set the bandwidth resolution (in Hz).

=cut

cache sense_bandwidth_resolution =>
    ( getter => 'sense_bandwidth_resolution_query' );

sub sense_bandwidth_resolution_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_bandwidth_resolution(
        $self->query( command => "SENS${channel}:BAND?", %args ) );
}

sub sense_bandwidth_resolution {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write(
        command => sprintf( "SENS%s:BAND %.17g", $channel, $value ),
        %args
    );
    $self->cached_sense_bandwidth_resolution($value);
}

=head2 sense_bandwidth_video_query

=head2 sense_bandwidth_video

Query/Set the video bandwidth (in Hz).

=cut

cache sense_bandwidth_video =>
    ( getter => 'sense_bandwidth_video_query' );

sub sense_bandwidth_video_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_bandwidth_video(
        $self->query( command => "SENS${channel}:BAND:VIDEO?", %args ) );
}

sub sense_bandwidth_video {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write(
        command => sprintf( "SENS%s:BAND:VIDEO %.17g", $channel, $value ),
        %args
    );
    $self->cached_sense_bandwidth_video($value);
}

=head2 sense_bandwidth_resolution_select_query

=head2 sense_bandwidth_resolution_select

Query/Set selectivity of IF filter. Can be NORM or HIGH.

Used by R&S VNAs.

=cut

cache sense_bandwidth_resolution_select =>
    ( getter => 'sense_bandwidth_resolution_select_query' );

sub sense_bandwidth_resolution_select_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_bandwidth_resolution(
        $self->query( command => "SENS${channel}:BAND:SEL?", %args ) );
}

sub sense_bandwidth_resolution_select {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/NORM HIGH/] ) }
    );

    $self->write(
        command => sprintf( "SENS%s:BAND:SEL %s", $channel, $value ), %args );
    $self->cached_sense_bandwidth_resolution_select($value);
}

1;
