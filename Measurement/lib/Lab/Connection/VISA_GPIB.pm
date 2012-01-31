#!/usr/bin/perl -w

#
# GPIB Connection class for Lab::Bus::VISA
# This one implements a GPIB-Standard connection on top of VISA (translates 
# GPIB parameters to VISA resource names, mostly, to be exchangeable with other GPIB
# connections.
#

# TODO: Access to GPIB VISA attributes, device clear, ...


package Lab::Connection::VISA_GPIB;
our $VERSION = '2.94';

use strict;
use Lab::Bus::VISA;
use Lab::Connection::GPIB;
use Lab::Exception;


our @ISA = ("Lab::Connection::GPIB");

our %fields = (
	bus_class => 'Lab::Bus::VISA',
	resource_name => undef,
	wait_status=>0, # sec;
	wait_query=>10e-6, # sec;
	read_length=>1000, # bytes
	gpib_board=>0,
	gpib_address=>1,
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class, parameter checks
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	return $self;
}


#
# Translating from plain GPIB-driverish to VISAslang
#


#
# perform a serial poll on the bus and return the status byte
#
sub serial_poll {
	my $self=shift;
	
	# Soon to be implemented
	return 0;
}


#
# adapting bus setup to VISA
#
sub _setbus {
	my $self=shift;
	my $bus_class = $self->bus_class();

	no strict 'refs';
	$self->bus($bus_class->new($self->config())) || Lab::Exception::Error->throw( error => "Failed to create bus $bus_class in " . __PACKAGE__ . "::_setbus.\n");
	use strict;

	#
	# build VISA resource name
	#
	my $resource_name = 'GPIB'.$self->gpib_board().'::'.$self->gpib_address();
	$resource_name .= '::'.$self->gpib_saddress() if defined $self->gpib_saddress();
	$resource_name .= '::INSTR';
	$self->resource_name($resource_name);
	$self->config()->{'resource_name'} = $resource_name;
	
	# again, pass it all.
	$self->connection_handle( $self->bus()->connection_new( $self->config() ));

	return $self->bus();
}


1;

#
# Read,Write,Query are OK in the version from Lab::Connection
#


=pod

=encoding utf-8

=head1 NAME

Lab::Connection::VISA_GPIB - GPIB-type connection class which uses L<Lab::Bus::VISA> 
and thus NI VISA (L<Lab::VISA>) as a backend.

=head1 SYNOPSIS

This class is not called directly. To make a GPIB suppporting instrument use 
Lab::Connection::VISA_GPIB, set the connection_type parameter accordingly:

 $instrument = new HP34401A(
    connection_type => 'VISA_GPIB',
    gpib_board => 0,
    gpib_address => 14
 )

=head1 DESCRIPTION

C<Lab::Connection::VISA_GPIB> provides a GPIB-type connection with L<Lab::Bus::VISA> using
NI VISA (L<Lab::VISA>) as backend.

It inherits from L<Lab::Connection::GPIB> and subsequently from L<Lab::Connection>.

The main feature is to assemble the standard gpib connection options
  gpib_board
  gpib_address
  gpib_saddress
into a valid NI VISA resource name (see L<Lab::Connection::VISA> for more details).

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::VISA_GPIB(
    gpib_board => 0,
    gpib_address => $address,
    gpib_saddress => $secondary_address
 }


=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.


=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $GPIB_Address=$instrument->Config(gpib_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_Address = $connection->Config()->{'gpib_address'};
 
=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::GPIB>

=item * L<Lab::Connection::VISA>

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
