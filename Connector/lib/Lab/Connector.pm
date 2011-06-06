#!/usr/bin/perl -w
# POD

#$Id$

package Lab::Connector;

use strict;

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function

use Carp;
use Data::Dumper;
our $AUTOLOAD;


our @ISA = ();

# our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

# this holds a list of references to all the connector objects that are floating around in memory,
# to enable transparent connector reuse, so the user doesn't have to handle (or even know about,
# to that end) connector objects. weaken() is used so the reference in this list does not prevent destruction
# of the object when the last "real" reference is gone.
our %ConnectorList = (
	# ConnectorType => $ConnectorReference,
);

our %fields = (
	config => undef,
	type => undef,	# e.g. 'GPIB'
	ignore_twins => 0, # 
	ins_debug=>0,  # do we need additional output?
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $config = undef;
	if (ref $_[0] eq 'HASH') { $config=shift } # try to be flexible about options as hash/hashref
	else { $config={@_} }
	my $self={};
	bless ($self, $class);
	$self->_construct(__PACKAGE__, \%fields);

	$self->config($config);

	# Object data setup
	$self->ignore_twins($self->config('ignore_twins'));

	return $self;
}


#
# Call this in inheriting class's constructors to conveniently initialize the %fields object data
#
sub _construct {	# _construct(__PACKAGE__, %fields);
	(my $self, my $package, my $fields) = (shift, shift, shift);
	my $class = ref($self);
	my $twin = undef;

	foreach my $element (keys %{$fields}) {
		$self->{_permitted}->{$element} = $fields->{$element};
	}
	@{$self}{keys %{$fields}} = values %{$fields};
}


#
# these are stubs to be overwritten in child classes
#

#
# In child classes, this should search %Lab::Connector::ConnectorList for a reusable
# instance (and be called in the constructor).
# e.g.
# return $self->_search_twin() || $self;
#
sub _search_twin {
	return 0;
}

sub connection_read { # @_ = ( $connection_handle, \%args )
	return 0;
}

sub connection_write { # @_ = ( $connection_handle, \%args )
	return 0;
}

#
# generates and returns a connection handle;
#
sub connection_new {
	return 0;
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
		Lab::Exception::Error->throw( error => "AUTOLOAD in " . __PACKAGE__ . " couldn't access field '${name}'.\n"  . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));
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





1;

=head1 NAME

Lab::Connector - connector base class

=head1 SYNOPSIS

This is meant to be used as a base class for inheriting instruments only.
Every inheriting classes constructors should start as follows:

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = $class->SUPER::new(@_);
		$self->_construct(__PACKAGE__); #initialize fields etc.
		...
	}

=head1 DESCRIPTION

C<Lab::Connector> is a base class for individual connectors. It doesn't do anything on its own.
For more detailed information on the use of connector objects, take a look on a child class, e.g.
C<Lab::Connector::GPIB>.

In C<%Lab::Connector::ConnectorList> resides a hash which contains references to all the active connectors in your program.
They are put there by the constructor of the individual connector C<Lab::Connector::new()> and have two levels: Package name and
a unique connector ID (GPIB board index offers itself for GPIB). This is to transparently (to the use interface) reuse connector objects,
as there may only be one connector object for every (hardware) connector. weaken() is used on every reference stored in this hash, so
it doesn't prevent object destruction when the last "real" reference is lost.
Yes, this breaks object orientation a little, but it comes so handy!

our %Lab::Connector::ConnectorList = [

	$Package => {
		$UniqueID => $Object,
	}

	'Lab::Connector::GPIB' => {
		'0' => $Object,		"0" is the gpib board index, here
	}

Place your twin searching code in $self->_search_twin(). Make sure it evaluates $self->IgnoreTwin(). Look at Lab::Connector::GPIB.


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

 $Config = $connector->Config();
 $GPIB_PAddress = $connector->Config()->{'GPIB_PAddress'};
 
=head1 CAVEATS/BUGS

Probably view. Mostly because there's not a lot to be done here.

=head1 SEE ALSO

=over 4

=item L<Lab::Connector::GPIB>

=item L<Lab::Connector::MODBUS>

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