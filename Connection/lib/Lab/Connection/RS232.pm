#!/usr/bin/perl -w
# POD

package Lab::Instrument::RS232;

use strict;
use warnings;

use Lab::Instrument; 

# load serial driver
use vars qw( $OS_win);
BEGIN {
   $OS_win = ($^O eq "MSWin32") ? 1 : 0;

   if ($OS_win) {
     eval "use Win32::SerialPort";
     die "$@\n" if ($@);
   }
   else {
     eval "use Device::SerialPort";
     die "$@\n" if ($@);
   }
} # End BEGIN

our $RS232_DEBUG = 0;
our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);
our $WIN32 = ($^O eq "MSWin32") ? 1 : 0;

sub new {
	my $self = shift;
	# get arguments
	my %args = @_;
	
	# create hash ref
	my $object = {};
	
	# create object
	bless ($object,$self);

	if (exists $args{'reuse'}) {
		# reuse INET client object
		if ( ref($args{'reuse'}) =~ /::SerialPort$/ ) {
			# IO socket given
			$object->{'client'} = $args{'reuse'};
		} else {
			# Lab::Instrument object!
			$object->{'client'} = $args{'reuse'}->Handle()->{'client'};
		}		
	} else {
		# clear new port
        if ($WIN32) {
            $object->{'client'} = new Win32::SerialPort($args{'Port'}) or print "Could not open serial port\n";
        } else {
            $object->{'client'} = new Device::SerialPort($args{'Port'}) or print "Could not open serial port\n";
        }
        # config port if needed 
        $object->{'client'}->purge_all;
        $args{'Timeout'} = 500 unless (exists $args{'Timeout'} );
        $object->{'client'}->read_const_time($args{'Timeout'});
        $object->{'client'}->handshake($args{'Handshake'}) if (exists $args{'Handshake'});
        $object->{'client'}->baudrate($args{'Baudrate'}) if (exists $args{'Baudrate'});
        $object->{'client'}->parity($args{'Parity'}) if (exists $args{'Parity'});
        $object->{'client'}->databits($args{'Databits'}) if (exists $args{'Databits'});
        $object->{'client'}->stopbits($args{'Stopbits'}) if (exists $args{'Stopbits'});
	}
	return $object if (defined $object->{'client'});
	# init failed
	return undef;
}

# to be compatible with Lab::Instument and the reuse function of this package
sub Handle {
	my $self = shift;
	return $self;
}

# basic functionality

sub Read {
	my $self = shift;
	my $length = shift;
    my $result = undef;

    if ($length eq 'all' ) {

  	  my $buf = $self->{'client'}->read(4096);
      while (length($buf) == 4096) {

        $result .= $buf;
        $buf = $self->{'client'}->read(4096);
      }
      $result .= $buf;

    } else {
      $result = $self->{'client'}->read($length);
    }
	chomp($result);
	return $result;
}

sub Write {
	my $self = shift;
	return $self->{'client'}->write(join("\n",@_));
}

# BrutalRead and Clear not implemented

1;
__END__

=head1 NAME

Lab::Instrument::RS232 - Perl extension for interfaceing with instruments via RS232 or Virtual Comm Ports

=head1 SYNOPSIS

  use Lab::Instrument;
  my $h = Lab::Instrument->new( Interface => 'RS232',
				                Port      => 'COM1|/dev/ttyUSB1');
  
  # or
  my $h2 = Lab::Instrument->new( Interface => 'RS232',
				                 reuse     => $h);  # opens a second Instrument on the same port

=head1 DESCRIPTION

This is an interface package for Lab::Instruments to communicate via RS232 or Virtual Comm Port e.g. for
FTDI devices.

=head1 CONSTRUCTOR

=head2 new

All parameters are used as by C<Device::SerialPort>. Port is needed in every case. An additional parameter C<reuse> 
is avaliable if two instruments use the same port. This is mainly implemented for USBprologix gateway. 
C<reuse> can be a SerialPort object or a C<Lab::Instrument...> package. Default value for timeout is 500ms and
can be set by the parameter "Timeout". Other options: Handshake, Baudrate, Databits, Stopbits and Parity

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

=item L<Win32::SerialPort>

=item L<Device::SerialPort>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2010      Matthias Voelker <mvoelker@cpan.org>     

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

