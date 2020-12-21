package Lab::Moose::Instrument::RS_ZNL;

#ABSTRACT: Rohde & Schwarz ZNL Vector Network Analyzer

use v5.20;
use Carp 'croak';
use Moose;

extends 'Lab::Moose::Instrument::RS_ZVA';

# does not support USBTMC

=head1 SYNOPSIS

 my $data = $znl->sparam_sweep(timeout => 10);

=cut

=head1 METHODS

See L<Lab::Moose::Instrument::VNASweep> for the high-level C<sparam_sweep> and
C<sparam_catalog> methods.

=cut

# The ZNL only supports SWAP byte order. It does not have a FORMAT:BORDER command.
sub format_border_query() {
    return 'SWAP';
}

sub format_border {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    if ( $value ne 'SWAP' ) {
        croak 'The R&S ZNL only suppots SWAP byte order.';
    }
    return $self->cached_format_border($value);
}

__PACKAGE__->meta->make_immutable();

1;

