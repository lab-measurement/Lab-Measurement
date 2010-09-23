#!/usr/bin/perl -w
# POD

#$Id$

package Lab::Instrument;

use strict;
# removed to load only if needed
# use Lab::VISA;
# use Lab::Instrument::IsoBus;

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function


# setup this variable to add inherited functions later
our @ISA = ();

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

our $WAIT_STATUS=10;#usec;
our $WAIT_QUERY=10;#usec;
our $QUERY_LENGTH=300; # bytes
our $QUERY_LONG_LENGTH=10240; #bytes
our $INS_DEBUG=0; # do we need additional output?

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless ($self, $class);

	
	# check if arguments is a hash with the key 'interface'
	my %args = ();
	%args = @_ if (int(@_/2) == (@_/2)); 

	if (exists $args{'Interface'}) {
		my $ifName="Lab::Instrument::".$args{'Interface'};

		# new interface using separate interface objects
		push(@INC, $args{'ModulePath'}) if (exists $args{'ModulePath'});
		eval('require '.$ifName.';') or die "Could not load the interface package $ifName\n"; # eval required to solve path problems with ::

		# call the new function
		$self->{'interface'}=$ifName->new(%args); # small key names for internal functions
		# everything okay?
		return undef unless (defined $self->{'interface'});

		# look to delay property
		$self->{'InterfaceDelay'} = $args{'InterfaceDelay'} if (exists $args{'InterfaceDelay'});
		# inherit functions from the interface object
		push(@ISA,$ifName);
		# done
		return $self;
	} else {
		# old interface from Lab::Instrument V2.01
		my @args=@_;
		# load required packages
		require Lab::VISA;
		require Lab::Instrument;
        
        	$self->{config}->{isIsoBusInstrument}=0;
        	
        	my ($status,$res)=Lab::VISA::viOpenDefaultRM();
        	if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot open resource manager: $status";}
        	$self->{default_rm}=$res;
        
        	my $resource_name;
        	
        	#
        	# GPIB instruments can be defined by providing a hash as constructor argument
        	#
        	if ((ref $args[0]) eq 'HASH') {
        		$self->{config}=$args[0];
        		if (defined ($self->{config}->{GPIB_address})) {
        			@args=(
        				(defined ($self->{config}->{GPIB_board})) ? $self->{config}->{GPIB_board} : 0, $self->{config}->{GPIB_address});
        		} else {
        			die "The Lab::Instrument constructor got a malformed hash as argument. Aborting.\n";
        		}
        	} # argument was a hash - check finished

        	if ($#args >0) { 
        		#
        		# more than one argument
        		#
        		my $firstargtype=ref($args[0]);
        		if ($firstargtype eq 'Lab::Instrument::IsoBus') {
        			print "Hey great! Someone is testing IsoBus instruments!!!\n";
        			print "IsoBus support is UNTESTED so far. It may eat your pet targh. You have been warned.\n";
        			#
        			# First argument: the IsoBus instrument
        			# Second argument: the IsoBus address
        			#
        			if ($args[0]->IsoBus_valid()) {			
        				print "Connected to valid IsoBus.\n";
        				$self->{config}->{isIsoBusInstrument}=1;
        				$self->{config}->{IsoBus}=$args[0];
        				$self->{config}->{IsoBusAddress}=$args[1];
        			} else {
        				die "Tried to instantiate IsoBus instrument without valid IsoBus. Aborting.\n";
        			};
        		} else {
        			#
        			# More than one argument: assume GPIB, and the two arguments are gpib adaptor and gpib address
        			#
        			$resource_name=sprintf("GPIB%u::%u::INSTR",$args[0],$args[1]);
        		}
        	} else {    
        		# 
        		# Exactly one argument -> this should be the VISA resource name of the instrument
        		# 
        		$resource_name=$args[0];
        	}# arguments given - check finished
            
        	
        	if ($self->{config}->{isIsoBusInstrument}) {
        		#
        		# we are creating an IsoBus instrument
        		#
        		if ($INS_DEBUG) { print "Instantiated IsoBus device.\n"; };
        		return $self;
        		
        	} else {
        		# 
        		# we are creating a VISA instrument
        		#
        		if ($resource_name) {
        			($status,my $instrument)=Lab::VISA::viOpen($self->{default_rm},$resource_name,$Lab::VISA::VI_NULL,$Lab::VISA::VI_NULL);
        			if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot open VISA instrument \"$resource_name\". Status: $status";}
        			$self->{instr}=$instrument;
                
        			$status=Lab::VISA::viSetAttribute($self->{instr}, $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
        			if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting timeout value: $status";}
            
        			if ($INS_DEBUG) { print "Instantiated VISA resource $resource_name.\n"; };
        			return $self;
        		} else {
        			die "You need to tell me which VISA instrument you want to open!!! Aborting...\n";		
        		};
        	} # selection if isoBus is used
	} # end of decision for new or old interface        	
    return 0;
}


sub Clear {
    my $self=shift;
    
    if (exists $self->{'interface'}) {
	# redirect to interface function
	return $self->{'interface'}->Clear(@_) if ($self->{'interface'}->can('Clear'));
	# error message
	die "Clear function is not implemented in the interface ".$self->{'interface'}."\n";
    } 
    # use old VISA implementation
    if ($self->{config}->{isIsoBusInstrument}) { die "Clear not implemented for IsoBus instruments.\n"; };
	
    my $status=Lab::VISA::viClear($self->{instr});
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
    
}


sub Write {
	my $arg_cnt=@_;
	my $self=shift;
	
	if (exists $self->{'interface'}) {
		if ($INS_DEBUG) {
		  print STDERR "DEBUG: Write(".join(',',@_).")\n";
		}
		# redirect to interface function
		# add delay if defined
		sleep($self->{'InterfaceDelay'}) if (exists $self->{'InterfaceDelay'});
		return $self->{'interface'}->Write(@_);
    	} else {
		# use old VISA implementation
		my $cmd=shift;

		if ($self->{config}->{isIsoBusInstrument}) { 
	
			my $write_cnt=$self->{config}->{IsoBus}->IsoBus_Write($self->{config}->{IsoBusAddress}, $cmd);
			return $write_cnt;
		
		} else {
	
			my $wait_status=$WAIT_STATUS;
			if ($arg_cnt==3){ $wait_status=shift}
			my ($status, $write_cnt)=Lab::VISA::viWrite(
				$self->{instr},
				$cmd,
				length($cmd)
			);
			usleep($wait_status);
			if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while writing string \"\n$cmd\n\": $status";}
			return $write_cnt;
		
		};
	}
}


sub Read {
	my $self=shift;

	if (exists $self->{'interface'}) {
		# redirect to interface function
		
		sleep($self->{'InterfaceDelay'}) if (exists $self->{'InterfaceDelay'});
		
		if ((exists $self->{'brutal'}) && $self->{'brutal'}) {
			# do a brutal read
			return $self->BrutalRead(@_);
		} else {
			# normal read
			return $self->{'interface'}->Read(@_);
		}
    	} else {

		my $length=shift;

		if ($self->{config}->{isIsoBusInstrument}) { 
	
			my $result=$self->{config}->{IsoBus}->IsoBus_Read($self->{config}->{IsoBusAddress}, $length);
			return $result;
		
		} else {	

			my ($status,$result,$read_cnt)=Lab::VISA::viRead($self->{instr},$length);
			if (($status != $Lab::VISA::VI_SUCCESS) && ($status != 0x3FFF0005)){die "Error while reading: $status";};
			return substr($result,0,$read_cnt);
		
		};
	}
}


sub BrutalRead {
    my $self=shift;

    if (exists $self->{'interface'}) {
	# redirect to interface function
 	return $self->{'interface'}->BrutalRead(@_) if ($self->{'interface'}->can('BrutalRead'));
	# use Read if Brutal read is not implemented
	return $self->{'interface'}->Read(@_);
    } else {
    	my $length=shift;

    	if ($self->{config}->{isIsoBusInstrument}) { die "BrutalRead not implemented for IsoBus instruments.\n"; };
	
    	my ($status,$result,$read_cnt)=Lab::VISA::viRead($self->{instr},$length);
    	return substr($result,0,$read_cnt);
    }
}


sub Query { # ($cmd, optional $wait_query  , optional $wait_status )
	# contains a nice bomb: read_cnt is arbitrarly set to 300 bytes
	my $arg_cnt=@_;
	my $self=shift;
	
	my $cmd=shift;

	my $wait_status=$WAIT_STATUS;
	# load own setting if exists
	$wait_status = $self->{'wait_status'} if (exists $self->{'wait_status'});
	my $wait_query=$WAIT_QUERY;
	# load own settings if exists
	$wait_query = $self->{'wait_query'} if (exists $self->{'wait_query'});
	if ($arg_cnt==3){ $wait_query=shift; };
	if ($arg_cnt==4){ $wait_status=shift; };
	
	my $write_cnt=$self->Write($cmd);
	# set default value
	my $read_cnt = $QUERY_LENGTH;
	# read own value if defined
	$read_cnt = $self->{'query_cnt'} if (exists $self->{'query_cnt'});

	# backward compatibility
	$read_cnt = $QUERY_LENGTH if ( not(exists $self->{'interface'}) and ($read_cnt eq 'all'));

	usleep($wait_query); #<---ensures that asked data presented from the device
	
	return $self->Read($read_cnt);
}


sub LongQuery { # ($cmd, optional $wait_query  , optional $wait_status )
    # contains a nice bomb: read_cnt is arbitrarly set to 10240 bytes
    my $self=shift;

    # save current setting
    my $save_read_cnt = $self->{'query_cnt'};
    # set to long query setup
    $self->{'query_cnt'} = $QUERY_LONG_LENGTH;
    $self->{'query_cnt'} = $self->{'long_query_cnt'} if (exists $self->{'long_query_cnt'});
    # request
    my $result = $self->Query(@_);
    # reconfigure read count
    $self->{'query_cnt'} = $save_read_cnt;

    return $result;
}


sub BrutalQuery {
    # contains a nice bomb: read_cnt is arbitrarly set to 300 bytes
    my $self=shift;
    # save current config
    my $save_config = $self->{'brutal'};
    # select brutal
    $self->{'brutal'} = 1;
    # do the task
    my $result = $self->Query(@_);    
    # restor orginal config
    $self->{'brutal'} = $save_config;
    return $result;
}


sub Handle {
    my $self=shift;
    if ($self->{config}->{isIsoBusInstrument}) { die "Handle not implemented for IsoBus instruments.\n"; };		
    if (exists $self->{'interface'}) {    
       return $self->{'interface'};
    }
    return $self->{instr};
}


sub DESTROY {
    my $self=shift;
    unless( exists $self->{'interface'}) {
	
	if ($self->{config}->{isIsoBusInstrument}) {
		# we dont actually have to do anything here :)
	} else {
	    my $status=Lab::VISA::viClose($self->{instr});
		$status=Lab::VISA::viClose($self->{default_rm});
	};
   } # done only for old interface
}

sub WriteConfig {
        my $self = shift;

        my %config = @_;
	%config = %{$_[0]} if (ref($_[0]));

	my $command = "";
	# function characters init
	my $inCommand = "";
	my $betweenCmdAndData = "";
	my $postData = "";
	# config data
	if (exists $self->{'CommandRules'}) {
		# write stating value by default to command
		$command = $self->{'CommandRules'}->{'preCommand'} 
			if (exists $self->{'CommandRules'}->{'preCommand'});
		$inCommand = $self->{'CommandRules'}->{'inCommand'} 
			if (exists $self->{'CommandRules'}->{'inCommand'});
		$betweenCmdAndData = $self->{'CommandRules'}->{'betweenCmdAndData'} 
			if (exists $self->{'CommandRules'}->{'betweenCmdAndData'});
		$postData = $self->{'CommandRules'}->{'postData'} 
			if (exists $self->{'CommandRules'}->{'postData'});
	}
	# get command if sub call from itself
	$command = $_[1] if (ref($_[0])); 

        # build up commands buffer
        foreach my $key (keys %config) {
		my $value = $config{$key};

		# reference again?
		if (ref($value)) {
			$self->WriteConfig($value,$command.$key.$inCommand);
		} else {
			# end of search
			$self->Write($command.$key.$betweenCmdAndData.$value.$postData);
		}
	}

}



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
