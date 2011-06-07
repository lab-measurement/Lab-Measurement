#!/usr/bin/perl -w

package Lab::Connection;

use strict;

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function

use Carp;
use Data::Dumper;
our $AUTOLOAD;


our @ISA = ();


our %fields = (
	connection_handle => undef,
	connector => undef, # set default here in child classes, e.g. connector => "GPIB"
	connector_class => "",
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
# generic methods - interface definition
#


sub Clear {
	my $self=shift;
	
	return $self->connector()->connection_clear($self->connection_handle()) if ($self->connector()->can('connection_clear'));
	# error message
	warn "Clear function is not implemented in the connector ".ref($self->connector())."\n"  . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__);
}


sub Write {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }
	
	return $self->connector()->connection_write($self->connection_handle(), $options);
}


sub Read {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	return $self->connector()->connection_read($self->connection_handle(), $options);
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
# infrastructure stuff below
#



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

	if( $class eq $package ) {
		$self->_setconnector();
	}
}


#
# Method to handle connector creation generically. This is called by _construct().
# If the following (rather simple code) doesn't suit your child class, or your need to
# introduce more thorough parameter checking and/or conversion, overwrite it - _construct()
# calls it only if it is called by the topmost class in the inheritance hierarchy itself.
#
# set $self->connection_handle
#
sub _setconnector { # $self->setconnector() create new or use existing connector
	my $self=shift;
	my $connector_class = $self->connector_class();

	warn ("new Lab::Connector::${connector_class}(\$self->config())\n");
	$self->connector(eval("require $connector_class; new $connector_class(\$self->config());")) || Lab::Exception::Error->throw( error => "Failed to create connector $connector_class in " . __PACKAGE__ . "::_setconnector.\n"  . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));

	# again, pass it all.
	$self->connection_handle( $self->connector()->connection_new( $self->config() ));
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
		cluck ("waaa");
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

Lab::Connection - connection base class

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

C<Lab::Connection> is a base class for individual connections. It doesn't do anything on its own.
For more detailed information on the use of connection objects, take a look on a child class, e.g.
C<Lab::Connection::GPIB>.

In C<%Lab::Connection::ConnectionList> resides a hash which contains references to all the active connections in your program.
They are put there by the constructor of the individual connection C<Lab::Connection::new()> and have two levels: Package name and
a unique connection ID (GPIB board index offers itself for GPIB). This is to transparently (to the use interface) reuse connection objects,
as there may only be one connection object for every (hardware) connection. weaken() is used on every reference stored in this hash, so
it doesn't prevent object destruction when the last "real" reference is lost.
Yes, this breaks object orientation a little, but it comes so handy!

our %Lab::Connection::ConnectionList = [

	$Package => {
		$UniqueID => $Object,
	}

	'Lab::Connection::GPIB' => {
		'0' => $Object,		"0" is the gpib board index, here
	}

Place your twin searching code in $self->_search_twin(). Make sure it evaluates $self->IgnoreTwin(). Look at Lab::Connection::GPIB.


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

 Copyright 2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut


1;