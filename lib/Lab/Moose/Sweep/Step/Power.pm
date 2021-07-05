package Lab::Moose::Sweep::Step::Power;

#ABSTRACT: Power sweep.

use v5.20;

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_power> method to change the power.

=item *

Default filename extension: C<'Power='>

=back

=cut

use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Power=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

sub _build_setter {
    return \&_power_setter;
}

sub _power_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_power( value => $value );
}

__PACKAGE__->meta->make_immutable();
1;
