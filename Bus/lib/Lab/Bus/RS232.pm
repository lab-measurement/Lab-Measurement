#!/usr/bin/perl -w
# POD

package Lab::Bus::RS232;

use strict;
use warnings;

use Lab::Bus;
use Data::Dumper;

our @ISA = ("Lab::Bus");

# load serial driver
use vars qw( $OS_win);
BEGIN {
   $OS_win = ($^O eq "MSWin32") ? 1 : 0;

   if ($OS_win) {
     eval "use Win32::Serialport";
     die "$@\n" if ($@);
   }
   else {
     eval "use Device::Serialport";
     die "$@\n" if ($@);
   }
} # End BEGIN

our $RS232_DEBUG = 0;
our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);
our $WIN32 = ($^O eq "MSWin32") ? 1 : 0;

my %fields = (
	client => undef,
	type => 'RS232',
	port => '/dev/ttyS0',
	baudrate => 38400,
	parity => 'none',
	databits => 8,
	stopbits => 1,
	handshake => 'none',
	timeout => 500,
	read_length => 'all',
	brutal => 0,
	wait_query => 10,
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->_construct(__PACKAGE__, \%fields);


	# parameter parsing
	$self->port($self->config('port')) if defined $self->config('port');
	warn ("No port supplied to RS232 bus. Assuming default port " . $self->config('port') . "\n") if(!defined $self->config('port')) 
	$self->port($self->config('baudrate')) if defined $self->config('baudrate');
	$self->parity($self->config('parity')) if defined $self->config('parity');
	$self->databits($self->config('databits')) if defined $self->config('databits');
	$self->stopbits($self->config('stopbits')) if defined $self->config('stopbits');
	$self->handshake($self->config('handshake')) if defined $self->config('handshake');
	$self->timeout($self->config('timeout')) if defined $self->config('timeout');



	# search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
	if( $class eq __PACKAGE__ ) { # careful - do only if this is not a parent class constructor
		if($twin = $self->_search_twin()) {
			undef $self;
			return $twin;	# ...and that's it.
		}
		else {
			$Lab::Bus::BusList{$self->type()}->{} = $self;
			weaken($Lab::Bus::BusList{$self->type()}->{$self->port()});


			# clear new port
			if ($WIN32) {
				$self->client( new Win32::Serialport($self->config('port')) or warn "Could not open serial port\n" );
			} else {
				$self->client( new Device::Serialport($self->config('port')) or warn "Could not open serial port\n" );
			}
			# config port if needed 

			if(defined $self->client) {
				$self->client()->purge_all;
				$self->client()->read_const_time($self->timeout());
				$self->client()->handshake($self->config('handshake')) if (exists $self->config('handshake'));
				$self->client()->baudrate($self->config('baudrate')) if (exists $self->config('baudrate'));
				$self->client()->parity($self->config('parity')) if (exists $self->config('parity'));
				$self->client()->databits($self->config('databits')) if (exists $self->config('databits'));
				$self->client()->stopbits($self->config('stopbits')) if (exists $self->config('stopbits'));
			}
			else {
				Lab::Exception::Error->throw( error => "Error initializing the serial interface\n" . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__) ); }
			}

			return $self;
		}
	}
}






#
# This will be short.
#
sub InstrumentNew {
	my $self = shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	return { handle_type => 'RS232', valid => 1 };
}



sub InstrumentRead { # @_ = ( $instrument_handle, $args = { read_length, brutal }
	my $self = shift;
	my $instrument_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $command = $args->{'command'} || undef;
	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();

	my $result = "";
	my $buf = "";
	my $raw = "";

	if($length eq 'all') {
		do {
			$buf = $self->client()->read(4096);
			$result .= $buf;
		} while(length($buf) == 4096);
	}
	else {
		$result = $self->client()->read($length); # note: taken from older code - is 4096 some strong limit? If yes, this needs more work.
	}

	return $result;
}



sub InstrumentQuery { # @_ = ( $instrument_handle, $args = { command, read_length, wait_query, brutal }
	my $self = shift;
	my $instrument_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $command = $args->{'command'} || undef;
	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();
	my $wait_status = $args->{'wait_status'} || $self->wait_status();
	my $wait_query = $args->{'wait_query'} || $self->wait_query();
	my $result = undef;

    $self->InstrumentWrite($args);

    usleep($wait_query); #<---ensures that asked data presented from the device

    $result=$self->InstrumentRead($args);
    return $result;
}




sub InstrumentWrite { # @_ = ( $instrument_handle, $args = { command, brutal }
	my $self = shift;
	my $instrument_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $command = $args->{'command'} || undef;
	my $brutal = $args->{'brutal'} || $self->brutal();

	my $status = undef;


	if(!defined $command) {
		Lab::Exception::CorruptParameter->throw(
			error => "No command given to " . __PACKAGE__ . "::InstrumentWrite().\n" . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
		);
	}
	else {
		$status = $self->client()->write($command);
	}


	if(!$status && !$brutal) {
		Lab::Exception::RS232Error->throw(
			error => "Error in " . __PACKAGE__ . "::InstrumentWrite() while executing $command: write failed.\n" . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
			status => $status,
		);
	}
	elsif($brutal) {
		warn "(brutal=>Ignored) error in " . __PACKAGE__ . "::InstrumentWrite() while executing $command: write failed.\n" . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__);
	}

	return 1;
}



sub InstrumentClear {
	my $self = shift;
	my $instrument_handle=shift;

	return 1;
}



#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
	my $self=shift;

	if(!$self->ignore_twins()) {
		for my $conn ( values %{$Lab::Bus::BusList{$self->type()}} ) {
			return $conn if $conn->port() == $self->port();
		}
	}
	return undef;
}


# BrutalRead and Clear not implemented

1;
__END__

=head1 NAME

Lab::Instrument::RS232 - Perl extension for interfaceing with instruments via RS232 or Virtual Comm ports

=head1 SYNOPSIS

  use Lab::Instrument;
  my $h = Lab::Instrument->new( Interface => 'RS232',
				                port      => 'COM1|/dev/ttyUSB1');
  
  # or
  my $h2 = Lab::Instrument->new( Interface => 'RS232',
				                 reuse     => $h);  # opens a second Instrument on the same port

=head1 DESCRIPTION

This is an interface package for Lab::Instruments to communicate via RS232 or Virtual Comm port e.g. for
FTDI devices.

=head1 CONSTRUCTOR

=head2 new

All parameters are used as by C<Device::Serialport>. port is needed in every case. An additional parameter C<reuse> 
is avaliable if two instruments use the same port. This is mainly implemented for USBprologix gateway. 
C<reuse> can be a Serialport object or a C<Lab::Instrument...> package. Default value for timeout is 500ms and
can be set by the parameter "timeout". Other options: handshake, baudrate, databits, stopbits and parity

=head1 METHODS

Used by C<Lab::Instrument>. Not for direct use!!!

=head2 Read

Reads data.

=head2 Write

Sent data to instrument

=head2 Handle

Give instrument object handle

=head1 CAVEATS/BUGS

Probably many. So far BrutalRead and Clear are not implemented because not needed for this interface.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=item L<Win32::Serialport>

=item L<Device::Serialport>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2010      Matthias Voelker <mvoelker@cpan.org>     

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

