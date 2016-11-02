package Lab::Moose::Connection;

use 5.010;
use warnings;
use strict;

use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument 'timeout_param';

use namespace::autoclean;

=head1 NAME

Lab::Moose::Connection - Role for connections.

=head1 DESCRIPTION

This role should be consumed by all connections in the Lab::Moose::Connection
namespace. It declares the required methods.

=head1 Required methods

This role requires C<Read>, C<Write> and C<Clear> methods.

=head1 METHODS

=head2 Query

 my $data = $connection->Query(command => '*IDN?');

Call C<Write> followed by C<Read>.

=cut

sub Query {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    $self->Write(%arg);

    delete $arg{command};
    return $self->Read(%arg);
}

requires qw/Read Write Clear/;

1;
