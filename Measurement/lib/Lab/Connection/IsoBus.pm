#!/usr/bin/perl -w

package Lab::Connection::IsoBus;
our $VERSION = '3.11';

use strict;
use Lab::Bus::VISA;
use Lab::Connection;
use Lab::Exception;


our @ISA = ("Lab::Connection");

our %fields = (
	bus_class => 'Lab::Bus::IsoBus',
	isobus_address => undef,
	wait_status=>0, # usec;
	wait_query=>10e-6, # sec;
	read_length=>1000, # bytes
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class, parameter checks
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	return $self;
}


1;

#
# That's all, all that was needed was the additional field "isobus_address".
#


=pod

=encoding utf-8

=head1 NAME

Lab::Connection::IsoBus - IsoBus connection class which uses L<Lab::Bus::IsoBus> as a backend.

=head1 SYNOPSIS

This is not called directly. To make an Isobus instrument use Lab::Connection::IsoBus, set
the connection_type parameter accordingly:

$instrument = new ILM210(
   connection_type => 'IsoBus',
   isobus_address => 3,
)

=head1 DESCRIPTION

C<Lab::Connection::IsoBus> provides a connection with L<Lab::Bus::IsoBus>, 
transparently handled via a pre-existing bus and connection object (e.g. serial or GPIB).

It inherits from L<Lab::Connection>.


=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::IsoBus(
   connection_type => 'IsoBus',
   isobus_address => 3,
 }


=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.


=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $IsoBus_Address=$instrument->Config(isobus_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $IsoBus_Address = $connection->Config()->{'isobus_address'};
 
=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Bus::IsoBus>

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
