#!/usr/bin/perl -w
# POD

package Lab::Connection::RS232;

use strict;
use warnings;

use Lab::Connection;
use Data::Dumper;

our @ISA = ("Lab::Connection");

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

my %fields = (
	Client => undef,
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $args = shift;
	my $self = $class->SUPER::new($args); # getting fields and _permitted from parent class
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;

	# clear new port
	if ($WIN32) {
		$self->Client( new Win32::SerialPort($self->Config()->{'Port'}) or print "Could not open serial port\n" );
	} else {
		$self->Client( new Device::SerialPort($self->Config()->{'Port'}) or print "Could not open serial port\n" );
	}
	# config port if needed 
	$self->Client()->purge_all;
	$self->Config()->{'Timeout'} = 500 unless (exists $self->Config()->{'Timeout'} );
	$self->Client()->read_const_time($self->Config()->{'Timeout'});
	$self->Client()->handshake($self->Config()->{'Handshake'}) if (exists $self->Config()->{'Handshake'});
	$self->Client()->baudrate($self->Config()->{'Baudrate'}) if (exists $self->Config()->{'Baudrate'});
	$self->Client()->parity($self->Config()->{'Parity'}) if (exists $self->Config()->{'Parity'});
	$self->Client()->databits($self->Config()->{'Databits'}) if (exists $self->Config()->{'Databits'});
	$self->Client()->stopbits($self->Config()->{'Stopbits'}) if (exists $self->Config()->{'Stopbits'});

	return $self if (defined $self->{'Client'});
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

  	  my $buf = $self->{'Client'}->read(4096);
      while (length($buf) == 4096) {

        $result .= $buf;
        $buf = $self->{'Client'}->read(4096);
      }
      $result .= $buf;

    } else {
      $result = $self->{'Client'}->read($length);
    }
	chomp($result);
	return $result;
}

sub Write {
	my $self = shift;
	return $self->{'Client'}->write(join("\n",@_));
}

sub WriteRaw {
	my $self = shift;
	return $self->{'Client'}->write(join("",@_));
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

