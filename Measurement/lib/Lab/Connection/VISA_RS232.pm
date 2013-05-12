#!/usr/bin/perl -w

#
# RS232 Connection class for Lab::Bus::VISA
# This one implements a RS232-Standard connection on top of VISA (translates 
# RS232 settings to VISA attributes, mostly).
#

# TODO: Access to GPIB VISA attributes, device clear, ...

die "Work in progress\n";

package Lab::Connection::VISA_RS232;
our $VERSION = '3.11';

use strict;
use Lab::Bus::VISA;
use Lab::Connection::RS232;
use Lab::Exception;


our @ISA = ("Lab::Connection::RS232");

our %fields = (
	bus_class => 'Lab::Bus::VISA',
	resource_name => undef,
	wait_status=>0, # sec;
	wait_query=>10e-6, # sec;
	read_length=>1000, # bytes
	port=> undef,
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
	my $resource_name = $self->port();
	$resource_name .= '::INSTR';
	$self->resource_name($resource_name);
	$self->config()->{'resource_name'} = $resource_name;
	
	# again, pass it all.
	$self->connection_handle( $self->bus()->connection_new( $self->config() ));

	# TODO: now we need to set all the RS232 communication parameters, since the VISA
	# bus does not evaluate them by default. (compared to RS232 bus)

	return $self->bus();
}


1;

#
# Read,Write,Query are OK in the version from Lab::Connection
#


=pod

=encoding utf-8

=head1 NAME

Lab::Connection::VISA_RS232 - RS232-type connection class which uses L<Lab::Bus::VISA> 
and thus NI VISA (L<Lab::VISA>) as a backend.

=head1 SYNOPSIS

This class is not called directly. To make a RS232 suppporting instrument use 
Lab::Connection::VISA_RS232, set the connection_type parameter accordingly:

 $instrument = new BlaDeviceType(
    connection_type => 'VISA_RS232',
    port => 'ASRL1',
 )

=head1 DESCRIPTION

C<Lab::Connection::VISA_RS232> provides a RS232-type connection with L<Lab::Bus::VISA> using
NI VISA (L<Lab::VISA>) as backend.

It inherits from L<Lab::Connection::RS232> and subsequently from L<Lab::Connection>.

The main feature is to set upon initialization all the RS232 libe parameters
  baud_rate
  ...

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::VISA_RS232(
    port => 'ASRL1',
    baud_rate => 9600,
 )


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

=item * L<Lab::Connection::RS232>

=item * L<Lab::Connection::VISA>

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich
           2012      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
