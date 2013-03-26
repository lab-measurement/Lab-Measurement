#!/usr/bin/perl -w

#TODO: Nonblocking mode + timeouts
#TODO: Control channel (http://cp.literature.agilent.com/litweb/pdf/5989-6717EN.pdf)

package Lab::Bus::TCPraw;
our $VERSION = '3.10';

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper; 
use IO::Socket;

our @ISA = ("Lab::Bus");


our %fields = (
	type => 'TCPraw',
	brutal => 0,
    read_length=>1000, # bytes
    wait_query=>10e-6, # sec;
	);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	# search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
	if( $class eq __PACKAGE__ ) { # careful - do only if this is not a parent class constructor
		if($twin = $self->_search_twin()) {
			undef $self;
			return $twin;	# ...and that's it.
		}
		else {
			$Lab::Bus::BusList{$self->type()}->{'default'} = $self;
			weaken($Lab::Bus::BusList{$self->type()}->{'default'});
		}
	}
	
	return $self;
}



sub connection_new {
	my $self = shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }
	my $ip_address = $args->{'ip_address'};
#	
    my $socket = new IO::Socket::INET(PeerAddr => $ip_address,
                                PeerPort => '5025',
                                Proto => 'tcp',
                                Timeout => 1,
                                Blocking => 1,);

    Lab::Exception::CorruptParameter->throw(error => $!.": '$ip_address'\n") unless $socket;
	my $connection_handle =  { valid => 1, type => "TCPraw", socket => $socket };  
	return $connection_handle;
}

#TODO: Status, Errors?
sub connection_read { # @_ = ( $connection_handle, $args = { read_length, brutal }
	my $self = shift;
	my $connection_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();
	my $socket = $connection_handle->{'socket'};

	my $result = undef;
	my $fragment = undef;

	sysread($socket, $result, $read_length);


	# strip spaces and null byte
	$result =~ s/[\n\r\x00]*$//;

	#
	# timeout occured - throw exception, but include the received data
	# if the "Brutal" option is present, ignore the timeout and just return the data
	#
# 	if( $ib_bits->{'ERR'} && $ib_bits->{'TIMO'} && !$brutal ) {
# 		Lab::Exception::GPIBTimeout->throw(
# 			error => sprintf("ibrd failed with a timeout, ibstatus %x\n", $ibstatus),
# 			ibsta => $ibstatus,
# 			ibsta_hash => $ib_bits,
# 			data => $result
# 		);
# 	}
	# no timeout, regular return
	return $result;
}


#TODO: Undocumented
sub connection_query { # @_ = ( $connection_handle, $args = { command, read_length, wait_status, wait_query, brutal }
	my $self = shift;
	my $connection_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $wait_query = $args->{'wait_query'} || $self->wait_query();
	my $result = undef;

	$self->connection_write($args);

    sleep($wait_query); #<---ensures that asked data presented from the device

    $result = $self->connection_read($args);
    return $result;
}



#TODO: Error checking
sub connection_write 
{ # @_ = ( $connection_handle, $args = { command }
	my $self = shift;
	my $connection_handle = shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $command = $args->{'command'} || undef;

	if(!defined $command) {
		Lab::Exception::CorruptParameter->throw(
			error => "No command given to " . __PACKAGE__ . "::connection_write().\n",
		);
	}
	
    print { $connection_handle->{'socket'} } "$command\n";
	return 1;
}



sub connection_settermchar 
{ 

	return 1;
}

sub connection_enabletermchar 
{ 
	return 1;
}

sub serial_poll 
{
	my $self = shift;
	my $connection_handle = shift;
	return undef;
}

sub connection_clear 
{
	my $self = shift;
	my $connection_handle=shift;

	close($connection_handle->{'socket'});
}

sub connection_device_clear
{
}

sub timeout 
{
	my $self=shift;
	my $connection_handle=shift;
	my $timo=shift;
	my $timoval=undef;
	
	Lab::Exception::CorruptParameter->throw( error => "The timeout value has to be a positive decimal number of seconds, ranging 0-1000.\n" )
    	if($timo !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ || $timo <0 || $timo>1000);
    
    if($timo == 0)			{ $timoval=0} # never time out
    if($timo <= 1e-5)		{ $timoval=1 }
    elsif($timo <= 3e-5)	{ $timoval=2 }
    elsif($timo <= 1e-4)	{ $timoval=3 }
    elsif($timo <= 3e-4)	{ $timoval=4 }
    elsif($timo <= 1e-3)	{ $timoval=5 }
    elsif($timo <= 3e-3)	{ $timoval=6 }
    elsif($timo <= 1e-2)	{ $timoval=7 }
    elsif($timo <= 3e-2)	{ $timoval=8 }
    elsif($timo <= 1e-1)	{ $timoval=9 }
    elsif($timo <= 3e-1)	{ $timoval=10 }
    elsif($timo <= 1)		{ $timoval=11 }
    elsif($timo <= 3)		{ $timoval=12 }
    elsif($timo <= 10)		{ $timoval=13 }
    elsif($timo <= 30)		{ $timoval=14 }
    elsif($timo <= 100)		{ $timoval=15 }
    elsif($timo <= 300)		{ $timoval=16 }
    elsif($timo <= 1000)	{ $timoval=17 }
    
# 	my $ibstatus=ibtmo($connection_handle->{'gpib_handle'}, $timoval);
# 	
# 	my $ib_bits=$self->ParseIbstatus($ibstatus);
# 
# 	if($ib_bits->{'ERR'}==1) {
# 		Lab::Exception::GPIBError->throw(
# 			error => sprintf("Error in " . __PACKAGE__ . "::timeout(): ibtmo failed with status %x\n", $ibstatus) . Dumper($ib_bits),
# 			ibsta => $ibstatus,
# 			ibsta_hash => $ib_bits,
# 		);
# 	}
#    print "timeout(): not implemented!\n";
}


#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin
{
	my $self=shift;

	if(!$self->ignore_twins()) {
		for my $conn ( values %{$Lab::Bus::BusList{$self->type()}} ) {
			return $conn; # if $conn->gpib_board() == $self->gpib_board();
		}
	}
	return undef;
}


1;

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::LinuxGPIB - LinuxGPIB bus

=head1 SYNOPSIS

This is the USB TMC (Test & Measurement Class) bus class.

  my $tmc = new Lab::Bus::USBtmc({ });

or implicit through instrument and connection creation:

  my $instrument = new Lab::Instrument::HP34401A({
    connection_type => 'USBtmc',
    tmc_address=>1,
  }

=head1 DESCRIPTION

Driver for the interface provided by the usbtmc linux kernel module.

Obviously, this will work for Linux systems only. 
On Windows, please use L<Lab::Bus::VISA>. The interfaces are (errr, will be) identical.

Note: you don't need to explicitly handle bus objects. The Instruments will create them themselves, and existing bus will
be automagically reused.


=head1 CONSTRUCTOR

=head2 new

 my $bus = Lab::Bus::USBtmc({
  });

Return blessed $self, with @_ accessible through $self->config().



=head1 Thrown Exceptions

Lab::Bus::USBtmc throws

  Lab::Exception::TMCOpenFileError
  
  Lab::Exception::CorruptParameter

=head1 METHODS

=head2 connection_new

  $tmc->connection_new({ tmc_address => $addr });

Creates a new connection ("instrument handle") for this bus. The argument is a hash, whose contents depend on the bus type.
For TMC at least 'tmc_address' is needed.

The handle is usually stored in an instrument object and given to connection_read, connection_write etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $GPIB->connection_new({ gpib_address => 13 });
  $result = $GPIB->connection_read($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.

=head2 connection_write

  $GPIB->connection_write( $InstrumentHandle, { Cmd => $Command } );

Sends $Command to the instrument specified by the handle.


=head2 connection_read

  $GPIB->connection_read( $InstrumentHandle, { Cmd => $Command, ReadLength => $readlength, Brutal => 0/1 } );

Sends $Command to the instrument specified by the handle. Reads back a maximum of $readlength bytes. If a timeout or
an error occurs, Lab::Exception::GPIBError or Lab::Exception::Timeout are thrown, respectively. The Timeout object
carries the data received up to the timeout event, accessible through $Exception->Data().

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.

=head2 timeout

  $GPIB->timeout( $connection_handle, $timeout );

Sets the timeout in seconds for GPIB operations on the device/connection specified by $connection_handle.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $GPIB_Address=$instrument->config(gpib_address);

Without arguments, returns a reference to the complete $self->config aka @_ of the constructor.

 $config = $bus->config();
 $GPIB_PAddress = $bus->config()->{'gpib_address'};

=head1 CAVEATS/BUGS

Sysfs settings for timeout not supported, yet.

=head1 SEE ALSO

=over 4

=item 

L<Lab::Bus>

=item and many more...

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2004-2006 Daniel Schröer <schroeer@cpan.org>, 
           2009-2010 Daniel Schröer, Andreas K. Hüttel (L<http://www.akhuettel.de/>) and David Kalok,
           2010      Matthias Völker <mvoelker@cpan.org>
           2011      Florian Olbrich, Andreas K. Hüttel
           2012      Hermann Kraus

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut







1;

