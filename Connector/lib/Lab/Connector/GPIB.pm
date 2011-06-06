#!/usr/bin/perl -w


use strict;

package Lab::Connector::GPIB;
use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connector;
use LinuxGpib ':all';
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Connector");


our %fields = (
	gpib_board	=> 0,
	type => 'GPIB',
	brutal => 0,	# brutal as default?
	wait_status=>0, # usec;
	wait_query=>10, # usec;
	read_length=>1000, # bytes
	query_length=>300, # bytes
	query_long_length=>10240, #bytes
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->_construct(__PACKAGE__, \%fields);

	# one board - one connector - one connector object
	if ( exists $self->config()->{'gpib_board'} ) {
		$self->gpib_board($self->config()->{'gpib_board'}); 
	} # ... or the default

	# search for twin in %Lab::Connector::ConnectorList. If there's none, place $self there and weaken it.
	if( $class eq __PACKAGE__ ) { # careful - do only if this is not a parent class constructor
		if($twin = $self->_search_twin()) {
			undef $self;
			return $twin;	# ...and that's it.
		}
		else {
			$Lab::Connector::ConnectorList{$self->type()}->{$self->gpib_board()} = $self;
			weaken($Lab::Connector::ConnectorList{$self->type()}->{$self->gpib_board()});
		}
	}

	return $self;
}



sub InstrumentNew { # { gpib_address => primary address }
	my $self = shift;
	my $args = undef;
	if (ref $_[0] eq 'HASH') { $args=shift } # try to be flexible about options as hash/hashref
	else { $args={@_} }

	if(!defined $args->{'gpib_address'} || $args->{'gpib_address'} !~ /^[0-9]*$/ ) {
		Lab::Exception::CorruptParameter->throw (
			error => "No valid gpib address given to " . __PACKAGE__ . "::InstrumentNew()\n" . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
		);
	}

	my $gpib_address = $args->{'gpib_address'};
	my $instrument_handle = undef;
	my $gpib_handle = undef;

	# open device
	# see: http://linux-gpib.sourceforge.net/doc_html/r1297.html
	# for timeout constant table: http://linux-gpib.sourceforge.net/doc_html/r2137.html
	# ibdev arguments: board index, primary address, secondary address, timeout (constants, see link), send_eoi, eos (end-of-string character)
	print "Opening device: " . $gpib_address . "\n";
	$gpib_handle = ibdev(0, $gpib_address, 0, 12, 1, 0);

	# clear
	#my $ibstatus = ibclr($GPIBInstrument);
	#printf("Instrument cleared, ibstatus %x\n", $ibstatus);
		
	$instrument_handle =  { valid => 1, type => "GPIB", gpib_handle => $gpib_handle };  
	return $instrument_handle;
}


#
# Todo: Evaluate $ibstatus: http://linux-gpib.sourceforge.net/doc_html/r634.html
#
sub InstrumentRead { # @_ = ( $instrument_handle, $args = { read_length, brutal }
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
	my $raw = "";
	my $ib_bits=undef;	# hash ref
	my $ibstatus = undef;
	my $ibsta_verbose = "";
	my $decimal = 0;

	$ibstatus = ibrd($instrument_handle->{'gpib_handle'}, $result, $read_length);
	$ib_bits=$self->ParseIbstatus($ibstatus);

	if( $ib_bits->{'ERR'} && !$ib_bits->{'TIMO'} ) {	# if the error is a timeout, we still evaluate the result and see what to do with the error later
		Lab::Exception::GPIBError->throw(
			error => sprintf("ibrd failed with ibstatus %x\n", $ibstatus) . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
			ibsta => $ibstatus,
			ibsta_hash => $ib_bits,
		);
	}

	# strip spaces and null byte
	# note to self: find a way to access the ibcnt variable through the perl binding to use
	# $result = substr($result, 0, $ibcnt)
	$raw = $result;
	$result =~ /^\s*([+-][0-9]*\.[0-9]*)([eE]([+-]?[0-9]*))?\s*\x00*$/;
	$result = $1;

	#
	# timeout occured - throw exception, but include the received data
	# if the "Brutal" option is present, ignore the timeout and just return the data
	#
	if( $ib_bits->{'ERR'} && $ib_bits->{'TIMO'} && !$brutal ) {
		Lab::Exception::GPIBTimeout->throw(
			error => sprintf("ibrd failed with a timeout, ibstatus %x\n", $ibstatus) . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
			ibsta => $ibstatus,
			ibsta_hash => $ib_bits,
			data => $result
		);
	}
	# no timeout, regular return
	return $result;
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


    $self->InstrumentWrite($args);

    usleep($wait_query); #<---ensures that asked data presented from the device

    $result=$self->InstrumentRead($args);
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

	my $result = undef;
	my $raw = "";
	my $ib_bits=undef;	# hash ref
	my $ibstatus = undef;
	my $ibsta_verbose = "";
	my $decimal = 0;


	if(!defined $command) {
		Lab::Exception::CorruptParameter->throw(
			error => "No command given to " . __PACKAGE__ . "::InstrumentWrite().\n" . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
		);
	}
	else {
		$ibstatus=ibwrt($instrument_handle->{'gpib_handle'}, $command, length($command));
        usleep($wait_status);
	}

	$ib_bits=$self->ParseIbstatus($ibstatus);
# 	foreach my $key ( keys %IbBits ) {
# 		print "$key: $ib_bits{$key}\n";
# 	}

	# Todo: better Error checking
	if($ib_bits->{'ERR'}==1) {
		if($ib_bits->{'TIMO'} == 1) {
			Lab::Exception::GPIBTimeout->throw(
				error => sprintf("Timeout in " . __PACKAGE__ . "::InstrumentWrite() while executing $command: ibwrite failed with status %x\n", $ibstatus) . Dumper($ib_bits) . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
				ibsta => $ibstatus,
				ibsta_hash => $ib_bits,
			);
		}
		else {
			Lab::Exception::GPIBError->throw(
				error => sprintf("Error in " . __PACKAGE__ . "::InstrumentWrite() while executing $command: ibwrite failed with status %x\n", $ibstatus) . Dumper($ib_bits) . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__),
				ibsta => $ibstatus,
				ibsta_hash => $ib_bits,
			);
		}
	}

	return 1;
}


#
# calls ibclear() on the instrument - how to do on VISA?
#
sub InstrumentClear {
	my $self = shift;
	my $instrument_handle=shift;

	ibclr($instrument_handle->{'gpib_handle'});
}


sub ParseIbstatus { # Ibstatus http://linux-gpib.sourceforge.net/doc_html/r634.html
	my $self = shift;
	my $ibstatus = shift;	# 16 Bit int
	my @ibbits = ();

	if( $ibstatus !~ /[0-9]*/ || $ibstatus < 0 || $ibstatus > 0xFFFF ) {	# should be a 16 bit integer
		Lab::Exception::CorruptParameter->throw( error => 'Lab::Connector::GPIB::VerboseIbstatus() got an invalid ibstatus.'  . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__), InvalidParameter => $ibstatus );
	}

	for (my $i=0; $i<16; $i++) {
		$ibbits[$i] = 0x0001 & ($ibstatus >> $i);
	}

	my %Ib = ();
	( $Ib{'DCAS'}, $Ib{'DTAS'}, $Ib{'LACS'}, $Ib{'TACS'}, $Ib{'ATN'}, $Ib{'CIC'}, $Ib{'REM'}, $Ib{'LOK'}, $Ib{'CMPL'}, $Ib{'EVENT'}, $Ib{'SPOLL'}, $Ib{'RQS'}, $Ib{'SRQI'}, $Ib{'END'}, $Ib{'TIMO'}, $Ib{'ERR'} ) = @ibbits;

	return \%Ib;

} # return: ($ERR, $TIMO, $END, $SRQI, $RQS, $SPOLL, $EVENT, $CMPL, $LOK, $REM, $CIC, $ATN, $TACS, $LACS, $DTAS, $DCAS)

sub VerboseIbstatus {
	my $self = shift;
	my $ibstatus = shift;
	my $ibstatus_verbose = "";

	if(ref(\$ibstatus) =~ /SCALAR/) {
		$ibstatus = $self->ParseIbstatus($ibstatus);
	}
	elsif(ref($ibstatus) !~ /HASH/) {
		Lab::Exception::CorruptParameter->throw( error => 'Lab::Connector::GPIB::VerboseIbstatus() got an invalid ibstatus.'  . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__), InvalidParameter => $ibstatus );
	}

	while( my ($k, $v) = each %$ibstatus ) {
        $ibstatus_verbose .= "$k: $v\n";
    }

	return $ibstatus_verbose;
}


#
# search and return an instance of the same type in %Lab::Connector::ConnectorList
#
sub _search_twin {
	my $self=shift;

	if(!$self->ignore_twins()) {
		for my $conn ( values %{$Lab::Connector::ConnectorList{$self->type()}} ) {
			return $conn if $conn->gpib_board() == $self->gpib_board();
		}
	}
	return undef;
}


=head1 NAME

Lab::Connector::GPIB - GPIB connector base

=head1 SYNOPSIS

This is the GPIB connector class for the GPIB library C<linux-gpib> (aka C<libgpib0> in the debian world).

  my $GPIB = new Lab::Connector::GPIB({ gpib_board => 0 });

or implicit through instrument creation:

  my $instrument = new Lab::Instrument::HP34401A({
    ConnectorType => 'GPIB',
    gpib_board => 0,
    GPIB_Paddress=>14,
  }

=head1 DESCRIPTION

See http://linux-gpib.sourceforge.net/.
This will work for Linux systems only. On Windows, please use C<Lab::Connector::VISA>. The interfaces are (errr, will be) identical.

Note: you don't need to explicitly handle connector objects. The Instruments will create them themselves, and existing connector will
be automagically reused.

In GPIB, instantiating two connector with identical parameter "gpib_board" will logically lead to the reuse of the first one.
To override this, use the parameter "ignore_twins".


=head1 CONSTRUCTOR

=head2 new

 my $connector = Lab::Connector::GPIB({
    gpib_board => $board_num
  });

Return blessed $self, with @_ accessible through $self->config().

Options:
C<gpib_board>: Index of board to use. Can be omitted, 0 is the default.


=head1 Thrown Exceptions

Lab::Connector::GPIB throws

  Lab::Exception::GPIBError
    fields:
    'ibsta', the raw ibsta status byte received from linux-gpib
    'ibsta_hash', the ibsta bit values in a named, easy-to-read hash ( 'DCAS' => $val, 'DTAS' => $val, ... ). Use Lab::Connector::GPIB::VerboseIbstatus() to get a nice string representation

  Lab::Exception::GPIBTimeout
    fields:
    'Data', this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
    ... and all the fields of Lab::Exception::GPIBError

=head1 METHODS

=head2 InstrumentNew

  $GPIB->InstrumentNew({ GPIB_Paddr => $paddr });

Creates a new instrument handle for this connector. The argument is a hash, which contents depend on the connector type.
For GPIB at least 'GPIB_Paddr' is needed.

The handle is usually stored in an instrument object and given to InstrumentRead, InstrumentWrite etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $GPIB->InstrumentNew({ GPIB_Paddr => 13 });
  $result = $GPIB->InstrumentRead($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.


=head2 InstrumentWrite

  $GPIB->InstrumentWrite( $InstrumentHandle, { Cmd => $Command } );

Sends $Command to the instrument specified by the handle.


=head2 InstrumentRead

  $GPIB->InstrumentRead( $InstrumentHandle, { Cmd => $Command, ReadLength => $readlength, Brutal => 0/1 } );

Sends $Command to the instrument specified by the handle. Reads back a maximum of $readlength bytes. If a timeout or
an error occurs, Lab::Exception::GPIBError or Lab::Exception::GPIBTimeout are thrown, respectively. The Timeout object
carries the data received up to the timeout event, accessible through $Exception->Data().

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.


=head2 config

Provides unified access to the fields in initial @_ to all the cild classes.
E.g.

 $GPIB_PAddress=$instrument->config(GPIB_PAddress);

Without arguments, returns a reference to the complete $self->config aka @_ of the constructor.

 $config = $connector->config();
 $GPIB_PAddress = $connector->config()->{'GPIB_PAddress'};

=head1 CAVEATS/BUGS

View. Also, not a lot to be done here.

=head1 SEE ALSO

=over 4

=item L<Lab::Connector::GPIB>

=item L<Lab::Connector::MODBUS>

=item and many more...

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: Connector.pm 749 2011-02-15 12:55:20Z olbrich $

 Copyright 2004-2006 Daniel Schröer <schroeer@cpan.org>, 
           2009-2010 Daniel Schröer, Andreas K. Hüttel (L<http://www.akhuettel.de/>) and David Kalok,
         2010      Matthias Völker <mvoelker@cpan.org>
           2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut







1;

