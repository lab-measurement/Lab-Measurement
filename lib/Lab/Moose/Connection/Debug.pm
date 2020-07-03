package Lab::Moose::Connection::Debug;

#ABSTRACT: Debug connection, printing / reading on terminal

use v5.20;

use Moose;
use namespace::autoclean;
use Data::Dumper;
use YAML::XS;

use Carp;

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

=head1 SYNOPSIS

 use Lab::Moose;

 my $instrument = instrument(
     type => 'DummySource',
     connection_type => 'DEBUG'
     connection_options => {
         verbose => 0, # do not print arguments of all Write commands (default is 1).
     }
 );


=head1 DESCRIPTION

Debug connection object. Print out C<Write> commands and prompt answer for
C<Read> commands.

=head1 METHODS

=head2 Write

If the connection option verbose is set, output the content of all write
commands to the terminal. Otherwise, do nothing.

=cut

sub Write {
    my $self = shift;
    my %args = @_;
    if ( $self->verbose() ) {
        carp "Write called with args:\n", Dump \%args, "\n";
    }
}

=head2 Read

Output the arguments of the read command to the terminal, and request
a response there, which is given as result of the read.

=cut

sub Read {
    my $self = shift;
    my %args = @_;
    carp "Read called with args:\n", Dump \%args, "\n";
    say "enter return value:";
    my $retval = <STDIN>;
    chomp $retval;
    return $retval;
}

=head2 Query

Output the arguments of the query command to the terminal, and request
a response there, which is given as result of the query.

=cut

sub Query {
    my $self = shift;
    my %args = @_;
    carp "Query called with args:\n", Dump \%args, "\n";
    say "enter return value:";
    my $retval = <STDIN>;
    chomp $retval;
    return $retval;
}

=head2 Clear

Output "Clear called" on the terminal.

=cut

sub Clear {
    my $self = shift;
    if ( $self->verbose ) {
        carp "Clear called";
    }
}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable();
1;

