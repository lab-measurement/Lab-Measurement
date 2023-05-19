package Lab::Moose::Instrument::Agilent33120A;

#ABSTRACT: Agilent 33120A 15MHz arbitrary waveform generator

use v5.20;

=head1 DESCRIPTION

Alias for L<Lab::Moose::Instrument::HP33120A>.

=cut

use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Instrument::HP33120A';

__PACKAGE__->meta()->make_immutable();

1;
