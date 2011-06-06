#!/usr/bin/perl -w


use strict;

package Lab::Connection::VISA;
use strict;
use Lab::VISA;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connection;
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Connection");


our %fields = (
	default_rm => undef,
	type => 'VISA',
	brutal => 0,	# brutal as default?
	wait_status=>10, # usec;
	wait_query=>10, # usec;
	query_length=>300, # bytes
	query_long_length=>10240, #bytes
	read_length => 1000, # bytes
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->_construct(__PACKAGE__, \%fields);

	# search for twin in %Lab::Connection::ConnectionList. If there's none, place $self there and weaken it.
	if( $class eq __PACKAGE__ ) { # careful - do only if this is not a parent class constructor
		if($twin = $self->_search_twin()) {
			undef $self;
			return $twin;	# ...and that's it.
		}
		else {
			# no distinction between VISA resource managers yet - need more than one?
			$Lab::Connection::ConnectionList{$self->type()}->{'default'} = $self;
			weaken($Lab::Connection::ConnectionList{$self->type()}->{'default'});
		}
	}

	my ($status,$rm)=Lab::VISA::viOpenDefaultRM();
	if ($status != $Lab::VISA::VI_SUCCESS) { Lab::Exception::VISAError->throw( error => 'Cannot open resource manager: $status\n' ) }
	$self->default_rm($rm);

	return $self;
}


sub _check_resource_name { # @_ = ( $resource_name )
	my ($self,$resname) = (shift,shift);
	my $found = undef;

	# check for a valid resource name. let's start with GPIB INSTR (NI-VISA Programmer Reference Manual, P. 276)
	if(
		$resname =~ /^GPIB[0-9]*::[0-9]+(::[0-9]+)?(::INSTR)?$/		# GPIB INSTR
	) {
		return 1;
	}

	return 0;
}


sub InstrumentNew { # @_ = ({ resource_name => $resource_name })
	my $self = shift;
	my $args = undef;
	my $status = undef;
	my $instrument_handle=undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	my $resource_name = $args->{'resource_name'};

	Lab::Exception::CorruptParameter->throw( error => 'No resource name given to Lab::Connection::VISA::InstrumentNew().\n' ) if(!exists $args->{'resource_name'});
	Lab::Exception::CorruptParameter->throw( error => 'Invalid resource name given to Lab::Connection::VISA::InstrumentNew().\n' ) if(!$self->_check_resource_name($args->{'resource_name'}));

	( $status, $instrument_handle ) = Lab::VISA::viOpen( $self->default_rm(), $args->{'resource_name'}, $Lab::VISA::VI_NULL, $Lab::VISA::VI_NULL);
	if ($status != $Lab::VISA::VI_SUCCESS) { Lab::Exception::VISAError->throw( error => "Cannot open VISA instrument \"$resource_name\". Status: $status", status => $status ); };

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
	my $result_conv = undef;
	my $read_length = $args->{'read_length'} || $self->read_length();

	my $result = undef;
	my $status = undef;
	my $read_cnt = undef;



	($status,$result,$read_cnt)=Lab::VISA::viRead($instrument_handle,$read_length);

	if ( ! ( $status ==  $Lab::VISA::VI_SUCCESS || $status == $Lab::VISA::VI_SUCCESS_TERM_CHAR || $status == $Lab::VISA::VI_ERROR_TMO ) ) {
		Lab::Exception::VISAError->throw(
			error => "Error in Lab::Connection::VISA::InstrumentRead() while executing $command, Status $status",
			status => $status,
		);
	}
	elsif ( $status == $Lab::VISA::VI_ERROR_TMO && !$brutal ) {
		Lab::Exception::VISATimeout->throw(
			error => "Timeout in Lab::Connection::VISA::InstrumentRead() while executing $command\n",
			status => $status,
			command => $command,
			data => $result,
		);
	}


	return substr($result,0,$read_cnt);

# 	$Raw = $Result;
# 	#printf("Raw: %s\n", $Result);
# 	# check for number and convert. secure builtin way? maybe sprintf?
# 	if($Result =~ /^\s*([+-][0-9]*\.[0-9]*)([eE]([+-]?[0-9]*))?\s*\x00*/) {
# 		$Result = $1;
# 		$Result .= "e$3" if defined $3;
# 		$ResultConv = $1;
# 		$ResultConv *= 10 ** ( $3 )  if defined $3;
# 	}
# 	else {
# 		# not recognized - well upstream will hopefully be happy, anyway
# 		#croak('Non-numeric answer received');
# 		$Result = $Raw
# 	}

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

	my $result = undef;
	my $status = undef;
	my $write_cnt = 0;
	my $read_cnt = undef;

	if(!defined $command) {
		Lab::Exception::CorruptParameter->throw(
			error => "No command given to " . __PACKAGE__ . "::InstrumentWrite().\n",
		);
	}
	else {
        ($status, $write_cnt)=Lab::VISA::viWrite(
            $instrument_handle,
            $command,
            length($command)
        );

        usleep($wait_status);

		if ( $status != $Lab::VISA::VI_SUCCESS ) {
			Lab::Exception::VISAError->throw(
				error => "Error in Lab::Connection::VISA::InstrumentWrite() while executing $command, Status $status",
				status => $status,
			);
		}

		return $write_cnt;
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

    usleep($wait_query); #<---ensures that asked data presented from the device

    $result=$self->InstrumentRead($args);
    return $result;
}


#
# search and return an instance of the same type in %Lab::Connection::ConnectionList
#
sub _search_twin {
	my $self=shift;

	# Only one VISA connection for the moment, stored as "default"
	if(!$self->ignore_twins()) {
		if(defined $Lab::Connection::ConnectionList{$self->type()}->{'default'}) {
			return $Lab::Connection::ConnectionList{$self->type()}->{'default'};
		}
	}

	return undef;
}


=head1 NAME

Lab::Connection::VISA - VISA connection

=head1 SYNOPSIS

This is the VISA connection class for the NI VISA library.

  my $visa = new Lab::Connection::VISA();

or implicit through instrument creation:

  my $instrument = new Lab::Instrument::HP34401A({
    ConnectionType => 'VISA',
  }

=head1 DESCRIPTION

soon


=head1 CONSTRUCTOR

=head2 new

 my $connection = Lab::Connection::VISA({
  });

Return blessed $self, with @_ accessible through $self->config().

Options:
none


=head1 Thrown Exceptions

Lab::Connection::VISA throws

  Lab::Exception::VISAError
    fields:
    'status', the raw ibsta status byte received from linux-gpib

  Lab::Exception::VISATimeout
    fields:
    'data', this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
    ... and all the fields of Lab::Exception::GPIBError

=head1 METHODS

=head2 InstrumentNew

  $visa->InstrumentNew({ resource_name => "GPIB0::14::INSTR" });

Creates a new instrument handle for this connection.

The handle is usually stored in an instrument object and given to InstrumentRead, InstrumentWrite etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $visa->InstrumentNew({ resource_name => "GPIB0::14::INSTR" });
  $result = $visa->InstrumentRead($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.


=head2 InstrumentWrite

  $visa->InstrumentWrite( $InstrumentHandle, { command => $command, wait_status => $wait_status } );

Sends $command to the instrument specified by the handle, and waits $wait_status microseconds before evaluating the status.


=head2 InstrumentRead

  $visa->InstrumentRead( $InstrumentHandle, { command => $command, read_length => $read_length, brutal => 0/1 } );

Sends $Command to the instrument specified by the handle. Reads back a maximum of $readlength bytes. If a timeout or
an error occurs, Lab::Exception::VISAError or Lab::Exception::VISATimeout are thrown, respectively. The Timeout object
carries the data received up to the timeout event, accessible through $Exception->Data().

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.


=head2 InstrumentQuery

  $visa->InstrumentQuery( $InstrumentHandle, { command => $command, read_length => $read_length, wait_status => $wait_status, wait_query => $wait_query, brutal => 0/1 } );

Performs an InstrumentWrite followed by an InstrumentRead, each given the supplied parameters. Waits $wait_query microseconds
betweeen Write and Read.



=head1 CAVEATS/BUGS

View. Also, not a lot to be done here.

=head1 SEE ALSO

=over 4

=item L<Lab::Connection::GPIB>

=item L<Lab::Connection::MODBUS>

=item and many more...

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: Connection.pm 749 2011-02-15 12:55:20Z olbrich $

 Copyright 2004-2006 Daniel Schröer <schroeer@cpan.org>, 
           2009-2010 Daniel Schröer, Andreas K. Hüttel (L<http://www.akhuettel.de/>) and David Kalok,
         2010      Matthias Völker <mvoelker@cpan.org>
           2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut







1;

