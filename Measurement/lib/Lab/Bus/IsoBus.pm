#!/usr/bin/perl -w


package Lab::Bus::IsoBus;
our $VERSION = '3.00';

use strict;
use Lab::Connection;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Bus");


our %fields = (
	type => 'IsoBus',
	base_connection => undef,
	brutal => 0,	# brutal as default?
	wait_status=>10e-6, # sec;
	wait_query=>10e-6, # sec;
	query_length=>300, # bytes
	query_long_length=>10240, #bytes
	read_length => 1000, # bytes
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
			# TODO implement twin detection
			# $Lab::Bus::BusList{$self->type()}->{'default'} = $self;
			# weaken($Lab::Bus::BusList{$self->type()}->{'default'});
		}
	}

	# set the connection $self->base_connection to the parameters required by IsoBus
	# clear the connection if possible

#   19     # we need to set the following RS232 options: 9600baud, 8 data bits, 1 stop bit, no parity, no flow control
#   20     # what is the read terminator? we assume CR=13 here, but this is not set in stone
#   21     # write terminator should I think always be CR=13=0x0d
#   22     
#   23     my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_BAUD, 9600);
#   24     if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
#   25 
#   26     $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR, 13);
#   27     if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar: $status";}
#   28 
#   29     $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, 1);
#   30     if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar enabled: $status";}
#   31 
#   32     $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_END_IN,   
#              $Lab::VISA::VI_ASRL_END_TERMCHAR);
#   33     if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting end termchar: $status";}
#   34 
#   35     #  here we might still have to reinitialize the serial port to make the settings come into effect. how???

	return $self;
}



sub connection_new { # @_ = ({ isobus_address => $isobus_address })
	my $self = shift;
	my $args = undef;
	my $status = undef;
	my $connection_handle=undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $isobus_address = $args->{'isobus_address'};

	# check that this is a number and in the valid range

        # we dont actually have to open anything here

	# we abuse the isobus_address as connection handle
	return $isobus_address;
}


sub connection_read { # @_ = ( $connection_handle, $args = { read_length, brutal }
	my $self = shift;
	my $connection_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();
	my $result = undef;

	$result=$self->base_connection->Read({
		    brutal => $brutal, 
		    read_length => $read_length,
	});

	return $result;
}



sub connection_write { # @_ = ( $connection_handle, $args = { command, wait_status }
	my $self = shift;
	my $connection_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $command = $args->{'command'} || undef;

	my $write_cnt = 0;

	if(!defined $command) {
		Lab::Exception::CorruptParameter->throw(
			error => "No command given to " . __PACKAGE__ . "::connection_write().\n",
		);
	}
	else {
		$write_cnt=$self->base_connection->Write({
			# build the format for an IsoBus command
			command => sprintf("@%d%s\r",$connection_handle,$command),
		});
        );

	return $write_cnt;
	}
}



sub connection_query { # @_ = ( $connection_handle, $args = { command, read_length, wait_status, wait_query, brutal }
	my $self = shift;
	my $connection_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $command = $args->{'command'} || undef;
	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();
	my $wait_status = $args->{'wait_status'} || $self->wait_status();
	my $wait_query = $args->{'wait_query'} || $self->wait_query();

	my $result = undef;
	my $status = undef;
	my $write_cnt = 0;
	my $read_cnt = undef;


	$write_cnt=$self->connection_write($args);

	usleep($wait_query); #<---ensures that asked data presented from the device

	$result=$self->connection_read($args);
	return $result;
}




#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
	my $self=shift;

	# Only one VISA bus for the moment, stored as "default"
	if(!$self->ignore_twins()) {
#		if(defined $Lab::Bus::BusList{$self->type()}->{'default'}) {
#			return $Lab::Bus::BusList{$self->type()}->{'default'};
#		}
	}

	return undef;
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::IsoBus - Oxford Instruments IsoBus bus

=head1 SYNOPSIS

soon

=head1 SEE ALSO

=over 4

=item * L<Lab::Bus>

=item * L<Lab::Connection>

=item * and many more...

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut



1;

