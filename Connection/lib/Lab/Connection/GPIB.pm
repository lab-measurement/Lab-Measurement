#!/usr/bin/perl -w
# POD


use strict;

package Lab::Connection::GPIB;
use strict;
use Scalar::Util qw(weaken);
use Lab::Connection;
use LinuxGpib ':all';
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Connection");

# the following will be handled through %fields soon
our $WAIT_STATUS=10;#usec;
our $WAIT_QUERY=10;#usec;
our $QUERY_LENGTH=300; # bytes
our $QUERY_LONG_LENGTH=10240; #bytes
our $INS_DEBUG=0; # do we need additional output?

our %fields = (
	GPIB_Board	=> 0,
	Brutal => 0,
	Type => 'GPIB',
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->ConstructMe(__PACKAGE__, \%fields);

	# one board - one connection - one connection object
	if ( exists $self->Config()->{'GPIB_Board'} ) {
		$self->GPIB_Board($self->Config()->{'GPIB_Board'}); 
	} # ... or the default

	# search for twin in %Lab::Connection::ConnectionList. If there's none, place $self there and weaken it.
	if( $class eq __PACKAGE__ ) { # careful - do only if this is not a parent class constructor
		if($twin = $self->_search_twin()) {
			warn "Equivalent connection twin found. Go on brother, leave me behind.\n";
			undef $self;
			return $twin;	# ...and that's it.
		}
		else {
			warn "I'm alone in this world.\n";
			$Lab::Connection::ConnectionList{$self->Type()}->{$self->GPIB_Board()} = $self;
			weaken($Lab::Connection::ConnectionList{$self->Type()}->{$self->GPIB_Board()});
		}
	}

	return $self;
}



sub InstrumentNew { # { GPIB_Paddress => primary address }
	(my $self, my $args) = (shift, shift);
	my $GPIB_Paddr;

	# using Primary Address only for the moment - no use for secondary here
	if (exists $args->{'GPIB_Paddress'}) {
		# create if missing
		$args->{'GPIB_Paddress'}=0 unless (exists $args->{'GPIB_Paddress'});
 		$GPIB_Paddr = $args->{'GPIB_Paddress'};
	}

	# open device
	my $GPIBInstrument;
	if ($GPIB_Paddr) {
		# see: http://linux-gpib.sourceforge.net/doc_html/r1297.html
		# for timeout constant table: http://linux-gpib.sourceforge.net/doc_html/r2137.html
		# ibdev arguments: board index, primary address, secondary address, timeout (constants, see link), send_eoi, eos (end-of-string character)
		print "Opening device: " . $GPIB_Paddr . "\n";
		$GPIBInstrument = ibdev(0, $GPIB_Paddr, 0, 12, 1, 0);

		# clear
		my $ibstatus = ibclr($GPIBInstrument);
		printf("Instrument cleared, ibstatus %x\n", $ibstatus);

		print "Descriptor is $GPIBInstrument \n";
	}
		
	my $Instrument=  { valid => 1, type => "GPIB", GPIBHandle => $GPIBInstrument };  
	return $Instrument;
}


#
# Todo: Evaluate $ibstatus: http://linux-gpib.sourceforge.net/doc_html/r634.html
#
sub InstrumentRead { # $self=Connection, \%InstrumentHandle, \%Options = { ReadLength, Cmd, Brutal }
	my $self = shift;
	my $Instrument=shift;
	my $Options = shift;
	my $Command = $Options->{'Cmd'} || undef;
	my $Brutal = $Options->{'Brutal'};
	my $Result = undef;
	my $Raw = "";
	my $ResultConv = undef;
	my $IbBits=undef;	# hash ref

	my $ReadLength = $Options->{'ReadLength'} || 1000; # 1000 characters maximum should be sufficient... ?
	my $ibstatus = undef;
	my $ibsta_verbose = "";
    my $read_cnt = 0;
	my $decimal = 0;

	if(defined $Command) {
		$ibstatus=ibwrt($Instrument->{'GPIBHandle'}, $Command, length($Command));
		$IbBits=$self->ParseIbstatus($ibstatus);

		if( $IbBits->{'ERR'} ) {
			Lab::Exception::GPIBError->throw( error => sprintf("ibwrt failed with ibstatus %x\n", $ibstatus), ibsta => $ibstatus, ibsta_hash => $IbBits );
		}
	}

	$ibstatus = ibrd($Instrument->{'GPIBHandle'}, $Result, $ReadLength);
	$IbBits=$self->ParseIbstatus($ibstatus);

	if( $IbBits->{'ERR'} && !$IbBits->{'TIMO'} ) {	# if the error is a timeout, we still evaluate the result and see what to do with the error later
		Lab::Exception::GPIBError->throw( error => sprintf("ibrd failed with ibstatus %x", $ibstatus), ibsta => $ibstatus, ibsta_hash => $IbBits );
	}
	else {
		$Raw = $Result;
		#printf("Raw: %s\n", $Result);
		# check for number and convert. secure builtin way? maybe sprintf?
		if($Result =~ /^\s*([+-][0-9]*\.[0-9]*)([eE]([+-]?[0-9]*))?\s*\x00*/) {
			$Result = $1;
			$Result .= "e$3" if defined $3;
			$ResultConv = $1;
			$ResultConv *= 10 ** ( $3 )  if defined $3;
		}
		else {
			# not recognized - well upstream will hopefully be happy, anyway
			#croak('Non-numeric answer received');
			$Result = $Raw
		}
	}


	# Todo: additional reads neccessary? (compare VISA)

	#
	# timeout occured - throw exception, but include the received data
	# if the "Brutal" option is present, ignore the timeout and just return the data
	#
	if( $IbBits->{'ERR'} && $IbBits->{'TIMO'} && !$Brutal ) {
		Lab::Exception::GPIBTimeout->throw( error => sprintf("ibrd failed with a timeout, ibstatus %x\n", $ibstatus), ibsta => $ibstatus, ibsta_hash => $IbBits, Data => $Result );
	}
	# no timeout, regular return
	return $Result;
}


sub InstrumentWrite { # $self=Connection, \%InstrumentHandle, \%Options = { Cmd }
	my $self = shift;
	my $Instrument=shift;
	my $Options = shift;
	my $Command = $Options->{'Cmd'} || undef;

	my $ibstatus = undef;

	if(!defined $Command) {
		die("No command submitted\n");
	}
	else {
		$ibstatus=ibwrt($Instrument->{'GPIBHandle'}, $Command, length($Command));
	}

	my $IbBits=$self->ParseIbstatus($ibstatus);
# 	foreach my $key ( keys %IbBits ) {
# 		print "$key: $IbBits{$key}\n";
# 	}

	# Todo: better Error checking
	if($IbBits->{'ERR'}==1) {
		croak(sprintf("InstrumentWrite failed with ibstatus %x\n", $ibstatus) . "Options: \n" . Dumper($Options));
	}

	return 1;
}


sub ParseIbstatus { # Ibstatus http://linux-gpib.sourceforge.net/doc_html/r634.html
	my $self = shift;
	my $ibstatus = shift;	# 16 Bit int
	my @ibbits = ();

	if( $ibstatus !~ /[0-9]*/ || $ibstatus < 0 || $ibstatus > 0xFFFF ) {	# should be a 16 bit integer
		Lab::Exception::CorruptParameter->throw( error => 'Lab::Connection::GPIB::VerboseIbstatus() got an invalid ibstatus.' , InvalidParameter => $ibstatus );
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
		Lab::Exception::CorruptParameter->throw( error => 'Lab::Connection::GPIB::VerboseIbstatus() got an invalid ibstatus.' , InvalidParameter => $ibstatus );
	}

	while( my ($k, $v) = each %$ibstatus ) {
        $ibstatus_verbose .= "$k: $v\n";
    }

	return $ibstatus_verbose;
}


#
# search and return an instance of the same type in %Lab::Connection::ConnectionList
#
sub _search_twin {
	my $self=shift;

	if(!$self->IgnoreTwins()) {
		for my $conn ( values %{$Lab::Connection::ConnectionList{$self->Type()}} ) {
			return $conn if $conn->GPIB_Board() == $self->GPIB_Board();
		}
	}
	return undef;
}


=head1 NAME

Lab::Connection::GPIB - GPIB connection base

=head1 SYNOPSIS

This is the GPIB connection class for the GPIB library C<linux-gpib> (aka C<libgpib0> in the debian world).

  my $GPIB = new Lab::Connection::GPIB({ GPIB_Board => 0 });

or implicit through instrument creation:

  my $instrument = new Lab::Instrument::HP34401A({
    ConnectionType => 'GPIB',
    GPIB_Board => 0,
    GPIB_Paddress=>14,
  }

=head1 DESCRIPTION

See http://linux-gpib.sourceforge.net/.
This will work for Linux systems only. On Windows, please use C<Lab::Connection::VISA>. The interfaces are (errr, will be) identical.

Note: you don't need to explicitly handle connection objects. The Instruments will create them themselves, and existing connection will
be automagically reused.

In GPIB, instantiating two connection with identical parameter "GPIB_Board" will logically lead to the reuse of the first one.
To override this, use the parameter "IgnoreTwins".


=head1 CONSTRUCTOR

=head2 new

 my $connection = Lab::Connection::GPIB({
    GPIB_Board => $board_num
  });

Return blessed $self, with @_ accessible through $self->Config().

Options:
C<GPIB_Board>: Index of board to use. Can be omitted, 0 is the default.


=head1 Thrown Exceptions

Lab::Connection::GPIB throws

  Lab::Exception::GPIBError
    fields:
    'ibsta', the raw ibsta status byte received from linux-gpib
    'ibsta_hash', the ibsta bit values in a named, easy-to-read hash ( 'DCAS' => $val, 'DTAS' => $val, ... ). Use Lab::Connection::GPIB::VerboseIbstatus() to get a nice string representation

  Lab::Exception::GPIBTimeout
    fields:
    'Data', this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
    ... and all the fields of Lab::Exception::GPIBError

=head1 METHODS

=head2 InstrumentNew

  $GPIB->InstrumentNew({ GPIB_Paddr => $paddr });

Creates a new instrument handle for this connection. The argument is a hash, which contents depend on the connection type.
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


=head2 Config

Provides unified access to the fields in initial @_ to all the cild classes.
E.g.

 $GPIB_PAddress=$instrument->Config(GPIB_PAddress);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_PAddress = $connection->Config()->{'GPIB_PAddress'};

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

