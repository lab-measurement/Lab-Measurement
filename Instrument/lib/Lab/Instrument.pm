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

our $WAIT_STATUS=10;#usec;
our $WAIT_QUERY=10;#usec;
our $QUERY_LENGTH=300; # bytes
our $QUERY_LONG_LENGTH=10240; #bytes
our $INS_DEBUG=0; # do we need additional output?

my %fields = (
	Connection => undef,
	ConnectionType => "",
	Config => undef,
	SupportedConnections => [ ],
);



sub new { 
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self={};
	bless ($self, $class);
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;

	# next argument has to be the configuration hash
	$self->Config(shift);

	return $self;
}


sub _checkconfig {
	my $self=shift;
	my $Config = $self->Config();

	return 1;
}

sub _checkconnection { # Connection object or ConnType string
	my $self=shift;
	my $connection=shift;
	my $ConnType = undef;

	$ConnType = ( split( '::',  ref($connection) || $connection ))[-1];

 	if (1 != grep( /^$ConnType$/, @{$self->SupportedConnections()} )) {
 		return 0;
 	}
	else {
		return 1;
	}
}


sub _setconnection { # create new or use existing connection
	my $self=shift;

	# check the configuration hash for a valid connection object or connection type, and set the connection
	if( defined($self->Config()->{'Connection'}) ) {
		if($self->_checkconnection($self->Config()->{'Connection'})) {
			$self->Connection($self->Config()->{'Connection'});
		}
		else { Lab::Exception::CorruptParameter->throw('Given connection is not supported.'); }
	}
	else {
		if($self->_checkconnection($self->Config()->{'ConnType'})) {
			$self->Connection(eval("new Lab::Connection::${\$self->Config()->{'ConnType'}}({GPIB_Board => 0})")) || croak('Failed to create connection');
			print "conntype: " . $self->Config()->{'ConnType'}. "\n";
		}
		else { Lab::Exception::CorruptParameter->throw('Given connection type is not supported.'); }
	}
	$self->InstrumentHandle( $self->Connection()->InstrumentNew(GPIB_Paddr => $self->Config()->{'GPIB_Paddress'}) );
}


sub AUTOLOAD {

	my $self = shift;
	my $type = ref($self) or croak "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://; # strip fully qualified portion

	unless (exists $self->{_permitted}->{$name} ) {
		Lab::Exception::UndefinedField->throw( error => "Can't access `$name' field in class $type\n" );
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
	#$self->Connection()->DESTROY();
        $self -> SUPER::DESTROY if $self -> can ("SUPER::DESTROY");
}



sub Clear {
	my $self=shift;
	
	return $self->Connection()->InstrumentClear($self->InstrumentHandle()) if ($self->Connection()->can('Clear'));
	# error message
	die "Clear function is not implemented in the connection ".ref($self->Connection())."\n";
}


sub Write {
	my $self=shift;
	my $data=shift;
	
	return $self->Connection()->InstrumentWrite($self->InstrumentHandle(), { Cmd => $data });
}




sub Read {
	my $self=shift;
	my %options=shift;
	%options={} unless (%options);

	return $self->Connection()->InstrumentRead($self->InstrumentHandle(), \%options);
}


# 
# sub BrutalRead {
#     	my $self=shift;
#     	my %options=shift;
# 	%options={} unless (%options);
# 	%options->{'brutal'}=1;
# 
# 	return $self->{'interface'}->InstrumentRead($self->{'handle'}, %options);
# }
# 


sub Query { # $self, $cmd, %options
	my $self=shift;
	my $cmd=shift;
	my %options=shift;
	%options={} unless (%options);

	my $wait_query=$WAIT_QUERY;
	# load own settings if exists
	$wait_query = $self->{'wait_query'} if (exists $self->{'wait_query'});
	
	$self->Write({ Cmd => $cmd });
	usleep($wait_query);
	return $self->Read(%options);
}


# 
# sub BrutalQuery {
# 	my $self=shift;
# 	my $cmd=shift;
# 	my %options=shift;
# 	%options={} unless (%options);
# 	%options{'brutal'}=1;
# 	return $self->Query($cmd,%options);
# };
# 
# 
# sub Handle {
#     	my $self=shift;
#     	return $self->{'handle'};
# }
# 
# 
# sub DESTROY {
#     	my $self=shift;
#         $self->{'interface'}->InstrumentDestroy($self->{'handle'}, %options);
#         
# 	if (exists $self->{instr} ) {
# 	      my $status=Lab::VISA::viClose($self->{instr});
# 	      $status=Lab::VISA::viClose($self->{default_rm});
#             }
# 	};
#    } # done only for old interface
# }
# 
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

 use Lab::Instrument;
 
 # old interface
 my $hp22 =  new Lab::Instrument(0,22); # GPIB board 0, address 22
 print $hp22->Query('*IDN?');

 #new interface
 my $hp22 =  new Lab::Instrument( Interface => 'TCPIP',
		          		          PeerAddr  => 'cs025',
				                  PeerPort  => 5025); 
 print $hp22->Query('*IDN?');

=head1 DESCRIPTION

C<Lab::Instrument> offers an abstract interface to an instrument, that is connected via
GPIB, serial bus, USB, ethernet, or Oxford Instruments IsoBus. It provides general 
C<Read>, C<Write> and C<Query> methods, and more.

It can be used either directly by the programmer to work with
an instrument that doesn't have its own perl class
(like L<Lab::Instrument::HP34401A|Lab::Instrument::HP34401A>). Or it can be used by such a specialized
perl instrument class (like C<Lab::Instrument::HP34401A>) to delegate the
actual visa work. (All the instruments in the default package do so.)

=head1 CONSTRUCTOR

=head2 new

 $instrument  = new Lab::Instrument($board,$addr);
 
 $instrument2 = new Lab::Instrument({
    GPIB_board   => $board,
    GPIB_address => $addr
 });

 $instrument3 = new Lab::Instrument($resourcename);

 $instrument4 = new Lab::Instrument($isobus,$addr);

 $instrument5 = new Lab::Instrument( Interface => TCPIP|RS232|VISA|TCPIP::Prologix,
				                     parameter name => parameter,
				                     ... );

Creates a new instrument object and open the instrument with GPIB address C<$addr>
connected to the GPIB board C<$board> (usually 0). Alternatively, the VISA resource 
name C<$resourcename> can be specified as string 
for serial or USB devices. All instrument classes that
internally use the C<Lab::Instrument> module (that's all instruments in the default
distribution) can use these three forms of the constructor.

An IsoBus device can be instantiated by providing the IsoBus instrument C<$isobus>
(of type C<Lab::Instrument::IsoBus>) as first parameter and the numeric IsoBus address 
of the device C<$addr> as second parameter.

Lastly, C<Lab::Instrument> interface packages can be used. These packages provide different 
interfaces. The required parameters can be found in the package description of the corresponding
package like C<Lab::Instrument::TCPIP> for the interface type TCPIP. If the interface modules
are not located in the default directories, that path can be given by the 'ModulePath' option.

=head1 METHODS

=head2 Write

 $write_count=$instrument->Write($command);
 
Sends the command C<$command> to the instrument.

=head2 Read

 $result=$instrument->Read($length);

Reads a result of maximum length C<$length> from the instrument and returns it.
Dies with a message if an error occurs. 

If interface package is used and object key 'brutal' is true, Read equals to BrutalRead. 
The length C<all> can be used to read until timeout. (Only for available if interface package
is used)

=head2 BrutalRead

 $result=$instrument->BrutalRead($length);

Same as Read, but this command ignores all error conditions. If an interface
package is used Read is used if BrutalRead is not implemented.

=head2 Query

 $result=$instrument->Query($command, $wait_query, $wait_status);

Sends the command C<$command> to the instrument and reads a result from the
instrument and returns it. The length of the read buffer is haphazardly
set to 300 bytes. 

Optional second and third arguments specify waiting times, i.e. how long the 
instrument needs to process the query and provide a result (C<$wait_query>) and 
how long the instrument needs to react on a command at all and set the status 
line (C<$wait_status>). Both parameters are set to 10us if not specified in 
the command line.

The default values of 'query_cnt', 'wait_query' and 'wait_status' can be overwritten
by defining the corresponding object key.

=head2 LongQuery

 $result=$instrument->LongQuery($command, $wait_query, $wait_status);

Same as Query, but with a read buffer size of 10240 bytes. If you need to read
even more data, you will have to use separate C<Write> and C<Read> calls.

=head2 BrutalQuery

 $result=$instrument->BrutalQuery($command);

Same as Query (i.e. buffer size 300 bytes), but with a lot less finesse. :) 
Sends command, asks for a value and returns whatever is returned. All error 
conditions including timeouts are blatantly ignored.

=head2 Clear

 $instrument->Clear();

Sends a clear command to the instrument if implemented for the interface.

=head2 Handle

 $instr_handle=$instrument->Handle();

Returns the VISA handle or the instrument package handle. The VISA handle can be 
used with the L<Lab::VISA> module.

=head2 WriteConfig

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

Probably many. Currently the old and the new interface is implemented. The goal would be to 
provide the old interface by loading the C<Lab::Instrument::VISA> package automaticly during
obejct creation and to remove the old code from all other functions.

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

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

