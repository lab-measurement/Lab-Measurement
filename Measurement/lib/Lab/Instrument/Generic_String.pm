
package Lab::Instrument::Generic_String;

use strict;
use Scalar::Util qw(weaken);
use Lab::Instrument;
use Carp;
use Data::Dumper;


our @ISA = ("Lab::Instrument");

our %fields = (
	# SupportedConnections => [ 'GPIB', 'RS232' ],	# in principle RS232, too, but not implemented (yet)
	supported_connections => [ 'ALL' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
	},

	device_settings => {
	},

);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);	# sets $self->config
	$self->_construct(__PACKAGE__, \%fields); 	# this sets up all the object fields out of the inheritance tree.
												# also, it does generic connection setup.

	return $self;
}



#
# utility methods
#

#
# only the generic Write, Read and Query from the connection are passed through.
#

sub write {
	my $self=shift;
	my $command=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	$options->{'command'} = $command;
	
	return $self->connection()->Write($options);
}


sub read {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	return $self->connection()->Read($options);
}


sub query {
	my $self=shift;
	my $command=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	$options->{'command'} = $command;

	return $self->connection()->Query($options);
}

1;










=head1 NAME

Lab::Instrument::Generic_String - generic instrument driver for devices driven by command/string based protocols.

=head1 SYNOPSIS

Lab::Instrument::Generic_String will accept all connection types and try to write and read strings to/from them.
Usage:

  use Lab::Instrument::Generic_String;

  my $SCPI_GPIP = new Lab::Instrument::Generic_String({
    connection_type => 'VISA_GPIB',
    gpib_address => 14,
  }

  my $device_id = $SCPI_GPIB->query('*IDN?');
  $SCPI_GPIB->write('*CLR');


=head1 DESCRIPTION

The Lab::Instrument::Generic_String class implements a generic instrument that lets you talk directly to any device driven
by a supported command/string based protocol and connection, like SCPI.

It supports three methods (see below): write(), read() and query() which are directly passed through to the connection.

If you're using this regularly, please consider creating a driver for your device or implementing your needs in an existing one and
share your improvements.


=head1 CONSTRUCTOR

    my $device=new(
      connection_type => $conntype,
      ... connection parameters ...
    );

$conntype is the desired connection class as in Lab::Connection::<conntype>.

=head1 METHODS


=head2 read

    $result = $device->read( @options );

Fetches waiting data from the bus. The recognized options depend on the underlying bus/connection, check there.
Common options:

    $result = $device->read(
      read_length => 300,	# how many characters to read
      brutal => 1           # ingore timeout errors (no exception gets thrown)
    )

=head2 read

    $device->write( $command, @options );

Writes $command to the device as a string. The recognized options depend on the underlying bus/connection.

=head2 query

    $result = $device->query( $command, @options );

Writes $command to the device as a string and reads back the resulting data. The recognized options depend on the underlying bus/connection, check there.
Common options:

    $result = $device->query(
      'some command',
      read_length => 300,  # how many characters to read back
      wait_query => 10     # how long to wait for the device/bus before reading back the answer, in microseconds
      brutal => 1          # ingore timeout errors (no exception gets thrown)
    )

=head1 CAVEATS/BUGS

None known.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

Copyright 2011 Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
