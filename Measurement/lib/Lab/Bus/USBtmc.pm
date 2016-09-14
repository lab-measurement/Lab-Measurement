package Lab::Bus::USBtmc;
our $VERSION = '3.520';

# "sys/ioctl.ph" throws a warning about FORTIFY_SOURCE, but
# this alternate is (perhaps?) not present on all systems,
# so do a workaround
if ( !defined( eval('require "linux/ioctl.ph";') ) ) {
    require "sys/ioctl.ph";
}

# Created using h2ph
eval 'sub USBTMC_IOC_NR () {91;}' unless defined(&USBTMC_IOC_NR);
eval 'sub USBTMC_IOCTL_INDICATOR_PULSE () { &_IO( &USBTMC_IOC_NR, 1);}'
    unless defined(&USBTMC_IOCTL_INDICATOR_PULSE);
eval 'sub USBTMC_IOCTL_CLEAR () { &_IO( &USBTMC_IOC_NR, 2);}'
    unless defined(&USBTMC_IOCTL_CLEAR);
eval 'sub USBTMC_IOCTL_ABORT_BULK_OUT () { &_IO( &USBTMC_IOC_NR, 3);}'
    unless defined(&USBTMC_IOCTL_ABORT_BULK_OUT);
eval 'sub USBTMC_IOCTL_ABORT_BULK_IN () { &_IO( &USBTMC_IOC_NR, 4);}'
    unless defined(&USBTMC_IOCTL_ABORT_BULK_IN);
eval 'sub USBTMC_IOCTL_CLEAR_OUT_HALT () { &_IO( &USBTMC_IOC_NR, 6);}'
    unless defined(&USBTMC_IOCTL_CLEAR_OUT_HALT);
eval 'sub USBTMC_IOCTL_CLEAR_IN_HALT () { &_IO( &USBTMC_IOC_NR, 7);}'
    unless defined(&USBTMC_IOCTL_CLEAR_IN_HALT);

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;

our @ISA = ("Lab::Bus");

our %fields = (
    type        => 'USBtmc',
    brutal      => 0,
    read_length => 1000,       # bytes
    wait_query  => 10e-6,      # sec;
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    if ( $class eq __PACKAGE__ )
    {        # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            return $twin;    # ...and that's it.
        }
        else {
            $Lab::Bus::BusList{ $self->type() }->{'default'} = $self;
            weaken( $Lab::Bus::BusList{ $self->type() }->{'default'} );
        }
    }

    return $self;
}

sub connection_new {         # { tmc_address => primary address }
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $fn;
    my $usb_vendor;
    my $usb_product;
    my $usb_serial = '*';

    if ( defined $args->{'tmc_address'}
        && $args->{'tmc_address'} =~ /^[0-9]*$/ ) {
        $fn = "/dev/usbtmc" . $args->{'tmc_address'};
    }
    else {
        # want the vendor/product as strings, hex values
        if (
            defined $args->{'visa_name'}
            && ( $args->{'visa_name'}
                =~ /USB::0x([0-9A-Fa-f]{4})::0x([0-9A-Fa-f]{4})::[^:]*::INSTR/
            )
            ) {
            $usb_vendor  = $1;
            $usb_product = $2;
            $usb_serial  = $3;
        }
        else {
            $usb_vendor = $args->{'usb_vendor'};
            if ( $usb_vendor =~ /^\s*0x([\da-f]{4})/i ) {
                $usb_vendor = $1;
            }
            else {
                $usb_vendor = sprintf( '%04x', $usb_vendor );
            }
            $usb_product = $args->{'usb_product'};
            if ( $usb_product =~ /^\s*0x([\da-f]{4})/i ) {
                $usb_product = $1;
            }
            else {
                $usb_product = sprintf( '%04x', $usb_product );
            }
            $usb_serial = $args->{'usb_serial'};
        }
    }

    if ( !defined $fn && ( !defined $usb_vendor || !defined $usb_product ) ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No valid USB TMC address given to "
                . __PACKAGE__
                . "::connection_new()\n", );
    }

    # the /sys/class/ system isn't consistent, so use lsusb
    # select matching serial; if usb_serial = '*' select first match.

    if ( !defined($fn) ) {
        open( LSUSB_HANDLE,
            "/usr/bin/lsusb -d ${usb_vendor}:${usb_product} -v 2>/dev/null |"
            )
            || Lab::Exception::CorruptParameter->throw(
            error => "Error running lsusb to find USB TMC address given to "
                . __PACKAGE__
                . "::connection_new()\n", );
        my $got = 0;
        while (<LSUSB_HANDLE>) {
            if ( !$got && /^\s*iSerial\s+\d+\s+([^\s]+)/i ) {
                $got = 1 if $usb_serial eq $1 || $usb_serial eq '*';
                $self->{config}->{usb_serial} = $1;
                next;
            }
            if ( $got && /^\s*iInterface\s+(\d+)\s/i ) {
                $fn = "/dev/usbtmc$1";
                last;
            }
        }
        close(LSUSB_HANDLE);
    }

    if ( !defined $fn ) {
        Lab::Exception::CorruptParameter->throw(
            error => sprintf(
                      "Could not find specified device 0x%s/0x%s/%s in "
                    . __PACKAGE__
                    . "::connection_new()\n",
                $usb_vendor, $usb_product, $usb_serial
            ),
        );
    }

    my $connection_handle = undef;
    my $tmc_handle        = undef;

    open( $tmc_handle, "+<", $fn )
        || Lab::Exception::CorruptParameter->throw(
        error => $! . ": '$fn'\n" );
    binmode($tmc_handle);
    $tmc_handle->autoflush;

    $connection_handle
        = { valid => 1, type => "USBtmc", tmc_handle => $tmc_handle };
    return $connection_handle;
}

#TODO: Status, Errors?
sub connection_read
{    # @_ = ( $connection_handle, $args = { read_length, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();

    my $result   = undef;
    my $fragment = undef;

    my $tmc_handle = $connection_handle->{'tmc_handle'};
    sysread( $tmc_handle, $result, $read_length );

    # strip spaces and null byte
    $result =~ s/[\n\r\x00]*$//;

    #
    # timeout occured - throw exception, but include the received data
    # if the "Brutal" option is present, ignore the timeout and just return the data
    #
    # 	if( $ib_bits->{'ERR'} && $ib_bits->{'TIMO'} && !$brutal ) {
    # 		Lab::Exception::GPIBTimeout->throw(
    # 			error => sprintf("ibrd failed with a timeout, ibstatus %x\n", $ibstatus),
    # 			ibsta => $ibstatus,
    # 			ibsta_hash => $ib_bits,
    # 			data => $result
    # 		);
    # 	}
    # no timeout, regular return
    return $result;
}

#TODO: Undocumented
sub connection_query
{ # @_ = ( $connection_handle, $args = { command, read_length, wait_status, wait_query, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $wait_query = $args->{'wait_query'} || $self->wait_query();
    my $result = undef;

    $self->connection_write($args);

    sleep($wait_query); #<---ensures that asked data presented from the device

    $result = $self->connection_read($args);
    return $result;
}

#TODO: Error checking
sub connection_write
{    # @_ = ( $connection_handle, $args = { command, wait_status }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command = $args->{'command'} || undef;

    # 	my $brutal = $args->{'brutal'} || $self->brutal();
    # 	my $read_length = $args->{'read_length'} || $self->read_length();

    # 	my $result = undef;
    # 	my $raw = "";
    # 	my $ib_bits=undef;	# hash ref
    # 	my $ibstatus = undef;
    # 	my $ibsta_verbose = "";
    # 	my $decimal = 0;

    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }

    print { $connection_handle->{'tmc_handle'} } $command;

    #     $ibstatus=ibwrt($connection_handle->{'gpib_handle'}, $command, length($command));

    # 	$ib_bits=$self->ParseIbstatus($ibstatus);
    # 	foreach my $key ( keys %IbBits ) {
    # 		print "$key: $ib_bits{$key}\n";
    # 	}

    # Todo: better Error checking
    # 	if($ib_bits->{'ERR'}==1) {
    # 		if($ib_bits->{'TIMO'} == 1) {
    # 			Lab::Exception::GPIBTimeout->throw(
    # 				error => sprintf("Timeout in " . __PACKAGE__ . "::connection_write() while executing $command: ibwrite failed with status %x\n", $ibstatus) . Dumper($ib_bits),
    # 				ibsta => $ibstatus,
    # 				ibsta_hash => $ib_bits,
    # 			);
    # 		}
    # 		else {
    # 			Lab::Exception::GPIBError->throw(
    # 				error => sprintf("Error in " . __PACKAGE__ . "::connection_write() while executing $command: ibwrite failed with status %x\n", $ibstatus) . Dumper($ib_bits),
    # 				ibsta => $ibstatus,
    # 				ibsta_hash => $ib_bits,
    # 			);
    # 		}
    # 	}

    return 1;
}

sub connection_settermchar {    # @_ = ( $connection_handle, $termchar

    # 	my $self = shift;
    # 	my $connection_handle=shift;
    # 	my $termchar =shift; # string termination character as string
    #
    # 	my $ib_bits=undef;	# hash ref
    # 	my $ibstatus = undef;
    #
    #         my $h=$connection_handle->{'gpib_handle'};
    #
    #         my $arg=ord($termchar);
    #
    # 	$ibstatus=ibconfig($connection_handle->{'gpib_handle'}, 15, $arg);
    #
    # 	$ib_bits=$self->ParseIbstatus($ibstatus);
    #
    # 	if($ib_bits->{'ERR'}==1) {
    # 		Lab::Exception::GPIBError->throw(
    # 			error => sprintf("Error in " . __PACKAGE__ . "::connection_settermchar(): ibeos failed with status %x\n", $ibstatus) . Dumper($ib_bits),
    # 			ibsta => $ibstatus,
    # 			ibsta_hash => $ib_bits,
    # 		);
    # 	}

    return 1;
}

sub connection_enabletermchar {    # @_ = ( $connection_handle, 0/1 off/on

    # 	my $self = shift;
    # 	my $connection_handle=shift;
    # 	my $arg=shift;
    #
    # 	my $ib_bits=undef;	# hash ref
    # 	my $ibstatus = undef;
    #
    #     my $h=$connection_handle->{'tmc_handle'};
    #
    # 	$ibstatus=ibconfig($connection_handle->{'gpib_handle'}, 12, $arg);
    #
    # 	$ib_bits=$self->ParseIbstatus($ibstatus);
    #
    # 	if($ib_bits->{'ERR'}==1) {
    # 		Lab::Exception::GPIBError->throw(
    # 			error => sprintf("Error in " . __PACKAGE__ . "::connection_enabletermchar(): ibeos failed with status %x\n", $ibstatus) . Dumper($ib_bits),
    # 			ibsta => $ibstatus,
    # 			ibsta_hash => $ib_bits,
    # 		);
    # 	}

    return 1;
}

sub serial_poll {
    my $self              = shift;
    my $connection_handle = shift;
    my $sbyte             = undef;

    #
    # 	my $ibstatus = ibrsp($connection_handle->{'gpib_handle'}, $sbyte);
    #
    # 	my $ib_bits=$self->ParseIbstatus($ibstatus);
    #
    # 	if($ib_bits->{'ERR'}==1) {
    # 		Lab::Exception::GPIBError->throw(
    # 			error => sprintf("ibrsp (serial poll) failed with status %x\n", $ibstatus) . Dumper($ib_bits),
    # 			ibsta => $ibstatus,
    # 			ibsta_hash => $ib_bits,
    # 		);
    # 	}
    #
    return $sbyte;
}

sub connection_clear {
    my $self              = shift;
    my $connection_handle = shift;

    close( $connection_handle->{'tmc_handle'} );
}

sub connection_device_clear {
    my $self              = shift;
    my $connection_handle = shift;

    my $unused = 0;

    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_ABORT_BULK_OUT(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_ABORT_BULK_IN(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_CLEAR_OUT_HALT(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_CLEAR_IN_HALT(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'}, USBTMC_IOCTL_CLEAR(),
        $unused
    );
}

sub timeout {
    my $self              = shift;
    my $connection_handle = shift;
    my $timo              = shift;
    my $timoval           = undef;

    Lab::Exception::CorruptParameter->throw( error =>
            "The timeout value has to be a positive decimal number of seconds, ranging 0-1000.\n"
        )
        if ( $timo !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
        || $timo < 0
        || $timo > 1000 );

    if    ( $timo == 0 )    { $timoval = 0 }    # never time out
    if    ( $timo <= 1e-5 ) { $timoval = 1 }
    elsif ( $timo <= 3e-5 ) { $timoval = 2 }
    elsif ( $timo <= 1e-4 ) { $timoval = 3 }
    elsif ( $timo <= 3e-4 ) { $timoval = 4 }
    elsif ( $timo <= 1e-3 ) { $timoval = 5 }
    elsif ( $timo <= 3e-3 ) { $timoval = 6 }
    elsif ( $timo <= 1e-2 ) { $timoval = 7 }
    elsif ( $timo <= 3e-2 ) { $timoval = 8 }
    elsif ( $timo <= 1e-1 ) { $timoval = 9 }
    elsif ( $timo <= 3e-1 ) { $timoval = 10 }
    elsif ( $timo <= 1 )    { $timoval = 11 }
    elsif ( $timo <= 3 )    { $timoval = 12 }
    elsif ( $timo <= 10 )   { $timoval = 13 }
    elsif ( $timo <= 30 )   { $timoval = 14 }
    elsif ( $timo <= 100 )  { $timoval = 15 }
    elsif ( $timo <= 300 )  { $timoval = 16 }
    elsif ( $timo <= 1000 ) { $timoval = 17 }

    # 	my $ibstatus=ibtmo($connection_handle->{'gpib_handle'}, $timoval);
    #
    # 	my $ib_bits=$self->ParseIbstatus($ibstatus);
    #
    # 	if($ib_bits->{'ERR'}==1) {
    # 		Lab::Exception::GPIBError->throw(
    # 			error => sprintf("Error in " . __PACKAGE__ . "::timeout(): ibtmo failed with status %x\n", $ibstatus) . Dumper($ib_bits),
    # 			ibsta => $ibstatus,
    # 			ibsta_hash => $ib_bits,
    # 		);
    # 	}
    #    print "timeout(): not implemented!\n";
}

sub ParseIbstatus
{    # Ibstatus http://linux-gpib.sourceforge.net/doc_html/r634.html
    print "ParseIbstatus not supported\n";

    # 	my $self = shift;
    # 	my $ibstatus = shift;	# 16 Bit int
    # 	my @ibbits = ();
    #
    # 	if( $ibstatus !~ /[0-9]*/ || $ibstatus < 0 || $ibstatus > 0xFFFF ) {	# should be a 16 bit integer
    # 		Lab::Exception::CorruptParameter->throw( error => 'Lab::Bus::GPIB::VerboseIbstatus() got an invalid ibstatus.', InvalidParameter => $ibstatus );
    # 	}
    #
    # 	for (my $i=0; $i<16; $i++) {
    # 		$ibbits[$i] = 0x0001 & ($ibstatus >> $i);
    # 	}
    #
    # 	my %Ib = ();
    # 	( $Ib{'DCAS'}, $Ib{'DTAS'}, $Ib{'LACS'}, $Ib{'TACS'}, $Ib{'ATN'}, $Ib{'CIC'}, $Ib{'REM'}, $Ib{'LOK'}, $Ib{'CMPL'}, $Ib{'EVENT'}, $Ib{'SPOLL'}, $Ib{'RQS'}, $Ib{'SRQI'}, $Ib{'END'}, $Ib{'TIMO'}, $Ib{'ERR'} ) = @ibbits;
    #
    # 	return \%Ib;

} # return: ($ERR, $TIMO, $END, $SRQI, $RQS, $SPOLL, $EVENT, $CMPL, $LOK, $REM, $CIC, $ATN, $TACS, $LACS, $DTAS, $DCAS)

sub VerboseIbstatus {
    my $self             = shift;
    my $ibstatus         = shift;
    my $ibstatus_verbose = "";

    if ( ref( \$ibstatus ) =~ /SCALAR/ ) {
        $ibstatus = $self->ParseIbstatus($ibstatus);
    }
    elsif ( ref($ibstatus) !~ /HASH/ ) {
        Lab::Exception::CorruptParameter->throw(
            error =>
                'Lab::Bus::GPIB::VerboseIbstatus() got an invalid ibstatus.',
            InvalidParameter => $ibstatus
        );
    }

    while ( my ( $k, $v ) = each %$ibstatus ) {
        $ibstatus_verbose .= "$k: $v\n";
    }

    return $ibstatus_verbose;
}

#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
    my $self = shift;

    if ( !$self->ignore_twins() ) {
        for my $conn ( values %{ $Lab::Bus::BusList{ $self->type() } } ) {
            return $conn;    # if $conn->gpib_board() == $self->gpib_board();
        }
    }
    return undef;
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::LinuxGPIB - LinuxGPIB bus

=head1 SYNOPSIS

This is the USB TMC (Test & Measurement Class) bus class.

  my $tmc = new Lab::Bus::USBtmc({ });

or implicit through instrument and connection creation:

  my $instrument = new Lab::Instrument::HP34401A({
    connection_type => 'USBtmc',
    tmc_address=>1,
  }

=head1 DESCRIPTION

Driver for the interface provided by the usbtmc linux kernel module.

Obviously, this will work for Linux systems only. 
On Windows, please use L<Lab::Bus::VISA>. The interfaces are (errr, will be) identical.

Note: you don't need to explicitly handle bus objects. The Instruments will create them themselves, and existing bus will
be automagically reused.


=head1 CONSTRUCTOR

=head2 new

 my $bus = Lab::Bus::USBtmc({
  });

Return blessed $self, with @_ accessible through $self->config().



=head1 Thrown Exceptions

Lab::Bus::USBtmc throws

  Lab::Exception::TMCOpenFileError
  
  Lab::Exception::CorruptParameter

=head1 METHODS

=head2 connection_new

  $tmc->connection_new({ tmc_address => $addr });

Creates a new connection ("instrument handle") for this bus. The argument is a hash, whose contents 
depend on the bus type.

For TMC there are several ways to indicate which device is to be used 

if more than one is given, it is the first one that is used:
tmc_address => $addr         selects /dev/usbtmc$addr 
visa_name=> 'USB::0xVVVV::0xPPPP::SSSSSS::INSTR';
    where VVVV is the hex usb vendor number, PPPP is the hex usb product number, and SSSSSS is the serial
    number string.  If SSSSSS is '*', then the first device found that matches vendor and product will be
    used.
usb_vendor=>'0xVVVV' or 0xVVVV    vendor number
usb_product=>'0xPPPP' or 0xPPPP   product number
usb_serial=>'SSSSSS'  or '*'      serial number, or wildcard.

The usb_serial defaults to '*' if not specified. 

The handle is usually stored in an instrument object and given to connection_read, connection_write etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $tmc->connection_new({ usb_vendor => 0x0699, usb_product => 0x1234 });
  $result = $tmc->connection_read($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.

=head2 connection_write

  $tmc->connection_write( $InstrumentHandle, { Cmd => $Command } );

Sends $Command to the instrument specified by the handle.


=head2 connection_read

  $tmc->connection_read( $InstrumentHandle, { Cmd => $Command, ReadLength => $readlength, Brutal => 0/1 } );

Sends $Command to the instrument specified by the handle. Reads back a maximum of $readlength bytes. If a timeout or
an error occurs, Lab::Exception::GPIBError or Lab::Exception::Timeout are thrown, respectively. The Timeout object
carries the data received up to the timeout event, accessible through $Exception->Data().

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.

=head2 timeout

  $tmc->timeout( $connection_handle, $timeout );

Sets the timeout in seconds for tmc operations on the device/connection specified by $connection_handle.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $tmc_serial = $instrument->config(usb_serial);

Without arguments, returns a reference to the complete $self->config aka @_ of the constructor.

 $config = $bus->config();
 $tmc_serial = $bus->config()->{'usb_serial'};

=head1 CAVEATS/BUGS

Sysfs settings for timeout not supported, yet.

=head1 SEE ALSO

=over 4

=item 

L<Lab::Bus>

=item

and many more...

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2004-2006 Daniel Schröer <schroeer@cpan.org>, 
           2009-2010 Daniel Schröer, Andreas K. Hüttel (L<http://www.akhuettel.de/>) and David Kalok,
           2010      Matthias Völker <mvoelker@cpan.org>
           2011      Florian Olbrich, Andreas K. Hüttel
           2012      Hermann Kraus

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;

