package Lab::Moose::Instrument::SCPI::Unit;

#ABSTRACT: Role for SCPI UNIT subsystem.

use Moose::Role;
use Lab::Moose::Instrument qw/setter_params getter_params validated_getter/;
use Lab::Moose::Instrument::Cache;
use MooseX::Params::Validate;
use Carp;

=head1 METHODS

=head2 unit_power_query

=head2 unit_power

Set/Get amplitude units for the input, output and display.
  Allowed values are DBM|DBMV|DBUV|DBUA|V|W|A.

=cut

cache unit_power => ( getter => 'unit_power_query' );

sub unit_power_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_format_data_query(
        $self->query( command => "UNIT:POWer?", %args ) );
}

sub unit_power {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/DBM DBMV DBUV DBUA V W A/] ) }
    );
    $self->write(
        command => sprintf( "UNIT:POWer %.17g", $value ),
        %args
    );
    $self->cached_format_data_query($value);
}


1;
