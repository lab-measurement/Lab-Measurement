#!/usr/bin/perl -w


use strict;

package Lab::Connection::GPIB;
use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connection;
use LinuxGpib ':all';
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Connection");


our %fields = (
	gpib_address	=> 0,
	gpib_saddress => undef, # secondary address
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

	return $self;
}





=head1 NAME

Lab::Connection::GPIB - GPIB connection base

=head1 SYNOPSIS

This is the GPIB connection class for the GPIB library C<linux-gpib> (aka C<libgpib0> in the debian world).

  my $GPIB = new Lab::Connection::GPIB({ gpib_board => 0 });

or implicit through instrument creation:

  my $instrument = new Lab::Instrument::HP34401A({
    ConnectionType => 'GPIB',
    gpib_board => 0,
    GPIB_Paddress=>14,
  }

=head1 DESCRIPTION

See http://linux-gpib.sourceforge.net/.
This will work for Linux systems only. On Windows, please use C<Lab::Connection::VISA>. The interfaces are (errr, will be) identical.

Note: you don't need to explicitly handle connection objects. The Instruments will create them themselves, and existing connection will
be automagically reused.

In GPIB, instantiating two connection with identical parameter "gpib_board" will logically lead to the reuse of the first one.
To override this, use the parameter "ignore_twins".


=head1 CONSTRUCTOR

=head2 new

 my $connection = Lab::Connection::GPIB({
    gpib_board => $board_num
  });

Return blessed $self, with @_ accessible through $self->config().

Options:
C<gpib_board>: Index of board to use. Can be omitted, 0 is the default.


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

=head2 connection_new

  $GPIB->connection_new({ GPIB_Paddr => $paddr });

Creates a new instrument handle for this connection. The argument is a hash, which contents depend on the connection type.
For GPIB at least 'GPIB_Paddr' is needed.

The handle is usually stored in an instrument object and given to connection_read, connection_write etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $GPIB->connection_new({ GPIB_Paddr => 13 });
  $result = $GPIB->connection_read($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.


=head2 connection_write

  $GPIB->connection_write( $InstrumentHandle, { Cmd => $Command } );

Sends $Command to the instrument specified by the handle.


=head2 connection_read

  $GPIB->connection_read( $InstrumentHandle, { Cmd => $Command, ReadLength => $readlength, Brutal => 0/1 } );

Sends $Command to the instrument specified by the handle. Reads back a maximum of $readlength bytes. If a timeout or
an error occurs, Lab::Exception::GPIBError or Lab::Exception::GPIBTimeout are thrown, respectively. The Timeout object
carries the data received up to the timeout event, accessible through $Exception->Data().

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.


=head2 config

Provides unified access to the fields in initial @_ to all the cild classes.
E.g.

 $GPIB_PAddress=$instrument->config(GPIB_PAddress);

Without arguments, returns a reference to the complete $self->config aka @_ of the constructor.

 $config = $connection->config();
 $GPIB_PAddress = $connection->config()->{'GPIB_PAddress'};

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

