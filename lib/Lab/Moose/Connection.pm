package Lab::Moose::Connection;

#ABSTRACT: Role for connections

use v5.20;

use warnings;
use strict;

use Moose::Role;
use MooseX::Params::Validate qw/validated_hash/;
use Lab::Moose::Instrument qw/timeout_param read_length_param/;
use namespace::autoclean;

requires qw/Read Write Clear/;

=head1 DESCRIPTION

This role should be consumed by all connections in the Lab::Moose::Connection
namespace. It declares the required methods.

=cut

has timeout => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);

sub _timeout_arg {
    my $self = shift;
    my %arg  = @_;
    return $arg{timeout} // $self->timeout();
}

has read_length => (
    is      => 'ro',
    isa     => 'Int',
    default => 32768
);

sub _read_length_arg {
    my $self = shift;
    my %arg  = @_;
    return $arg{read_length} // $self->read_length();
}

=head2 Query

 my $data = $connection->Query(command => '*IDN?');

Call C<Write> followed by C<Read>.

=cut

sub Query {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        read_length_param,
        command => { isa => 'Str' },
    );

    my %write_arg = %arg;
    delete $write_arg{read_length};
    $self->Write(%write_arg);

    delete $arg{command};
    return $self->Read(%arg);
}

1;
