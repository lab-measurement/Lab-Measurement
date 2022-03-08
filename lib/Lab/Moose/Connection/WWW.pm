package Lab::Moose::Connection::WWW;

#ABSTRACT: Connection with URL requests

use v5.20;

=head1 SYNOPSIS

 use Lab::Moose
 
 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'WWW',
     connection_options => {ip => 172.22.11.2, port => 8002},
 );

=head1 DESCRIPTION

This module provides a connection for devices with an integrated web
server.

=cut

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(enum);
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;

use LWP::Simple;

use namespace::autoclean;


has ip => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has port => (
    is       => 'ro',
    isa      => 'Lab::Moose::PosNum',
    required => 1,
);

sub Read {
    my ( $self, %args ) = validated_hash(
        \@_,
        command => { isa => 'Str' },
    );
    my $command = $args{'command'};
    my $url = "http://$self->ip():$self->port()$command";
    return get( $url );
}

sub Write {
    my ( $self, %args ) = validated_hash(
        \@_,
        command => { isa => 'Str' },
    );
    my $command = $args{'command'};
    my $url = "http://$self->ip():$self->port()$command";
    get( $url );
}

1;
