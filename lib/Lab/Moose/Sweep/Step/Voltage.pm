package Lab::Moose::Sweep::Step::Voltage;

#ABSTRACT: Voltage sweep.

use v5.20;

=head1 DESCRIPTION

Step sweep with following properties:

=over

=item *

Uses instruments C<set_level> method to change the output voltage.

=item *

Default filename extension: C<'Voltage='>

=back

=cut

use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Voltage=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'ArrayRefOfInstruments', coerce => 1, required => 1 );

sub _build_setter {
    return \&_voltage_setter;
}

sub _voltage_setter {
    my $self  = shift;
    my $value = shift;
    foreach (@{$self->instrument}) {
        $_->set_level( value => $value );
    }
}

__PACKAGE__->meta->make_immutable();
1;
