#!/usr/bin/perl -w
# POD

package Lab::Instrument::TCPIP::Prologix;

use strict;
use warnings;
use Time::HiRes qw (usleep sleep);

use Lab::Instrument::TCPIP; 
our @ISA = ('Lab::Instrument::TCPIP');

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

sub new {
	my $self = shift;
	my %args = @_;
	die "Not GPIB addr given\n" unless (exists $args{'GPIBaddr'});

	$args{'PeerPort'} = 1234 unless (exists $args{'PeerPort'});

	my $object = $self->SUPER::new(%args);
	return undef unless (defined $object);

	$object->{'CommandDelay'} = 0.01;
	# basic init
	$object->{'GPIBaddr'} = $args{'GPIBaddr'};	
	$object->{'client'}->send("++auto 0\n");
	
	return $object;
}

# basic functionality

sub Read {
	my $self = shift;
	$self->Write("++read eoi");
	return $self->SUPER::Read(@_);
}

sub Write {
	my $self = shift;
	my @data = @_;
	unshift(@data,'++addr '.$self->{'GPIBaddr'});
	return $self->SUPER::Write(@data);
}

# BrutalRead and Clear not implemented

1;
__END__

=head1 NAME

Lab::Instrument::TCPIP::Prologix - Perl extension for interfaceing with instruments via Prologix LAN-GPIB gateway

=head1 SYNOPSIS

  use Lab::Instrument;
  my $h = Lab::Instrument->new( Interface => 'TCPIP::Prologix',
                                PeerAddr  => 'cs025',
                                GPIBAddr  => 12);
  
  # or
  my $h2 = Lab::Instrument->new( Interface => 'TCPIP::Prologix',
                                 reuse     => $h,
                                 GPIBAddr  => 16 );  

=head1 DESCRIPTION

This is an interface package for Lab::Instruments to communicate via LAN-GPIB gateway.

=head1 CONSTRUCTOR

=head2 new

The PeerAddr of the Gateway box as well as the GPIB address has to be given. A delay of 10 ms
is added to the communication because a lot of old instruments with GPIB are quite slow.

=head1 METHODS

Used by C<Lab::Instrument>. Not for direct use!!!

=head2 Read

Reads data. So far only read whole line is implemented. Timeout not implemented so far!

=head2 Write

Sent data to instrument

=head2 Handle

Inherited from C<Lab::Instrument::TCPIP>

=head1 CAVEATS/BUGS

Probably many. So far BrutalRead and Clear are not implemented because not needed for this interface. Timeout should be
added in the next version.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=item L<Lab::Instrument::TCPIP>

=item L<IO::Socket::INET>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2010      Matthias Voelker <mvoelker@cpan.org>     

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

