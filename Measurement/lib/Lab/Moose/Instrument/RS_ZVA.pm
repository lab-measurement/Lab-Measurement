package Lab::Moose::Instrument::RS_ZVA;

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/getter_params timeout_param/;
use Lab::Moose::BlockData;
use Carp;
use Config;
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
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

sub _get_data_columns {
    my ( $self, $catalog, $freq_array, $points ) = @_;

    my $num_rows = @{$freq_array};
    if ( $num_rows != $self->cached_sense_sweep_points() ) {
        croak
            "length of frequency array not equal to number of configured points";
    }

    my @points = @{$points};

    my $num_columns = @{$catalog};

    my $num_points = @points;

    if ( $num_points != $num_columns * $num_rows ) {
        croak "$num_points != $num_columns * $num_rows";
    }

    my @data_columns;

    my $block_data = Lab::Moose::BlockData->new();

    $block_data->add_column($freq_array);

    while (@points) {
        my @param_data = splice @points, 0, 2 * $num_rows;
        my ( @real, @im );
        while (@param_data) {
            push @real, shift @param_data;
            push @im,   shift @param_data;
        }

        $block_data->add_column( \@real );
        $block_data->add_column( \@im );
    }
    return $block_data;
}

sub complex_catalog {
    my $self = shift;

    my $catalog = $self->cached_calculate_data_call_catalog();
    my @complex_catalog;

    for my $sparam ( @{$catalog} ) {
        push @complex_catalog, "Re($sparam)", "Im($sparam)";
    }

    return \@complex_catalog;
}

sub _estimate_read_length {
    my $self = shift;

    my $catalog = $self->complex_catalog();

    my $num_cols = @{$catalog};

    my $num_rows = $self->cached_sense_sweep_points();
    my $format   = $self->cached_format_data();

    my $length_per_num;

    if ( $format->[0] eq 'ASC' ) {
        $length_per_num = 30;
    }
    elsif ( $format->[0] eq 'REAL' ) {
        $length_per_num = $format->[1] / 8;
    }
    else {
        croak "unknown format: @{$format}";
    }

    return $length_per_num * $num_rows * $num_cols + 100;
}

my %precision_param = ( precision =>
        { isa => enum( [qw/single double/] ), default => 'single' } );

sub query_data_points {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        %precision_param,
        ,

        # FIXME: ascii flag for debugging?
    );

    my $precision = $args{precision};

    # Ensure that we get data in native endianess.

    my $byteorder = $Config{byteorder};

    # $byteorder is 1234 or 12345678 on little-endian.

    if ( $byteorder !~ /1234/ ) {
        croak 'big endian is not yet supported. File a bug if you need this.';
    }

    my $network_byteorder = $self->cached_format_border();
    if ( $network_byteorder ne 'SWAP' ) {
        carp 'setting network byteorder to little endian.';
        $self->format_border( value => 'SWAP' );
    }

    # Ensure correct data format

    my $length = $precision eq 'single' ? 32 : 64;
    my $format = $self->cached_format_data();

    if ( $format->[0] ne 'REAL' || $format->[1] != $length ) {
        carp "setting data format: REAL, $length";
        $self->format_data( format => 'REAL', length => $length );
    }

    # Get data.
    my $read_length = $self->_estimate_read_length();
    my $binary      = $self->calculate_data_call(
        timeout     => $args{timeout},
        read_length => $read_length,
        format      => 'SDATA'
    );

    if ( substr( $binary, 0, 1 ) ne '#' ) {
        croak 'does not look like binary data';
    }

    my $num_digits = substr( $binary, 1, 1 );
    my $num_bytes  = substr( $binary, 2, $num_digits );
    if ( length $binary != $num_bytes + $num_digits + 2 ) {
        croak "incomplete data";
    }

    my @floats = unpack(
        $precision eq 'single' ? 'f*' : 'd*',
        substr( $binary, 2 + $num_digits )
    );

    return \@floats;

}

sub sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        %precision_param
    );

    my $catalog = $self->complex_catalog();

    my $freq_array = $self->sense_frequency_linear_array();

    # Ensure single sweep mode.
    if ( $self->cached_initiate_continuous() ) {
        $self->initiate_continuous( value => 0 );
    }

    # Start single sweep.
    $self->initiate_immediate();

    # Wait until single sweep is finished.
    $self->wai();

    # Query measured traces.

    my $points_ref = $self->query_data_points(%args);

    return $self->_get_data_columns( $catalog, $freq_array, $points_ref );
}

1;
