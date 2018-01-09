package Lab::Moose::Sweep::Step::Frequency;

#ABSTRACT: Frequency sweep.

=head1 Description

Step sweep with following properties:

=over

=item *

 Uses instruments C<set_frq> method to change the frequency.
 The default filename extension is 

=item *

Default filename extension: C<'Frequency='>

=back

=cut

use 5.010;
use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Frequency=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

sub _build_setter {
    return \&_frq_setter;
}

sub _frq_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_frq( value => $value );
}

__PACKAGE__->meta->make_immutable();
1;
