package Lab::Moose::Connection::VISA::VXI11;

#ABSTRACT: VXI-11 frontend to National Instruments' VISA library.

=head1 SYNOPSIS

 use Lab::Moose
 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'VISA::VXI11',
     connection_options => {host => '132.188.12.12'}
 );

=head1 DESCRIPTION

Creates a VXI-11 resource name for the VISA backend.

=cut

use 5.010;

use Moose;
use Moose::Util::TypeConstraints qw(enum);

use Carp;

use namespace::autoclean;

extends 'Lab::Moose::Connection::VISA';

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+resource_name' => (
    required => 0,
);

sub gen_resource_name {
    my $self = shift;

    my $host = $self->host();

    return "TCPIP::${host}::INSTR";
}

__PACKAGE__->meta->make_immutable();

1;
