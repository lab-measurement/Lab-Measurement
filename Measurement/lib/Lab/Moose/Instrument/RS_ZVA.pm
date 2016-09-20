package Lab::Moose::Instrument::RS_ZVA;

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter/;
use Lab::Moose::BlockData;
use Carp;
use namespace::autoclean;

our $VERSION = '3.520';

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Calculate::Data

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep

    Lab::Moose::Instrument::SCPI::Initiate

    Lab::Moose::Instrument::VNASweep
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
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

    return $self->calculate_data_call( format => 'SDATA', %args );
}

1;
