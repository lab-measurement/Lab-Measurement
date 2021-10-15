package Lab::Moose::Sweep::Step::Phase;

#ABSTRACT: Phase sweep.

use v5.20;

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_phase> method to change the phase.

=item *

Default filename extension: C<'Phase='>

=back

=cut

use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Phase=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'ArrayRefOfInstruments', coerce => 1, required => 1 );

sub _build_setter {
    return \&_phase_setter;
}

sub _phase_setter {
    my $self  = shift;
    my $value = shift;
    foreach (@{$self->instrument}) {
        $_->set_phase( value => $value );
    }
}

__PACKAGE__->meta->make_immutable();
1;
