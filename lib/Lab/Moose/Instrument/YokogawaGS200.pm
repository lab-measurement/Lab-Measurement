package Lab::Moose::Instrument::YokogawaGS200;

#ABSTRACT: YokogawaGS200 voltage/current source.

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Carp;
use Lab::Moose::Instrument::Cache;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Source::Function
    Lab::Moose::Instrument::SCPI::Source::Level
    Lab::Moose::Instrument::SCPI::Source::Range
);

has [
    qw/
        max_units_per_second
        max_units_per_step
        min_units
        max_units
        /
] => ( is => 'ro', isa => 'Num', required => 1 );

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

=head1 SYNOPSIS


=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head2 source_frequency_query

=head2 source_frequency

=head2 cached_source_frequency

Query and set the RF output frequency.
    
=cut

around source_level => sub {

};

#
# Aliases for Lab::XPRESS::Sweep API
#

sub get_level {
    my $self = shift;
    return $self->source_level_query(@_);
}

sub set_voltage {
    my $self  = shift;
    my $value = shift;
    return $self->source_level( value => $value );
}

sub sweep_to_level {
    my $self = shift;
    return $self->set_voltage(@_);
}

1;
