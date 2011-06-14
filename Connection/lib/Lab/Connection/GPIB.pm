#!/usr/bin/perl -w

#
# This is the GPIB Connection base class. It provides the interface definition for all
# connections implementing the GPIB protocol.
#
# In your scripts, use the implementing classes (e.g. Lab::Connection::LinuxGPIB).
# They are distributed with their bus (Lab::Connection::LinuxGPIB is implemented
# in Lab/Bus/GPIB.pm)
#
# Instruments using a GPIB connection will check the inheritance tree of the provided connection
# for this class.
#
package Lab::Connection::GPIB;
use strict;
use Lab::Exception;

our @ISA = ("Lab::Connection");


our %fields = (
	bus_class => undef, # 'Lab::Bus::LinuxGPIB', 'Lab::Bus::VISA', ...
	gpib_address	=> 0,
	gpib_saddress => undef, # secondary address, if needed
	brutal => 0,	# brutal as default?
	wait_status=>0, # usec;
	wait_query=>10, # usec;
	read_length=>1000, # bytes
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->_construct(__PACKAGE__, \%fields);

	return $self;
}



#
# These are the method stubs you have to overwrite when implementing the GPIB connection for your
# hardware/driver. See documentation for detailed description of the parameters, expected exceptions
# and expected return values.
#
# You might just be satisfied with the generic ones from Lab::Connection, take a look at them.
#

# sub Clear {	# @_ = ()
# 	return 0;
# }


# sub Write { # @_ = ( command => $cmd, wait_status => $wait_status, brutal => 1/0 )
# 	return 0; # status true/false
# }


# sub Read { # @_ = ( read_length => $read_length, brutal => 1/0 )
# 	return 0; # result
# }



1;

