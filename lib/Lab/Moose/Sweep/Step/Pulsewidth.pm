package Lab::Moose::Sweep::Step::Pulsewidth;

#ABSTRACT: Pulsewidth sweep.

use v5.20;

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_pulsewidth> method to change the pulsewidth. On initialization
an optional boolean parameter C<constant_delay> can be passed to keep a constant
delay time over a pulse period.

=item *

Default filename extension: C<'Pulsewidth='>

=back

See pulsewidth-sweep.pl in the examples::Sweeps folder for a simple pulsewidth
sweep example. 

=cut

use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Pulsewidth=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

has constant_delay => ( is => 'ro', isa => 'Bool', default => 0 );

sub _build_setter {
    return \&_pulsewidth_setter;
}

sub _pulsewidth_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_pulsewidth(
      value => $value,
      constant_delay => $self->constant_delay
    );
}

__PACKAGE__->meta->make_immutable();
1;

__END__
