package Lab::Moose::Connection::VXI11;

#ABSTRACT: Connection backend to VXI-11 (Lan/TCP)

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints 'enum';
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;
use Lab::VXI11;
use namespace::autoclean;

has client => (
    is       => 'ro',
    isa      => 'Lab::VXI11',
    writer   => '_client',
    init_arg => undef,
);

has lid => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_lid',
    init_arg => undef
);

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has proto => (
    is      => 'ro',
    isa     => enum( [qw/tcp udp/] ),
    default => 'tcp'
);

has device => (
    is      => 'ro',
    isa     => 'Str',
    default => "inst0",
);

sub BUILD {
    my $self    = shift;
    my $host    = $self->host();
    my $proto   = $self->proto();
    my $timeout = $self->timeout();
    my $device  = $self->device();
    my $client
        = Lab::VXI11->new( $host, DEVICE_CORE, DEVICE_CORE_VERSION, $proto )
        or croak "cannot open VXI-11 connection with $host: $!";
    $self->_client($client);

    my ( $error, $lid, $abortPort, $maxRecvSize )
        = $client->create_link( 0, 0, 0, $device );
    if ($error) {
        croak "Cannot create VXI-11 link. error: $error";
    }
    $self->_lid($lid);
}

sub Write {

}

sub Read {

}

sub Query {

}

sub Clear {

}

with qw/
    Lab::Moose::Connection
    /;

__PACKAGE__->meta->make_immutable();

1;

=head1 SYNOPSIS

 use Lab::Moose;

 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'Socket',
     connection_options => {host => '132.199.11.2', port => 5025},
 );

=head1 DESCRIPTION

This connection uses L<IO::Socket::INET> to interface with the operating
system's TCP stack. This works on most operating systems without installing any
additional software.

=cut

