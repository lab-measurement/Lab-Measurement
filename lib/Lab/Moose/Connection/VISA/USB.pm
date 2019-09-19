package Lab::Moose::Connection::VISA::USB;

#ABSTRACT: USB-TMC frontend to National Instruments' VISA library.

=head1 SYNOPSIS

 use Lab::Moose
 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'VISA::USB',
     connection_options => {vid => 0xabcd, pid => 0x1234, serial => 'MY47000419'}
 );

=head1 DESCRIPTION

Creates a USB resource name for the VISA backend.

=cut

use 5.010;

use Moose;
use Moose::Util::TypeConstraints qw(enum);

use Carp;

use namespace::autoclean;

extends 'Lab::Moose::Connection::VISA';

has vid => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has pid => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has serial => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+resource_name' => (
    required => 0,
);

sub gen_resource_name {
    my $self = shift;

    my $vid    = $self->vid;
    my $pid    = $self->pid;
    my $serial = $self->serial;
    if ( $vid =~ /^0x/i ) {
        $vid = hex($vid);
    }
    if ( $pid =~ /^0x/i ) {
        $pid = hex($pid);
    }

    return sprintf( "USB::0x%04x::0x%04x::%s::INSTR", $vid, $pid, $serial );
}

__PACKAGE__->meta->make_immutable();

1;
