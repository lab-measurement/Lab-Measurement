#!/usr/bin/perl -w
# POD

#$Id$

package Lab::Instrument;

use strict;

use Lab::Exception;
use Lab::Connection;
use Carp;
use Data::Dumper;

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function

# setup this variable to add inherited functions later
our @ISA = ();

our $AUTOLOAD;

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);


our %fields = (
	connection => undef,
	connection_type => "GPIB", # default
	supported_connections => [ ],
	config => {},
	instrument_handle => undef,
	wait_status => 10, # usec
	wait_query => 100, # usec
	query_length => 300, # bytes
	query_long_length => 10240, # bytes
	ins_debug => 0, # do we need additional output?
);



sub new { 
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $config = undef;
	if (ref $_[0] eq 'HASH') { $config=shift }
	else { $config={@_} }

	my $self={};
	bless ($self, $class);

	$self->_construct(__PACKAGE__, \%fields);

	$self->config($config);

	return $self;
}

#
# Call this in inheriting class's constructors to conveniently initialize the %fields object data.
#
sub _construct {	# _construct(__PACKAGE__);
	(my $self, my $package, my $fields) = (shift, shift, shift);
	my $class = ref($self);

	foreach my $element (keys %{$fields}) {
		$self->{_permitted}->{$element} = $fields->{$element};
	}
	@{$self}{keys %{$fields}} = values %{$fields};

	#
	# Check the connection data OR the connection object in $self->config(), but only if 
	# _construct() has been called from the instantiated class (and not from somewhere up the heritance hierarchy)
	# That's because child classes can add new entrys to $self->supported_connections(), so delay checking to the top class.
	#
	if( $class eq $package ) {
		$self->_setconnection();
	}
}


sub _checkconfig {
	my $self=shift;
	my $config = $self->config();

	return 1;
}

sub _checkconnection { # Connection object or ConnType string
	my $self=shift;
	my $connection=shift || "";
	my $conn_type = "";

	$conn_type = ( split( '::',  ref($connection) || $connection ))[-1];

 	if (defined $conn_type && 1 != grep( /^$conn_type$/, @{$self->supported_connections()} )) {
 		return 0;
 	}
	else {
		return 1;
	}
}

#
# Method to handle connection creation generically. This is called by _construct().
# If the following (rather simple code) doesn't suit your child class, or your need to
# introduce more thorough parameter checking and/or conversion, overwrite it - _construct()
# calls it only if it is called by the topmost class in the inheritance hierarchy itself.
#
sub _setconnection { # $self->setconnection() create new or use existing connection
	my $self=shift;
	# check the configuration hash for a valid connection object or connection type, and set the connection
	if( defined($self->config('connection')) ) {
		if($self->_checkconnection($self->config('connection')) ) {
			$self->connection($self->config('connection'));
		}
		else { croak('Given Connection not supported'); }
	}
	else {
		my $connection_type = $self->config('connection_type') || $self->connection_type();
		warn "No connection and no connection type given - trying to create default connection $connection_type.\n" if !$self->config('connection_type');
		if($self->_checkconnection($self->config('connection_type'))) {
			# yep - pass all the parameters on to the connection, it will take the ones it needs.
			# This way connection setup can be handled generically. Conflicting parameter names? Let's try it.
			warn ("new Lab::Connection::${connection_type}(\$self->config())");
			$self->connection(eval("new Lab::Connection::${connection_type}(\$self->config())")) || croak('Failed to create connection');
		}
		else { croak('Given Connection Type not supported'); }
	}

	# again, pass it all.
	$self->instrument_handle( $self->connection()->InstrumentNew( $self->config() ));
}



sub Clear {
	my $self=shift;
	
	return $self->connection()->InstrumentClear($self->instrument_handle()) if ($self->connection()->can('Clear'));
	# error message
	die "Clear function is not implemented in the connection ".ref($self->connection())."\n";
}


sub Write {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }
	
	return $self->connection()->InstrumentWrite($self->instrument_handle(), $options);
}




sub Read {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	return $self->connection()->InstrumentRead($self->instrument_handle(), $options);
}



sub BrutalRead {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }
	$options->{'Brutal'} = 1;
	
	return $self->Read($options);
}



sub Query {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	my $wait_query=$options->{'wait_query'} || $self->wait_query();

	$self->Write( $options );
	usleep($wait_query);
	return $self->Read($options);
}



sub LongQuery {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	$options->{read_length} = 10240;
	return $self->Query($options);
}


sub BrutalQuery {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	$options->{brutal} = 1;
	return $self->Query($options);
}






#
# config gets it's own accessor - convenient access like $self->config('GPIB_Paddress') instead of $self->config()->{'GPIB_Paddress'}
# with a hashref as argument, set $self->{'config'} to the given hashref.
# without an argument it returns a reference to $self->config (just like AUTOLOAD would)
#
sub config {	# $value = self->config($key);
	(my $self, my $key) = (shift, shift);

	if(!defined $key) {
		return $self->{'config'};
	}
	elsif(ref($key) =~ /HASH/) {
		return $self->{'config'} = $key;
	}
	else {
		return $self->{'config'}->{$key};
	}
}

sub AUTOLOAD {

	my $self = shift;
	my $type = ref($self) or croak "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://; # strip fully qualified portion

	unless (exists $self->{_permitted}->{$name} ) {
		Lab::Exception::Error->throw( error => "AUTOLOAD in " . __PACKAGE__ . " couldn't access field '${name}'.\n" );
	}

	if (@_) {
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}
}

# needed so AUTOLOAD doesn't try to call DESTROY on cleanup and prevent the inherited DESTROY
sub DESTROY {
        my $self = shift;
	#$self->connection()->DESTROY();
        $self -> SUPER::DESTROY if $self -> can ("SUPER::DESTROY");
}


# sub WriteConfig {
#         my $self = shift;
# 
#         my %config = @_;
# 	%config = %{$_[0]} if (ref($_[0]));
# 
# 	my $command = "";
# 	# function characters init
# 	my $inCommand = "";
# 	my $betweenCmdAndData = "";
# 	my $postData = "";
# 	# config data
# 	if (exists $self->{'CommandRules'}) {
# 		# write stating value by default to command
# 		$command = $self->{'CommandRules'}->{'preCommand'} 
# 			if (exists $self->{'CommandRules'}->{'preCommand'});
# 		$inCommand = $self->{'CommandRules'}->{'inCommand'} 
# 			if (exists $self->{'CommandRules'}->{'inCommand'});
# 		$betweenCmdAndData = $self->{'CommandRules'}->{'betweenCmdAndData'} 
# 			if (exists $self->{'CommandRules'}->{'betweenCmdAndData'});
# 		$postData = $self->{'CommandRules'}->{'postData'} 
# 			if (exists $self->{'CommandRules'}->{'postData'});
# 	}
# 	# get command if sub call from itself
# 	$command = $_[1] if (ref($_[0])); 
# 
#         # build up commands buffer
#         foreach my $key (keys %config) {
# 		my $value = $config{$key};
# 
# 		# reference again?
# 		if (ref($value)) {
# 			$self->WriteConfig($value,$command.$key.$inCommand);
# 		} else {
# 			# end of search
# 			$self->Write($command.$key.$betweenCmdAndData.$value.$postData);
# 		}
# 	}
# 
# }


1;

=head1 NAME

Lab::Instrument - General instrument package

=head1 SYNOPSIS

This is meant to be used as a base class for inheriting instruments only.
Every inheriting class' constructors should start as follows:

  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    $self->_construct(__PACKAGE__);  # check for supported connections, initialize fields etc.
    ...
  }

=head1 DESCRIPTION

C<Lab::Instrument> is the base class for Instruments. It doesn't do anything by itself, but
is meant to be inherited in specific instrument drivers.
It provides general C<Read>, C<Write> and C<Query> methods and basic connection handling (internal, C<_set_connection>, C<_check_connection>).

The connection object can be obtained by calling C<connection()>.

Also, fields common to all instrument classes are created and set to default values where applicable:

  connection => undef,
  ConnectionType => "",
  SupportedConnections => [ ],
  Config => undef,
  InstrumentHandle => undef,
  WaitQuery => 100,

Opposing prior versions, it can't be used directly by the programmer anymore. To work with an instrument
that doesn't have its own perl class, probably a Lab::Instrument::Generic driver or similar will be introduced.

=head1 CONSTRUCTOR

=head2 new

This blesses $self (don't do it in an inheriting class!), initializes the basic "fields" to be accessed
via AUTOLOAD and puts the configuration hash in $self->Config to be accessed in methods and inherited
classes.

Arguments: just the configuration hash passed along from child classes' constructor.

=head1 METHODS

=head2 Write

 $instrument->Write($command);
 
Sends the command C<$command> to the instrument.

=head2 Read

 $result=$instrument->Read({ ReadLength => <max length>, Cmd => <command>, Brutal => <1/0>);

Reads a result of C<ReadLength> from the instrument and returns it.
Returns an exception on error.

If the parameter C<Brutal> is set, a timeout in the connection will not result in an Exception thrown,
but will return the data obtained until the timeout without further comment.
Be aware that this data is also contained in the the timeout exception object (see C<Lab::Exception>).

Generally, all options are passed to the connection, so additional options may be supported based on the connection.

=head2 BrutalRead

Equivalent to

 $result=$instrument->Read({ Brutal =>  1 });

=head2 Query

 $result=$instrument->Query({ Cmd => $command, WaitQuery => $wait_query, ReadLength => $max length, WaitStatus => $wait_status);

Sends the command C<$command> to the instrument and reads a result from the
instrument and returns it. The length of the read buffer is set to C<ReadLength> or to the
default set in the connection.

Waits for C<WaitQuery> microseconds before trying to read the answer.

WaitStatus not implemented yet - needed?

The default value of 'wait_query' can be overwritten
by defining the corresponding object key.

Generally, all options are passed to the connection, so additional options may be supported based on the connection.

=head2 LongQuery

Equivalent to

 $result=$instrument->Query({ Cmd => $command, ReadLength => 10240, ... });

=head2 BrutalQuery

Equivalent to

 $result=$instrument->Query({ Cmd => $command, Brutal=>1, ... });

This won't complain about a timeout error and quietly return the data it received until abort.
By the way: you can get to this data without the 'Brutal' option through the timeout exception object if you catch it!

=head2 Clear

 $instrument->Clear();

Sends a clear command to the instrument if implemented for the interface.

=head2 Connection

 $connection=$instrument->connection();

Returns the connection object used by this instrument. It can then be passed on to another object on the
same connection, or be used to change connection parameters.

=head2 WriteConfig

 # this is not implemented in this base class at present

 $instrument->WriteConfig( 'TRIGGER' => { 'SOURCE' => 'CHANNEL1',
  			  	                          'EDGE'   => 'RISE' },
    	               'AQUIRE'  => 'HRES',
    	               'MEASURE' => { 'VRISE' => 'ON' });

Builds up the commands and sends them to the instrument. To get the correct format a 
command rules hash has to be set up by the driver package

e.g. for SCPI commands
$instrument->{'CommandRules'} = { 
                  'preCommand'        => ':',
    		  'inCommand'         => ':',
    		  'betweenCmdAndData' => ' ',
    		  'postData'          => '' # empty entries can be skipped
    		};

=head1 CAVEATS/BUGS

Probably many, with all the porting. This will get better.

=head1 SEE ALSO

=over 4

=item L<Lab::VISA>

=item L<Lab::Instrument::HP34401A>

=item L<Lab::Instrument::HP34970A>

=item L<Lab::Instrument::Source>

=item L<Lab::Instrument::KnickS252>

=item L<Lab::Instrument::Yokogawa7651>

=item L<Lab::Instrument::SR780>

=item L<Lab::Instrument::ILM>

=item L<Lab::Instrument::TCPIP>

=item L<Lab::Instrument::TCPIP::Prologix>

=item L<Lab::Instrument::VISA>

=item and many more...

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2004-2006 Daniel Schröer <schroeer@cpan.org>, 
           2009-2010 Daniel Schröer, Andreas K. Hüttel (L<http://www.akhuettel.de/>) and David Kalok,
           2010      Matthias Völker <mvoelker@cpan.org>
           2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

