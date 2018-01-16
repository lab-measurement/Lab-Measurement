package Lab::Moose::Sweep::Step::Magnet;

#ABSTRACT: Step/list sweep of magnetic field

=head1 SYNOPSIS

 my $sweep = sweep(
     type => 'Step::Magnet',
     instrument => $ips,
     from => -1, # Tesla
     to => 1,
     step => 0.1, # steps of 0.1 Tesla
     rate => 1, (Tesla/min, mandatory, always positive)
 );

=head1 Description

Step sweep with following properties:

=over

=item *

 Uses instruments C<sweep_to_field> method to set the field.

=item *

Default filename extension: C<'Field='>

=back

=cut

use 5.010;
use Moose;

extends 'Lab::Moose::Sweep::Step';

has rate => ( is => 'ro', isa => 'Num', required => 1 );

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Field=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

sub _build_setter {
    return \&_field_setter;
}

sub _field_setter {
    my $self  = shift;
    my $value = shift;
    my $rate  = $self->rate;
    $self->instrument->sweep_to_field( target => $value, rate => $rate );
}

__PACKAGE__->meta->make_immutable();
1;
