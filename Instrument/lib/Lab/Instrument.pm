#$Id$

package Lab::Instrument;

use strict;
use Lab::VISA;
use Lab::Instrument::IsoBus;
use Time::HiRes qw (usleep sleep);
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

    my @args=@_;
    
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
    }
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
    }
    
    
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
    };
    
    return 0;
}


sub Clear {
    my $self=shift;
    
    if ($self->{config}->{isIsoBusInstrument}) { die "Clear not implemented for IsoBus instruments.\n"; };
    
    my $status=Lab::VISA::viClear($self->{instr});
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
}


sub Write {
    my $arg_cnt=@_;
    my $self=shift;
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


sub Read {
    my $self=shift;
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


sub BrutalRead {
    my $self=shift;
    my $length=shift;

    if ($self->{config}->{isIsoBusInstrument}) { die "BrutalRead not implemented for IsoBus instruments.\n"; };
    
    my ($status,$result,$read_cnt)=Lab::VISA::viRead($self->{instr},$length);
    return substr($result,0,$read_cnt);
}


sub Query { # ($cmd, optional $wait_query  , optional $wait_status )
    # contains a nice bomb: read_cnt is arbitrarly set to 300 bytes
    my $arg_cnt=@_;
    my $self=shift;
    my $cmd=shift;

    my $wait_status=$WAIT_STATUS;
    my $wait_query=$WAIT_QUERY;
    if ($arg_cnt==3){ $wait_query=shift; };
    if ($arg_cnt==4){ $wait_status=shift; };
    
    my $write_cnt=$self->Write($cmd);
    my $read_cnt;
    
    usleep($wait_query); #<---ensures that asked data presented from the device

    my $result=$self->Read($QUERY_LENGTH);
    return $result;
}


sub LongQuery { # ($cmd, optional $wait_query  , optional $wait_status )
    # contains a nice bomb: read_cnt is arbitrarly set to 10240 bytes
    my $arg_cnt=@_;
    my $self=shift;
    my $cmd=shift;

    if ($self->{config}->{isIsoBusInstrument}) { die "LongQuery not implemented for IsoBus instruments.\n"; };
    
    my $wait_status=$WAIT_STATUS;
    my $wait_query=$WAIT_QUERY;
    if ($arg_cnt==3){ $wait_query=shift}
    if ($arg_cnt==4){ $wait_status=shift}    
    
    my $write_cnt=$self->Write($cmd);
    my $read_cnt;
    usleep($wait_query); #<---ensures that asked data presented from the device

    my $result=$self->Read($QUERY_LONG_LENGTH);
    return $result;
}


sub BrutalQuery {
    # contains a nice bomb: read_cnt is arbitrarly set to 300 bytes
    my $arg_cnt=@_;
    my $self=shift;
    my $cmd=shift;

    if ($self->{config}->{isIsoBusInstrument}) { die "Query not implemented for IsoBus instruments.\n"; };
    
    my $wait_status=$WAIT_STATUS;
    my $wait_query=$WAIT_QUERY;
    if ($arg_cnt==3){ $wait_query=shift}
    if ($arg_cnt==4){ $wait_status=shift}    
    
    my $write_cnt=$self->Write($cmd);
    my $read_cnt;
    usleep($wait_query); #<---ensures that asked data presented from the device

    my $result=$self->BrutalRead($QUERY_LENGTH);
    return $result;
}


sub Handle {
    my $self=shift;
    if ($self->{config}->{isIsoBusInstrument}) { die "Handle not implemented for IsoBus instruments.\n"; };     
    return $self->{instr};
}


sub DESTROY {
    my $self=shift;
    
    if ($self->{config}->{isIsoBusInstrument}) {
        # we dont actually have to do anything here :)
    } else {
        my $status=Lab::VISA::viClose($self->{instr});
        $status=Lab::VISA::viClose($self->{default_rm});
    };
}


1;

=head1 NAME

Lab::Instrument - General VISA based instrument

=head1 SYNOPSIS

 use Lab::Instrument;
 
 my $hp22 =  new Lab::Instrument(0,22); # GPIB board 0, address 22
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

Creates a new instrument object and open the instrument with GPIB address C<$addr>
connected to the GPIB board C<$board> (usually 0). Alternatively, the VISA resource 
name C<$resourcename> can be specified as string 
for serial or USB devices. All instrument classes that
internally use the C<Lab::Instrument> module (that's all instruments in the default
distribution) can use these three forms of the constructor.

Lastly, an IsoBus device can be instantiated by providing the IsoBus instrument C<$isobus>
(of type C<Lab::Instrument::IsoBus>) as first parameter and the numeric IsoBus address 
of the device C<$addr> as second parameter.

=head1 METHODS

=head2 Write

 $write_count=$instrument->Write($command);
 
Sends the command C<$command> to the instrument.

=head2 Read

 $result=$instrument->Read($length);

Reads a result of maximum length C<$length> from the instrument and returns it.
Dies with a message if an error occurs.

=head2 BrutalRead

 $result=$instrument->BrutalRead($length);

Same as Read, but this command ignores all error conditions.

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

Sends a clear command to the instrument.

=head2 Handle

 $instr_handle=$instrument->Handle();

Returns the VISA handle. You can use this handle with the L<Lab::VISA> module.

=head1 CAVEATS/BUGS

Probably many.

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

=item and many more

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2004-2006 Daniel Schröer <schroeer@cpan.org>, 
           2009-2010 Daniel Schröer, Andreas K. Hüttel (L<http://www.akhuettel.de/>) and David Kalok

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
