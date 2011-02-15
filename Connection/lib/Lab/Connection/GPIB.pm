#!/usr/bin/perl -w
# POD


use strict;

package Lab::Connection::GPIB;
use Lab::Connection;
use LinuxGpib ':all';
use Data::Dumper;
use Carp;

# setup this variable to add inherited functions later
our @ISA = ("Lab::Connection");

our $VERSION = sprintf("1.%04d", q$Revision: 713 $ =~ / (\d+) /);

our $WAIT_STATUS=10;#usec;
our $WAIT_QUERY=10;#usec;
our $QUERY_LENGTH=300; # bytes
our $QUERY_LONG_LENGTH=10240; #bytes
our $INS_DEBUG=0; # do we need additional output?



my %fields = (
	GPIB_Board	=> 0,
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $args = shift;
	my $self = $class->SUPER::new($args); # getting fields and _permitted from parent class
	warn("HIER\n");
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;

	print Dumper($self->Config);

	# one board - one connection - one connection object
	if ( exists $self->Config()->{'GPIB_Board'} ) {
		$self->GPIB_Board($self->Config()->{'GPIB_Board'});
		print "Using GPIB Board " . $self->GPIB_Board() . "\n";
	}


	# my $GPIB_Paddr;

	# using Primary Address only for the moment - no use for secondary here
	# $GPIB_Paddr = $self->Config()->{'GPIB_Paddr'} || 0;


	# open device
#	my $GPIBInstrument;
# 	if ($GPIB_Paddr) {
# 		# see: http://linux-gpib.sourceforge.net/doc_html/r1297.html
# 		# for timeout constant table: http://linux-gpib.sourceforge.net/doc_html/r2137.html	12 = 3 seconds
# 		# ibdev arguments: board index, primary address, secondary address, timeout (constants, see link), send_eoi, eos (end-of-string character)
# 		print "Opening device: " . $GPIB_Paddr . "\n";
# 		$GPIBInstrument = ibdev(0, $GPIB_Paddr, 0, 12, 1, 0);
# 		# Error if Descriptor is "-1"
# 		die("Error opening Instrument!\n") unless $GPIBInstrument >= 0;
# 		print "Descriptor is $GPIBInstrument \n";
# 	}

	warn Dumper($self);

	return $self;
}



sub InstrumentNew { # $self=Connection, { GPIB_Paddr => primary address }
	my $self = shift;
	# get arguments
	my %args = @_;
	print "New Instrument\n";
	my $GPIB_Paddr;

	# using Primary Address only for the moment - no use for secondary here
	if (exists $args{'GPIB_Paddr'}) {
		# create if missing
		$args{'GPIB_Paddr'}=0 unless (exists $args{'GPIB_Paddr'});
 		$GPIB_Paddr = $args{'GPIB_Paddr'};
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
sub InstrumentRead { # $self=Connection, \%InstrumentHandle, \%Options = { SCPI_cmd }
	my $self = shift;
	my $Instrument=shift;
	my $Options = shift;
	my $ScpiCommand = $Options->{'SCPI_cmd'} || undef;
	my $Result = undef;
	my $Raw = "";
	my $ResultConv = undef;
	my %IbBits=();

	my $ReadLength = $Options->{'Read_Length'} || 100;
	my $ibstatus = undef;
    my $read_cnt = 0;
	my $decimal = 0;

	if(!defined $ScpiCommand) {
		die("No command submitted\n");
	}
	else {
		$ibstatus=ibwrt($Instrument->{'GPIBHandle'}, $ScpiCommand, length($ScpiCommand));
		%IbBits=$self->ParseIbstatus($ibstatus);

		if($IbBits{'ERR'}==1) {
			croak(sprintf("InstrumentRead failed in ibwrt with ibstatus %x\n", $ibstatus) . "Options: \n" . Dumper($Options));
		}
		else {
			# 1000 characters maximum should be sufficient... ?
			$ibstatus = ibrd($Instrument->{'GPIBHandle'}, $Result, $ReadLength);
			%IbBits=$self->ParseIbstatus($ibstatus);

			if($IbBits{'ERR'}==1) {
				croak(sprintf("InstrumentRead failed in ibrd with ibstatus %x\n", $ibstatus) . "Options: \n" . Dumper($Options));
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
					# for now
					croak('Non-numeric answer received');
				}
			}
		}
	}


	# Todo: additional reads neccessary? (compare VISA)


# 	foreach my $key ( keys %IbBits ) {
# 		print "$key: $IbBits{$key}\n";
# 	}

	# Todo: better Error checking
	if($IbBits{'ERR'}==1) {
		croak(sprintf("InstrumentRead failed with ibstatus %x\n", $ibstatus) . "Options: \n" . Dumper($Options));
	}

	return $Result;
	#return $Result;
}


sub InstrumentWrite { # $self=Connection, \%InstrumentHandle, \%Options = { SCPI_cmd }
	my $self = shift;
	my $Instrument=shift;
	my $Options = shift;
	my $ScpiCommand = $Options->{'SCPI_cmd'} || undef;

	my $ibstatus = undef;

	if(!defined $ScpiCommand) {
		die("No command submitted\n");
	}
	else {
		$ibstatus=ibwrt($Instrument->{'GPIBHandle'}, $ScpiCommand, length($ScpiCommand));
	}

	my %IbBits=$self->ParseIbstatus($ibstatus);
# 	foreach my $key ( keys %IbBits ) {
# 		print "$key: $IbBits{$key}\n";
# 	}

	# Todo: better Error checking
	if($IbBits{'ERR'}==1) {
		croak(sprintf("InstrumentWrite failed with ibstatus %x\n", $ibstatus) . "Options: \n" . Dumper($Options));
	}

	return 1;
}


sub ParseIbstatus { # Ibstatus http://linux-gpib.sourceforge.net/doc_html/r634.html
	my $self = shift;
	my $ibstatus = shift;	# 16 Bit int
	my @ibbits = ();

	for (my $i=0; $i<16; $i++) {
		$ibbits[$i] = 0x0001 & ($ibstatus >> $i);
	}

	my %Ib = ();
	( $Ib{'DCAS'}, $Ib{'DTAS'}, $Ib{'LACS'}, $Ib{'TACS'}, $Ib{'ATN'}, $Ib{'CIC'}, $Ib{'REM'}, $Ib{'LOK'}, $Ib{'CMPL'}, $Ib{'EVENT'}, $Ib{'SPOLL'}, $Ib{'RQS'}, $Ib{'SRQI'}, $Ib{'END'}, $Ib{'TIMO'}, $Ib{'ERR'} ) = @ibbits;

	return %Ib;

} # return: ($ERR, $TIMO, $END, $SRQI, $RQS, $SPOLL, $EVENT, $CMPL, $LOK, $REM, $CIC, $ATN, $TACS, $LACS, $DTAS, $DCAS)



sub DESTROY {
        my $self = shift;
		print "Releasing GPIB board.\n";
		ibonl($self->GPIB_Board(),0);
        $self -> SUPER::DESTROY if $self -> can ("SUPER::DESTROY");
}


1;