package Lab::Moose::Sweep::DataFile;

# ABSTRACT: Store parameters of datafile and its plots.
use Moose;
use MooseX::Params::Validate 'validated_hash';

has params => ( is => 'ro', isa => 'HashRef', required => 1 );

has plots => (
    is      => 'ro', isa => 'ArrayRef[HashRef]',
    default => sub   { [] },
);

sub add_plot {
    my ( $self, %args )
        = validated_hash( \@_, MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1 );
    push @{ $self->plots }, \%args;
}

__PACKAGE__->meta->make_immutable();
1;

