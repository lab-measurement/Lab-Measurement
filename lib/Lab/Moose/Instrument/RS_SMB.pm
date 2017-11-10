package Lab::Moose::Instrument::RS_SMB;

#ABSTRACT: Rohde & Schwarz SMB Signal Generator

use 5.010;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Carp;
use Lab::Moose::Instrument::Cache;
use namespace::autoclean;

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

=head1 SYNOPSIS

 # Set frequency to 2 GHz
 $smb->source_frequency(value => 2e9);
 
 # Query output power (in Dbm)
 my $power = $smb->source_power_level_immediate_amplitude_query();
 
=cut

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::SCPI::Source::Power>

=back

=head2 source_frequency_query

=head2 source_frequency

=head2 cached_source_frequency

Query and set the RF output frequency.
    
=cut

cache source_frequency => ( getter => 'source_frequency_query' );

sub source_frequency_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_source_frequency(
        $self->query( command => "FREQ?" ) );
}

sub source_frequency {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
	);

    my $min_freq = 9e3;
    if ($value < $min_freq) {
	croak "value smaller than minimal frequency $min_freq";
    }

    $self->write( command => sprintf( "FREQ %.17g", $value ) );
    $self->cached_source_frequency($value);
}

#
# Aliases for Lab::XPRESS::Sweep API
#

sub set_frq {
    my $self  = shift;
    return $self->source_frequency( @_ );
}

sub get_frq {
    my $self = shift;
    return $self->source_frequency_query();
}

1;
