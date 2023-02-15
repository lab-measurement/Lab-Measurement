package Lab::Moose::Instrument::RS_ZVA;

#ABSTRACT: Rohde & Schwarz ZVA Vector Network Analyzer

use v5.20;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter validated_channel_getter validated_channel_setter /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::VNASweep

    Lab::Moose::Instrument::SCPI::Output::State
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

cache calculate_data_call_catalog => (
    getter => 'calculate_data_call_catalog',
    isa    => 'ArrayRef'
);

sub calculate_data_call_catalog {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $string
        = $self->query( command => "CALC${channel}:DATA:CALL:CAT?", %args );
    $string =~ s/'//g;

    return $self->cached_calculate_data_call_catalog(
        [ split ',', $string ] );
}

sub calculate_data_call {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        format => { isa => 'Str' }    # {isa => enum([qw/FDATA SDATA MDATA/])}
    );

    my $format = delete $args{format};

    return $self->binary_query(
        command => "CALC${channel}:DATA:CALL? $format",
        %args
    );

}

sub sparam_catalog {
    my $self = shift;

    my $catalog = $self->cached_calculate_data_call_catalog();
    my @complex_catalog;

    for my $sparam ( @{$catalog} ) {
        push @complex_catalog, "Re($sparam)", "Im($sparam)";
    }

    return \@complex_catalog;
}

sub sparam_sweep_data {
    my ( $self, %args ) = validated_getter( \@_ );

    my $byte_order = $self->cached_format_border();
    if ( $byte_order ne 'SWAP' ) {
        carp 'setting network byteorder to little endian.';
        $self->format_border( value => 'SWAP' );
    }

    # Start single sweep.
    $self->initiate_immediate();

    # Wait until single sweep is finished.
    $self->wai();

    return $self->calculate_data_call( format => 'SDATA', %args );
}

=head1 SYNOPSIS

 my $data = $zva->sparam_sweep(timeout => 10);

=cut


sub set_power {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    $self->source_power_level_immediate_amplitude( value => $value );	
}

sub get_power {
	my $self = shift;
	return $self->source_power_level_immediate_amplitude_query();	
}



=head1 METHODS

See L<Lab::Moose::Instrument::VNASweep> for the high-level C<sparam_sweep> and
C<sparam_catalog> methods.

=cut

__PACKAGE__->meta->make_immutable();

1;
