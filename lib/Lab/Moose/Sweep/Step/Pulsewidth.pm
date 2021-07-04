package Lab::Moose::Sweep::Step::Pulsewidth;
$Lab::Moose::Sweep::Step::Pulsewidth::VERSION = '3.750';
#ABSTRACT: Pulsewidth sweep.

use v5.20;


use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Pulsewidth=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

has channel => ( is => 'ro', isa => 'Num', default => 1 );

has constant_delay => ( is => 'ro', isa => 'Num', default => 0 );

sub _build_setter {
    return \&_pulsewidth_setter;
}

sub _pulsewidth_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_pulsewidth(
      channel => $self->channel,
      value => $value,
      constant_delay => $self->constant_delay
    );
}

__PACKAGE__->meta->make_immutable();
1;

__END__
