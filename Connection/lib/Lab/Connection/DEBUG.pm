#!/usr/bin/perl -w


use strict;

package Lab::Connection::DEBUG::HumanInstrument;

use base "Wx::App";

sub OnInit {

	my $frame = Wx::Frame->new( undef,           # parent window
		-1,              # ID -1 means any
		'wxPerl rules',  # title
		[-1, -1],         # default position
		[250, 150],       # size
	);

	$frame->Show( 1 );
}



package Lab::Connection::DEBUG;
use strict;
use threads;
use threads::shared;
use Thread::Semaphore;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connection;
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Connection");

our $thr = undef;


our %fields = (
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

	# no twin search - just register
	if( $class eq __PACKAGE__ ) { # careful - do only if this is not a parent class constructor
		my $i = 0;
		while(defined $Lab::Connection::ConnectionList{$self->type()}->{$i}) { $i++; }
		$Lab::Connection::ConnectionList{$self->type()}->{$i} = $self;
		weaken($Lab::Connection::ConnectionList{$self->type()}->{$i});
	}

	# This is not and will be no gui application, so start the gui main loop in a thread.
	# A little process communication will soon follow...
	print "Starting 'human instrument' console.\n";
	my $human_console = new Lab::Connection::DEBUG::HumanInstrument();
	$thr = threads->create( sub { $human_console->MainLoop(); print "NOOOOO!"; } );


	$thr->detach();

	return $self;
}


sub InstrumentNew { # @_ = ({ resource_name => $resource_name })
	my $self = shift;
	my $args = undef;
	my $status = undef;
	my $instrument_handle=undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	$instrument_handle = { debug_instr_index => $self->instrument_index() };

	$self->instrument_index($self->instrument_index() + 1 );

	return $instrument_handle;   
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

	my $result = undef;
	my $user_status = undef;
	my $message = "";

	my $brutal_txt = 'false';
	$brutal_txt = 'true' if $brutal;

	( $message = <<ENDMSG ) =~ s/^\t+//gm;


		  DEBUG connection
		  InstrumentRead called on Instrument No. $instrument_handle->{'debug_instr_index'}
		  Brutal:      $brutal_txt
		  Read length: $read_length

		  Enter device response (one line). Timeout prefix: 'T!', Error: 'E!'
ENDMSG

	print $message;

	$result = <STDIN>;
	chomp($result);

	if( $result =~ /^(T!).*/) {
		$result = substr($result, 2);
		Lab::Exception::Timeout->throw(
			error => "Timeout in " . __PACKAGE__ . "::InstrumentRead().\n",
			data => $result,
		);
	}
	elsif( $result =~ /^(E!).*/) {
		$result = substr($result, 2);
		Lab::Exception::Error->throw(
			error => "Error in " . __PACKAGE__ . "::InstrumentRead().\n",
		);
	}

	print "\n";
	return $result;
}




sub InstrumentWrite { # @_ = ( $instrument_handle, $args = { command, wait_status }
	my $self = shift;
	my $instrument_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $command = $args->{'command'} || undef;
	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();
	my $wait_status = $args->{'wait_status'} || $self->wait_status();

	my $message = "";
	my $user_return = "";

	my $brutal_txt = 'false';
	$brutal_txt = 'true' if $brutal;


	( $message = <<ENDMSG ) =~ s/^\t+//gm;


		  DEBUG connection
		  InstrumentWrite called on Instrument No. $instrument_handle->{'debug_instr_index'}
		  Command:     $command
		  Brutal:      $brutal_txt
		  Read length: $read_length
		  Wait status: $wait_status

		  Enter return state: (E)rror, just Return for success
ENDMSG
	print $message;

	$user_return = <STDIN>;
	chomp($user_return);

	if(!defined $command) {
		Lab::Exception::CorruptParameter->throw(
			error => "No command given to " . __PACKAGE__ . "::InstrumentWrite().\n",
		);
	}
	else {

		if ( $user_return eq 'E' ) {
			Lab::Exception::Error->throw(
				error => "Error in " . __PACKAGE__ . "::InstrumentWrite() while executing $command.",
			);
		}

		print "\n";
		return 1;
	}
}



sub InstrumentQuery { # @_ = ( $instrument_handle, $args = { command, read_length, wait_status, wait_query, brutal }
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
	my $status = undef;
	my $write_cnt = 0;
	my $read_cnt = undef;


    $write_cnt=$self->InstrumentWrite($args);

    print "\nwait_query: $wait_query usec\n";

    $result=$self->InstrumentRead($args);
    return $result;
}



sub _search_twin {
	my $self=shift;

	return undef;
}


=head1 NAME

Lab::Connection::DEBUG - debug connection


=head1 DESCRIPTION

This will be an interactive debug connection, which lets you enter responses to your skript.








1;

