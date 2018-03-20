package Lab::Moose::Sweep::Continuous::Voltage;

#ABSTRACT: Continuous sweep of voltage

=head1 SYNOPSIS

 use Lab::Moose;

 # FIXME

=cut

use 5.010;
use Moose;
use Carp;
use Time::HiRes 'time';

extends 'Lab::Moose::Sweep::Continuous';

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Voltage=' );

__PACKAGE__->meta->make_immutable();
1;
