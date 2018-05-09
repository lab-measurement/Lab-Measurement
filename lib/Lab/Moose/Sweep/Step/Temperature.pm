package Lab::Moose::Sweep::Step::Temperature;
#ABSTRACT: Step/list sweep of temperature

use 5.010;
use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Temp=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

sub BUILD {
    my $self = shift;
}

sub _build_setter {
    return \&_temp_setter;
}

sub _temp_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->sweep_to_temperature( value => $value );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=head1 SYNOPSIS

 my $sweep = sweep(
     type => 'Step::Temperature',
     instrument => $triton,
     from => 0.5, # Kelvin
     to => 0.015,
     step => 0.005, # steps of 0.1 Tesla
 );

=head1 Description

Minimalistic (so far) step sweep with following properties:

=over

=item *

Uses instruments C<sweep_to_temperature> method to set the field.

=item *

Default filename extension: C<'Temp='>

=back

=cut
