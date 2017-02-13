package Lab::Moose::Instrument::RS_SMB;

use 5.010;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Carp;
use Lab::Moose::Instrument::Cache;
use namespace::autoclean;

our $VERSION = '3.540';

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Source::Power

);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

=head1 NAME

Lab::Moose::Instrument::RS_SMB - Rohde & Schwarz SMB Signal Generator

=head1 SYNOPSIS

 # Set frequency to 2 GHz
 $smb->sense_power_frequency(value => 2e9);
 
 # Query output power (in Dbm)
 my $power = $smb->source_power_level_immediate_amplitude_query();
 
=cut

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::SCPI::Source::Power>

=back

=head2 sense_power_frequency_query

=head2 sense_power_frequency

Query and set the RF output frequency.

=cut

cache sense_power_frequency => ( getter => 'sense_power_frequency_query' );

sub sense_power_frequency_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_sense_power_frequency(
        $self->query( command => "SENS:FREQ?" ) );
}

sub sense_power_frequency {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    $self->write( command => sprintf( "SENS:FREQ %.17g", $value ) );

    $self->cached_sense_power_frequency($value);
}

1;
