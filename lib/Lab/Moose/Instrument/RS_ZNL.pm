package Lab::Moose::Instrument::RS_ZNL;

#ABSTRACT: Rohde & Schwarz ZNL Vector Network Analyzer

use v5.20;

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

__PACKAGE__->meta->make_immutable();

1;

