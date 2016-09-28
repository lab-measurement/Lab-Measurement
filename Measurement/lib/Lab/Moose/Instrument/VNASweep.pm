package Lab::Moose::Instrument::VNASweep;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param getter_params
    /;

use Lab::Moose::BlockData;
use Carp;

use namespace::autoclean;

our $VERSION = '3.520';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Sense::Average
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep

    Lab::Moose::Instrument::SCPI::Initiate
);

requires qw/sparam_sweep_data sparam_catalog/;

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

sub _estimate_read_length {
    my $self = shift;

    my $catalog = $self->sparam_catalog();

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

sub _query_data_points {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        %precision_param,
        ,

        # FIXME: ascii flag for debugging?
    );

    my $precision = delete $args{precision};

    # Ensure correct data format

    my $length = $precision eq 'single' ? 32 : 64;
    my $format = $self->cached_format_data();

    if ( $format->[0] ne 'REAL' || $format->[1] != $length ) {
        carp "setting data format: REAL, $length";
        $self->format_data( format => 'REAL', length => $length );
    }

    # Get data.
    my $read_length = $self->_estimate_read_length();

    my $binary = $self->sparam_sweep_data(
        read_length => $read_length,
        %args
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

=head1 NAME

Lab::Moose::Instrument::VNASweep - Role for network analyzer sweeps.

=head1 METHODS

=head2 sparam_sweep

 my $data = $vna->sparam_sweep(timeout => 10, precision => 'double');

Perform a single sweep, and return the resulting data table. The result is of
type L<Lab::Moose::BlockData>. For each sweep point, one row of data will be
created. Each row will start with the sweep value (e.g. frequency), followed by the real and imaginary parts of the measured
S-parameters.

=head1 REQUIRED METHODS

These methods are required for role consumption.

=head2 sparam_catalog

 my $array_ref = $vna->sparam_catalog();

Return an arrayref of available S-parameter names. Example result:
C<['Re(s11)', 'Im(s11)', 'Re(s21)', 'Im(s21)']>.

=head2 sparam_sweep_data

 my $binary_string = $vna->sparam_sweep_data(timeout => $timeout, read_length => $read_length)

Return binary SCPI data block of S-parameter values. This string contains
the C<sparam_catalog> values of each frequency point. The floats must be in
native byte order. 

=cut

sub sparam_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        type => { isa => enum( ['frequency'] ), default => 'frequency' },
        average => { isa => 'Int', default => 1 },
        %precision_param
    );

    my $average_count = delete $args{average};

    # Not used so far.
    my $sweep_type = delete $args{type};


    my $catalog = $self->sparam_catalog();

    my $freq_array = $self->sense_frequency_linear_array();

    # Ensure single sweep mode.
    if ( $self->cached_initiate_continuous() ) {
        $self->initiate_continuous( value => 0 );
    }

    # Set average and sweep count.

    if ( $self->cached_sense_average_count() != $average_count ) {
        $self->sense_average_count( value => $average_count );
    }

    if ( $self->cached_sense_sweep_count() != $average_count ) {
        $self->sense_sweep_count( value => $average_count );
    }

    # Query measured traces.

    my $points_ref = $self->_query_data_points(%args);

    return $self->_get_data_columns( $catalog, $freq_array, $points_ref );
}

1;
