#!/usr/bin/perl -w

package Lab::Connection::DEBUG;
use strict;
use Time::HiRes qw (usleep sleep);
use Lab::Connection;
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Connection");


our %fields = (
	bus_class => "Lab::Bus::DEBUG",
	brutal => 0,	# brutal as default?
	type => 'DEBUG',
	wait_status=>10, # usec;
	wait_query=>10, # usec;
	query_length=>300, # bytes
	query_long_length=>10240, #bytes
	read_length => 1000, # bytesx

	instrument_index => 0,
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->_construct(__PACKAGE__, \%fields);

	return $self;
}



=head1 NAME

Lab::Connection::DEBUG - debug connection


=head1 DESCRIPTION

Connection to the DEBUG bus.

=cut


1;