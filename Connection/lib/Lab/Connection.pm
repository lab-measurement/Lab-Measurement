#!/usr/bin/perl -w
# POD

#$Id$

package Lab::Connection;

use strict;

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function

use Carp;
use Data::Dumper;
our $AUTOLOAD;


# setup this variable to add inherited functions later
our @ISA = ();

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

our $WAIT_STATUS=10;#usec;
our $WAIT_QUERY=10;#usec;
our $QUERY_LENGTH=300; # bytes
our $QUERY_LONG_LENGTH=10240; #bytes
our $INS_DEBUG=0; # do we need additional output?


my %fields = (
	Config => undef,
);


sub new {
	#
	# This doesn't do much except setting basic data fields and delivering
	# their %fields and _permitted to inheriting objects/classes
	(my $proto, my $Config) = (shift,shift);
	my $class = ref($proto) || $proto;
	my $self={};
	bless ($self, $class);
	$self->ConstructMe();

	# next argument has to be the configuration hash
	$self->Config($Config);

	return $self;
}

#
# config gets it's own accessor - read only access to $self->Config
# with no argument, returns a reference to $self->Config (just like AUTOLOAD would)
#
sub Config {	# $value = self->Config($key);
	(my $self, my $key) = (shift, shift);

	if(defined $key) {
		return $self->Config->{'$key'};
	}
	else {
		return $self->Config;
	}
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

#
# Call this in inheriting class's constructors to conveniently initialize the %fields object data.
#
#
sub ConstructMe {	# ConstructMe(__PACKAGE__);
	(my $self, my $package) = (shift, shift);
	my $class = ref($self);

	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;
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





1;

=head1 NAME

Lab::Connection - connection base class

=head1 SYNOPSIS

This is meant to be used as a base class for inheriting instruments only.
Every inheriting classes constructors should start as follows:

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = $class->SUPER::new(@_);
		$self->ConstructMe(__PACKAGE__); #initialize fields etc.
		...
	}

=head1 DESCRIPTION

C<Lab::Connection> is a base class for individual connections. It doesn't do anything on its own.
For more detailed information on the use of connection objects, take a look on a child class, e.g.
C<Lab::Connection::GPIB>.

=head1 CONSTRUCTOR

=head2 new

Generally called in child class constructor:

 my $self = $class->SUPER::new(@_);

Return blessed $self, with @_ accessible through $self->Config().

=head1 METHODS

=head2 Config

Provides unified access to the fields in initial @_ to all the cild classes.
E.g.

 $GPIB_PAddress=$instrument->Config(GPIB_PAddress);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_PAddress = $connection->Config()->{'GPIB_PAddress'};
 
=head1 CAVEATS/BUGS

Probably view. Mostly because there's not a lot to be done here.

=head1 SEE ALSO

=over 4

=item L<Lab::Connection::GPIB>

=item L<Lab::Connection::MODBUS>

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


1;