package Lab::Moose::Connection;

use 5.010;
use warnings;
use strict;

our $VERSION = '3.530';

use Moose::Role;

use namespace::autoclean;

requires qw/Read Write Query Clear/;

=head1 NAME

Lab::Moose::Connection - Role for connections.

=head1 DESCRIPTION

This role should be consumed by all connections in the Lab::Moose::Connection
namespace. It declares the required methods.

=cut

1;
