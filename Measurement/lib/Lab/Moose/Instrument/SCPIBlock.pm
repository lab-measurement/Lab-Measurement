package Lab::Moose::Instrument::SCPIBlock;

use Moose::Role;
use MooseX::Params::Validate;

use Lab::Moose::Instrument 'precision_param';

use Carp;

use namespace::autoclean;

with qw/
    Lab::Moose::Instrument::SCPI::Sense::Sweep
    Lab::Moose::Instrument::SCPI::Format
    /;

our $VERSION = '3.520';

=head1 NAME

Lab::Moose::Instrument::SCPI::Block - Role for handling SCPI/IEEE 488.2
block data.

=head1 DESCRIPTION

So far, only definite length floating point data of type 'REAL' is
supported.

See "8.7.9 <DEFINITE LENGTH ARBITRARY BLOCK RESPONSE DATA>" in IEEE 488.2.

=head1 METHODS

=head2 block_to_array

 my $array_ref = $self->block_to_array(
     binary => "#232${bytes}";
     precision => 'double'
 );

Convert block data to arrayref, where the binary block holds floating point
values in native byte-order.

=cut

sub block_to_array {
    my ( $self, %args ) = validated_hash(
        \@_,
        binary => { isa => 'Str' },
        precision_param(),
        ,
    );

    my $precision = delete $args{precision};
    my $binary    = delete $args{binary};

    if ( substr( $binary, 0, 1 ) ne '#' ) {
        croak 'does not look like binary data';
    }

    my $num_digits = substr( $binary, 1, 1 );
    my $num_bytes  = substr( $binary, 2, $num_digits );
    my $expected_length = $num_bytes + $num_digits + 2;

    # $binary might have a trailing newline, so do not check for equality.
    if ( length $binary < $expected_length ) {
        croak
            "incomplete data: expected_length: $expected_length, received length: ",
            length $binary;
    }

    my @floats = unpack(
        $precision eq 'single' ? 'f*' : 'd*',
        substr( $binary, 2 + $num_digits, $num_bytes )
    );

    return \@floats;

}

=head2 set_data_format_precision

 $self->set_data_format_precision( precision => 'double' );

Set used floating point type. Has to be 'single' (default) or 'double'.

=cut

sub set_data_format_precision {
    my ( $self, %args ) = validated_hash(
        \@_,
        precision_param(),
    );

    my $precision = delete $args{precision};
    my $length    = $precision eq 'single' ? 32 : 64;
    my $format    = $self->cached_format_data();

    if ( $format->[0] ne 'REAL' || $format->[1] != $length ) {
        carp "setting data format: REAL, $length";
        $self->format_data( format => 'REAL', length => $length );
    }
}

=head2 estimate_read_lenth

 my $read_length = $self->estimate_read_lenth( num_cols => 2 );

Calculate length of block for a SENSE:SWEEP operation, which is used e.g. in
network/spectrum analyzers.

=cut

sub estimate_read_length {
    my ( $self, %args ) = validated_hash(
        \@_,
        num_cols => { isa => 'Int' },
    );

    my $num_cols = delete $args{num_cols};

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

1;
