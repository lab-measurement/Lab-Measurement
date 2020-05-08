package Lab::Moose::Instrument::SCPIBlock;

#ABSTRACT: Role for handling SCPI/IEEE 488.2 block data

use Moose::Role;
use MooseX::Params::Validate;

use Lab::Moose::Instrument qw/
    precision_param
    /;

use Carp;

use namespace::autoclean;

with qw/
    Lab::Moose::Instrument::SCPI::Sense::Sweep
    Lab::Moose::Instrument::SCPI::Format
    /;

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

=head2 block_length

 my $read_length = $self->block_length(
     num_points => $num_points,
     precision => $precision
 );
 
Calulate block length for use in C<read_length> parameter.

=cut

sub block_length {
    my $self = shift;
    my ( $num_points, $precision ) = validated_list(
        \@_,
        num_points => { isa => 'Int' },
        precision_param(),
    );

    my $point_length
        = $precision eq 'single' ? 4
        : $precision eq 'double' ? 8
        :                          croak("unknown precision $precision");

    my $read_length = $num_points * $point_length;
    $read_length += length("#d") + length($read_length) + length("\n");
    return $read_length;
}

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

    my %endians = (
        native => '',
        big    => '>',
        little => '<'
        );
    my $endianflag = $endians{$self->endian};

    my $num_digits = substr( $binary, 1, 1 );
    my $num_bytes  = substr( $binary, 2, $num_digits );
    my $expected_length = $num_bytes + $num_digits + 2;

    # $binary might have a trailing newline, so do not check for equality.
    if ( length $binary < $expected_length ) {
        croak "incomplete data: expected_length: $expected_length,"
            . " received length: ", length $binary;
    }

    my @floats = unpack(
        $precision eq 'single' ? "f$endianflag*" : "d$endianflag*",
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

1;
