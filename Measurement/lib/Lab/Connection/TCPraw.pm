#!/usr/bin/perl -w

package Lab::Connection::TCPraw;
our $VERSION = '3.10';

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connection;
use Lab::Exception;

our @ISA = ("Lab::Connection");

our %fields = (
	bus_class => 'Lab::Bus::TCPraw',
	wait_status=>0, # usec;
	wait_query=>10e-6, # sec;
	read_length=>1000, # bytes
	timeout=>1, # seconds
	ip_port=>5025, # the default tcp port for raw connections
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	return $self;
}

sub Write {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }
	
	my $timeout = $options->{'timeout'} || $self->timeout();
	$self->bus()->timeout($self->connection_handle(), $timeout);
	
	return $self->bus()->connection_write($self->connection_handle(), $options);
}


sub Read {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }
	
	my $timeout = $options->{'timeout'} || $self->timeout();
	$self->bus()->timeout($self->connection_handle(), $timeout);

	return $self->bus()->connection_read($self->connection_handle(), $options);
}

sub Query {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	my $wait_query=$options->{'wait_query'} || $self->wait_query();
	my $timeout = $options->{'timeout'} || $self->timeout();
	$self->bus()->timeout($self->connection_handle(), $timeout);
	
	$self->Write( $options );
	usleep($wait_query);
	return $self->Read($options);
}

sub Clear {
	my $self=shift;
	my $options=undef;
	return $self->bus()->connection_device_clear($self->connection_handle());
}


#
# Query from Lab::Connection is sufficient
#



=pod

=encoding utf-8

=head1 NAME

Lab::Connection::TCPraw - connection class which uses a tcp connection as a backend.

=head1 SYNOPSIS

$instrument = new HP34401A(
   connection_type => 'TCPraw',
   ip_address => '1.2.3.4'
)
 
=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich
           2012      Hermann Kraus
           2013      Andreas K. Huettel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
