#!/usr/bin/perl -w

#
# general VISA Connection class for Lab::Bus::VISA
# This one digests VISA resource names
#
package Lab::Connection::VISA;
use strict;
use Lab::Bus::VISA;
use Lab::Connection;
use Lab::Exception;


our @ISA = ("Lab::Connection");

our %fields = (
	bus_class => 'Lab::Bus::VISA',
	resource_name => undef,
	wait_status=>0, # usec;
	wait_query=>10, # usec;
	read_length=>1000, # bytes
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class, parameter checks
	$self->_construct(__PACKAGE__, \%fields);

	return $self;
}

#
# That's all, all that was needed was the additional field "resource_name".
#



=head1 NAME

Lab::Connection::VISA - VISA-type connection class which uses L<Lab::Bus::VISA> and thus NI VISA (L<Lab::VISA>) as a backend.

=head1 SYNOPSIS

This is not called directly. To make a VISA suppporting instrument use Lab::Connection::VISA, set
the connection_type parameter accordingly:

$instrument = new HP34401A(
   connection_type => 'VISA',
   resource_name => 'GPIB0::14::INSTR',
)

=head1 DESCRIPTION

C<Lab::Connection::VISA> provides a VISA-type connection with L<Lab::Bus::VISA> using NI VISA (L<Lab::VISA>) as backend.

It inherits from L<Lab::Connection>.


=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::VISA(
   connection_type => 'VISA',
   resource_name => 'GPIB0::14::INSTR',
 }


=head1 METHODS

This just calls back on the methods inherited from L<Lab::Connection>.


=head2 config

Provides unified access to the fields in initial @_ to all the cild classes.
E.g.

 $GPIB_PAddress=$instrument->Config(GPIB_PAddress);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_PAddress = $connection->Config()->{'GPIB_PAddress'};
 
=head1 CAVEATS/BUGS

Probably view. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item L<Lab::Connection>

=item L<Lab::Connection::GPIB>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;