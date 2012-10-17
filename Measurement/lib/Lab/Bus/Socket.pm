#!/usr/bin/perl -w


package Lab::Bus::Socket;
our $VERSION = '3.00';

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;
use Carp;
use IO::Socket;
use IO::Select;

our @ISA = ("Lab::Bus");


our %fields = (
	type => 'Socket',	
    PeerAddr => 'localhost', # Client for Write
    PeerPort => '6342',
    OpenServer =>0,
    LocalHost => 'localhost', # Server for Read
    LocalPort => '6342',
	Proto =>'tcp',
	Listen => 1,
    Reuse => 1,
    Timeout=> 60,
    EnableTermChar=>0,
    TermChar=>"\r\n",
	closechar =>"\004", # EOT
	brutal => 0,	# brutal as default?
	wait_query=>10e-6, # sec;
	read_length=>1000, # bytes
	query_length=>300, # bytes
	query_long_length=>10240, #bytes
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	# parameter parsing

	$self->PeerAddr($self->config('PeerAddr')) if defined $self->config('PeerAddr');
	$self->PeerPort($self->config('PeerPort')) if defined $self->config('PeerPort');
	$self->OpenServer($self->config('OpenServer')) if defined $self->config('OpenServer');
	$self->LocalHost($self->config('LocalHost')) if defined $self->config('LocalHost');
	$self->LocalPort($self->config('LocalPort')) if defined $self->config('LocalPort');
	$self->Proto($self->config('Proto')) if defined $self->config('Proto');
	$self->Timeout($self->config('Timeout')) if defined $self->config('Timeout');
	$self->EnableTermChar($self->config('EnableTermChar')) if defined $self->config('EnableTermChar');
	$self->TermChar($self->config('TermChar')) if defined $self->config('TermChar');
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

sub connection_new { # { gpib_address => primary address }
	my $self = shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }
	my $server = undef;
	my $client = undef;
	if ($args->{'OpenServer'}){
 		$server = new IO::Socket::INET (
                                  LocalHost => $args->{'LocalHost'},
                                  LocalPort => $args->{'LocalPort'},
                                  Proto => $args->{'Proto'},
                                  Listen => $args->{'Listen'},
                                  Reuse => $args->{'Reuse'},
                                 );
		die "Could not create socket server: $!\n" unless $server;
	}                             
 	$client = new IO::Socket::INET (
                                  PeerAddr => $args->{'PeerAddr'},
                                  PeerPort => $args->{'PeerPort'},
                                  Proto => $args->{'Proto'},
                                 );
	die "Could not create socket client: $!\n" unless $client;
	$client->autoflush(1);
	my $connection_handle = undef;
	$connection_handle =  { valid => 1, type => "SOCKET", socket_client_handle => $client, socket_server_handle => $server};#,   
	return $connection_handle;
};

sub connection_write { # @_ = ( $connection_handle, $args = { command, wait_status }
	my $self = shift;
	my $connection_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_}};
	my $command = $args->{'command'} || undef;
	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();
	if(!defined $command) {
		Lab::Exception::CorruptParameter->throw(
			error => "No command given to " . __PACKAGE__ . "::connection_write().\n",
		);
	}
	else {
		if ($self->{'EnableTermChar'}){$command.=$self->{'TermChar'}}
		my $sock=$connection_handle->{'socket_client_handle'};
		
		my @ready = IO::Select->new($sock)->can_write($self->{'Timeout'});
		if (@ready) {
			$sock->send($command) or die "$! sending command";
		}
		else {	
			Lab::Exception::Timeout->throw(
				error => "Socket write time out\n",
			);
    	}
	}
	return 1;
}

sub connection_read { # @_ = ( $connection_handle, $args = { read_length, brutal }
	my $self = shift;
	my $connection_handle=shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $sock=$connection_handle->{'socket_client_handle'} || undef;
	my $brutal = $args->{'brutal'} || $self->brutal();
	my $read_length = $args->{'read_length'} || $self->read_length();

	my $raw="";
	my $result = undef;
	

	if(!defined $sock) {
		Lab::Exception::CorruptParameter->throw(
			error => "No Socket given to " . __PACKAGE__ . "::connection_read().\n",
		);
	}
	else {
		my @ready = IO::Select->new($sock)->can_read($self->{'Timeout'});
		if (@ready) {
    		$sock->recv($result,$read_length) or die "$! reading";
		}
		else {	
			Lab::Exception::Timeout->throw(
				error => "Socket read time out\n",
			);
    	}
	};

	$raw = $result;
	#$result =~ /^\s*([+-][0-9]*\.[0-9]*)([eE]([+-]?[0-9]*))?\s*\x00*$/;
	#$result = $1;
	$result =~ s/[\n\r\x00]*$//;
	return $result;
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
	my $wait_query = $args->{'wait_query'} || $self->wait_query();
	my $result = undef;


    $self->connection_write($args);

    sleep($wait_query); #<---ensures that asked data presented from the device

    $result=$self->connection_read($args);
    return $result;
}
	

#sub connection_settermchar 
#{ 
#	my $self = shift;
#	my $connection_handle=shift;
#	my $args = undef;
#	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
#	else { $args={@_} }
#	my $termchar=$args->{'TermChar'};
#	return 1;
#}
#
#sub connection_enabletermchar 
#{ 
#	return 1;
#}

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
	