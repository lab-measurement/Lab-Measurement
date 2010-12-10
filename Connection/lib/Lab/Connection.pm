#!/usr/bin/perl -w
# POD

#$Id$

package Lab::Connection;

use strict;

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function

use Carp;
our $AUTOLOAD;


# setup this variable to add inherited functions later
our @ISA = ();

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

our $WAIT_STATUS=10;#usec;
our $WAIT_QUERY=10;#usec;
our $QUERY_LENGTH=300; # bytes
our $QUERY_LONG_LENGTH=10240; #bytes
our $INS_DEBUG=0; # do we need additional output?

our $Config={};


#
# I'll try using the AUTOLOAD method for accessing object data. The access methods named after the
# variables will be the same for any other approach we might want to change to later.
#
my %fields = (
);


sub new {

	#
	# This doesn't do much except setting basic data fields and delivering
	# their %fields and _permitted to inheriting objects/classes

	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self={};
	bless ($self, $class);
#	my $self = $class->SUPER::new(); # getting fields and _permitted from parent class
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;



	# we have one more parameter, which is a reference to the instrument config hash
	# $Config = shift;
	return $self;
}

sub AUTOLOAD {

	my $self = shift;
	my $type = ref($self) or croak "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://; # strip fuly qualified portion

	unless (exists $self->{_permitted}->{$name} ) {
		croak "Can't access `$name' field in class $type";
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
        $self -> SUPER::DESTROY if $self -> can ("SUPER::DESTROY");
}



# 
# 
# sub InstrumentClear { # $self, %handle
#     	my $self=shift;
#     	my %handle=shift;
# 
# 	# redirect to specific (i.e. ::VISA) interface function
# 	return $self->{'interface'}->InstrumentClear(%handle) if ($self->{'interface'}->can('Clear'));
# 	# error message
# 	die "Clear function is not implemented in the interface ".$self->{'interface'}."\n";
# }
# 
# sub InstrumentRead { # $self, %handle, %options 
# 	my $self=shift;
# 	my %handle=shift;
# 	my %options=shift;
# 
# 	# redirect to interface function	
# 	sleep($self->{'InterfaceDelay'}) if (exists $self->{'InterfaceDelay'});
# 	
# 	if ($options->{'brutal'}) {
# 		# redirect to interface function
# 		return $self->{'interface'}->InstrumentBrutalRead(%handle,%options) if ($self->{'interface'}->can('BrutalRead'));
# 		# use Read if Brutal read is not implemented
# 	};
# 	return $self->{'interface'}->InstrumentRead(%handle,%options);
# }
# 
# 
# sub InstrumentWrite { # $self, %handle, $data
# 	my $self=shift;	
# 	my %handle=shift;
# 	my $data=shift;
# 	
# 	# add delay if defined
# 	sleep($self->{'InterfaceDelay'}) if (exists $self->{'InterfaceDelay'});
# 	# redirect to interface function
# 	return $self->{'interface'}->InstrumentWrite(%handle,$data);
# }
# 


# sub DESTROY {
#     my $self=shift;
#     unless( exists $self->{'interface'}) {
#     } # done only for old interface
# }


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

Lab::Interface - General interface package

=head1 SYNOPSIS

 use Lab::Interface;
 use Lab::Instrument;
 
 my $visa =  new Lab::Interface( Type => 'VISA' ); 
 my $rszdz = new Lab::Interface( Type => 'RS232', Device => '/dev/modem' );
 
 my $ins=new Lab::Instrument::Bla($visa, {Address=>'GPIB::INSTR::...'});
 print $ins->Query('*IDN?');

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

 $interface = new Lab::Interface( Type => TCPIP|RS232|VISA|TCPIP::Prologix,
				                     parameter name => parameter,
				                     ... );

C<Lab::Interface> interface packages can be used. These packages provide different 
interfaces. The required parameters can be found in the package description of the corresponding
package like C<Lab::Interface::TCPIP> for the interface type TCPIP. If the interface modules
are not located in the default directories, that path can be given by the 'ModulePath' option.

=head1 METHODS

=head2 Write

 $write_count=$instrument->Write(%target,$data);
 

=head2 Read

 $result=$instrument->Read(%target,%options);

=head2 Clear

 $instrument->Clear(%target);

Sends a clear command to the instrument if implemented for the interface.

=head2 Handle

 $instr_handle=$instrument->Handle();

Returns the instrument package handle.

=head2 WriteConfig

=head1 CAVEATS/BUGS

Probably many. 

=head1 SEE ALSO

=over 4

=item L<Lab::VISA>

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


1;