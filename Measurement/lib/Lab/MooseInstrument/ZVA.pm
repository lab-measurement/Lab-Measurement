package Lab::MooseInstrument::ZVA;
our $VERSION = '3.520';

use 5.010;
use Moose;
use MooseX::Params::Validate;
use Lab::MooseInstrument qw/getter_params/;
use Lab::BlockData;
use Carp;

use namespace::autoclean;

extends 'Lab::MooseInstrument';

with qw(
  Lab::MooseInstrument::Common

  Lab::MooseInstrument::SCPI::Calculate::Data

  Lab::MooseInstrument::SCPI::Sense::Frequency
  Lab::MooseInstrument::SCPI::Sense::Sweep

  Lab::MooseInstrument::SCPI::Initiate
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

sub _get_data_columns {
    my ( $self, $catalog, $freq_array, $data_string ) = @_;

    my $num_rows = @{$freq_array};

    my @points = split ',', $data_string;

    my $num_points = @points;

    # Have separate real and im part, so multiply with 2.
    my $num_columns = @{$catalog} * 2;

    if ( $num_points != $num_columns * $num_rows ) {
        croak "$num_points != $num_columns * $num_rows";
    }

    my @data_columns;

    my $block_data = Lab::BlockData->new();

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

sub sweep {
    my ( $self, %args ) = validated_hash( \@_, getter_params(), );

    my $catalog = $self->cached_calculate_data_call_catalog();

    my $freq_array = $self->sense_frequency_linear_array();

    # Ensure single sweep mode.
    if ( $self->cached_initiate_continuous() ) {
        $self->initiate_continuous( value => 0 );
    }

    # Start single sweep.
    $self->initiate_immediate();

    # Wait until single sweep is finished.
    $self->opc_sync(%args);

    # Query measured traces.
    my $data_string = $self->calculate_data_call();

    return $self->_get_data_columns( $catalog, $freq_array, $data_string );
}

1;
