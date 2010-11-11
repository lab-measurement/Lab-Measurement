#!/usr/bin/perl -w
# POD

package Lab::Instrument::TCPIP;

use strict;
use warnings;

use Lab::Instrument; 
use IO::Socket::INET;

our $TCPIP_DEBUG = 0;
our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

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
		if ( ref($args{'reuse'}) =~ /IO::Socket::INET/ ) {
			# IO socket given
			$object->{'client'} = $args{'reuse'};
		} else {
			# Lab::Instrument object!
			$object->{'client'} = $args{'reuse'}->Handle()->{'client'};
		}		
	} else {
		# clear new socket
		$args{'PeerPort'} = 5025 unless ( exists $args{'PeerPort'});
		$args{'Proto'} = 'tcp' unless ( exists $args{'Proto'});
		if ($TCPIP_DEBUG) {
			require Data::Dumper;
			print "TCPIP_DEBUG: Calling IO:Socket::INET with ".scalar(keys %args)." args:\n";
			print Data::Dumper->Dump([\%args],[\%args]);
		}
		$object->{'client'} = IO::Socket::INET->new(%args);
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
	# only all reading implemented so far
	my $result =  $self->{'client'}->getline();
	chomp($result);
	return $result;
}

sub Write {
	my $self = shift;
	return $self->{'client'}->send(join("\n",@_)."\n");
}

# BrutalRead and Clear not implemented

1;
__END__

=head1 NAME

Lab::Instrument::TCPIP - Perl extension for interfaceing with instruments via TCPIP

=head1 SYNOPSIS

  use Lab::Instrument;
  my $h = Lab::Instrument->new( Interface => 'TCPIP',
				                PeerAddr  => 'cs025',
				                PeerPort  => 5025);
  
  # or
  my $h2 = Lab::Instrument->new( Interface => 'TCPIP',
				                 reuse => $h);  

=head1 DESCRIPTION

This is an interface package for Lab::Instruments to communicate via TCP socket. It
is used for the TCPIP interface of e.g. Agilent instruments.

=head1 CONSTRUCTOR

=head2 new

All parameters are used as by C<IO::Socket::INET>. PeerAddr is needed in ervay case. The default PeerPort is 5025
as used by Agilent instruments. An additional parameter C<reuse> is avaliable if two instruments use the same address and 
port. This is mainly implemented for LANprologix gateway. C<reuse> can be a socket or a C<Lab::Instrument...> package.

=head1 METHODS

Used by C<Lab::Instrument>. Not for direct use!!!

=head2 Read

Reads data. So far only read whole line is implemented. Timeout not implemented so far!

=head2 Write

Sent data to instrument

=head2 Handle

Give instrument object handle

=head1 CAVEATS/BUGS

Probably many. So far BrutalRead and Clear are not implemented because not needed for this interface. Timeout should be
added in the next version.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=item L<IO::Socket::INET>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2010      Matthias Voelker <mvoelker@cpan.org>     

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

