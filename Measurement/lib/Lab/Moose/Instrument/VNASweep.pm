package Lab::Moose::Instrument::VNASweep;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param getter_params precision_param
    /;

use Lab::Moose::BlockData;
use Carp;

use namespace::autoclean;

our $VERSION = '3.520';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Instrument

    Lab::Moose::Instrument::SCPI::Sense::Average
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep

    Lab::Moose::Instrument::SCPI::Initiate

    Lab::Moose::Instrument::SCPIBlock
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

=head1 NAME

Lab::Moose::Instrument::VNASweep - Role for network analyzer sweeps.

=head1 METHODS

=head2 sparam_sweep

 my $data = $vna->sparam_sweep(timeout => 10, average => 10, precision => 'double');

Perform a single sweep, and return the resulting data table. The result is of
type L<Lab::Moose::BlockData>. For each sweep point, one row of data will be
created. Each row will start with the sweep value (e.g. frequency), followed by
the real and imaginary parts of the measured 
S-parameters.

This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<average>

Setting this to C<$N>, the method will perform C<$N> sweeps and the
returned data will consist of the average values.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=cut

=head1 REQUIRED METHODS

The following methods are required for role consumption.

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
        precision_param()
    );

    my $average_count = delete $args{average};
    my $precision     = delete $args{precision};

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

    # Ensure correct data format
    $self->set_data_format_precision( precision => $precision );

    # Query measured traces.

    # Get data.
    my $num_cols = @{$catalog};
    my $read_length = $self->estimate_read_length( num_cols => $num_cols );

    my $binary = $self->sparam_sweep_data(
        read_length => $read_length,
        %args
    );

    my $points_ref = $self->block_to_array(
        binary    => $binary,
        precision => $precision
    );

    return $self->_get_data_columns( $catalog, $freq_array, $points_ref );
}

=head1 CONSUMED ROLES

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Format>

=item L<Lab::Moose::Instrument::SCPI::Instrument>

=item L<Lab::Moose::Instrument::SCPI::Sense::Average>

=item L<Lab::Moose::Instrument::SCPI::Sense::Frequency>

=item L<Lab::Moose::Instrument::SCPI::Sense::Sweep>

=item L<Lab::Moose::Instrument::SCPI::Initiate>

=item L<Lab::Moose::Instrument::SCPIBlock>

=back

=cut

1;
