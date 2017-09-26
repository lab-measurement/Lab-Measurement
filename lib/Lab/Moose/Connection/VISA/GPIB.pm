package Lab::Moose::Connection::VISA::GPIB;

#ABSTRACT: GPIB back end to National Instruments' VISA library.

=head1 SYNOPSIS

 use Lab::Moose
 # FIXME 

=head1 DESCRIPTION


=cut

use 5.010;

use Moose;
use Moose::Util::TypeConstraints qw(enum);

use Carp;

use namespace::autoclean;

extends 'Lab::Moose::Connection::VISA';

has pad => (
    is        => 'ro',
    isa       => enum( [ ( 0 .. 30 ) ] ),
    predicate => 'has_pad',
    writer    => '_pad'
);

has gpib_address => (
    is        => 'ro',
    isa       => enum( [ ( 0 .. 30 ) ] ),
    predicate => 'has_gpib_address'
);

has sad => (
    is        => 'ro',
    isa       => enum( [ 0, ( 96 .. 126 ) ] ),
    predicate => 'has_sad',
);

has board_index => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has '+resource_name' => (
    required => 0,
    );

sub gen_resource_name {
    my $self = shift;
    if ( $self->has_gpib_address() ) {
        $self->_pad( $self->gpib_address() );
    }

    if ( not $self->has_pad() ) {
        croak "no primary GPIB address provided";
    }

    my $resource_name = "GPIB" . $self->board_index() . '::' . $self->pad();
    if ( $self->has_sad ) {
        $resource_name .= '::' . $self->sad();
    }
    $resource_name .= '::INSTR';
    return $resource_name;
}

__PACKAGE__->meta->make_immutable();

1;
