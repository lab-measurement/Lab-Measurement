package Lab::Moose::Sweep::Step::Frequency;

#ABSTRACT: Frequency sweep.

use v5.20;

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_frq> method to change the frequency.

=item *

Default filename extension: C<'Frequency='>

=back

=cut

use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Frequency=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'ArrayRefOfInstruments', coerce => 1, required => 1 );

sub _build_setter {
    return \&_frq_setter;
}

sub _frq_setter {
    my $self  = shift;
    my $value = shift;
    foreach (@{$self->instrument}) {
        $_->set_frq( value => $value );
    }
}

__PACKAGE__->meta->make_immutable();
1;
