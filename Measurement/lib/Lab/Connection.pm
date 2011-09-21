#!/usr/bin/perl -w

package Lab::Connection;
our $VERSION = '2.92';

use strict;

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function

use Carp;
use Data::Dumper;
our $AUTOLOAD;


our @ISA = ();


our %fields = (
	connection_handle => undef,
	bus => undef, # set default here in child classes, e.g. bus => "GPIB"
	bus_class => undef,
	config => undef,
	type => undef,	# e.g. 'GPIB'
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

	return $self;
}



#
# generic methods - interface definition
#


sub Clear {
	my $self=shift;
	
	return $self->bus()->connection_clear($self->connection_handle()) if ($self->bus()->can('connection_clear'));
	# error message
	warn "Clear function is not implemented in the bus ".ref($self->bus())."\n"  . Lab::Exception::Base::Appendix();
}


sub Write {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }
	
	return $self->bus()->connection_write($self->connection_handle(), $options);
}


sub Read {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }

	return $self->bus()->connection_read($self->connection_handle(), $options);
}


sub BrutalRead {
	my $self=shift;
	my $options=undef;
	if (ref $_[0] eq 'HASH') { $options=shift }
	else { $options={@_} }
	$options->{'brutal'} = 1;
	
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
		$self->_setbus();
	}
}


#
# Method to handle bus creation generically. This is called by _construct().
# If the following (rather simple code) doesn't suit your child class, or your need to
# introduce more thorough parameter checking and/or conversion, overwrite it - _construct()
# calls it only if it is called by the topmost class in the inheritance hierarchy itself.
#
# set $self->connection_handle
#
sub _setbus { # $self->setbus() create new or use existing bus
	my $self=shift;
	my $bus_class = $self->bus_class();

	$self->bus(eval("require $bus_class; new $bus_class(\$self->config());")) || Lab::Exception::Error->throw( error => "Failed to create bus $bus_class in " . __PACKAGE__ . "::_setbus.\n"  . Lab::Exception::Base::Appendix());

	# again, pass it all.
	$self->connection_handle( $self->bus()->connection_new( $self->config() ));
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
		Lab::Exception::Error->throw( error => "AUTOLOAD in " . __PACKAGE__ . " couldn't access field '${name}'.\n"  . Lab::Exception::Base::Appendix());
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


=pod

=encoding utf-8


=head1 NAME

Lab::Connection - connection base class

=head1 SYNOPSIS

This is the base class for all connections.
Every inheriting classes constructors should start as follows:

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = $class->SUPER::new(@_);
		$self->_construct(__PACKAGE__); #initialize fields etc.
		...
	}

=head1 DESCRIPTION

C<Lab::Connection> is the base class for all connections and implements a generic set of 
access methods. It doesn't do anything on its own.

A connection in general is an object which is created by an instrument and provides it 
with a generic set of methods to talk to its hardware counterpart.
For example L<Lab::Instrument::HP34401A> can work with any connection of the type GPIB, 
that is, connections derived from Lab::Connection::GPIB.

That would be, for example
  Lab::Connection::LinuxGPIB
  Lab::Connection::VISA_GPIB

Towards the instrument, these look the same, but they work with different drivers/backends.


=head1 CONSTRUCTOR

=head2 new

Generally called in child class constructor:

 my $self = $class->SUPER::new(@_);

Return blessed $self, with @_ accessible through $self->Config().

=head1 METHODS

=head2 Clear

Try to clear the connection, if the bus supports it.

=head2 Read

  my $result = $connection->Read();
  my $result = $connection->Read( timeout => 30 );

  configuration hash options:
   brutal => <1/0>   # suppress timeout errors if set to 1
   read_length => <int>   # how many bytes/characters to read
   ...see bus documentation

Reads a string from the connected device. In this basic form, its merely a wrapper to the
method connection_read() of the used bus.
You can give a configuration hash, which options are passed on to the bus.
This hash is also meant for options to Read itself, if need be.

=head2 Write

  $connection->Write( command => '*CLS' );

  configuration hash options:
   command => <command string>
   ...more (see bus documentation)

Write a command string to the connected device. In this basic form, its merely a wrapper to the
method connection_write() of the used bus.
You need to supply a configuration hash, with at least the key 'command' set.
This hash is also meant for options to Read itself, if need be.

=head2 Query

  my $result = $connection->Query( command => '*IDN?' );

  configuration hash options:
   command => <command string>
   wait_query => <wait time between read and write in usec>   # overwrites the connection default
   brutal => <1/0>   # suppress timeout errors if set to true
   read_length => <int>   # how many bytes/characters to read
   ...more (see bus documentation)

Write a command string to the connected device, and immediately read the response.

You need to supply a configuration hash with at least the 'command' key set.
The wait_query key sets the time to wait between read and write in usecs.
The hash is also passed along to the used bus methods.

=head2 BrutalRead

The same as read with the 'brutal' option set to 1.

=head2 BrutalQuery

The same as Query with the 'brutal' option set to 1.

=head2 LongQuery

The same as Query with 'read_length' set to 10240.


=head2 config

Provides unified access to the fields in initial @_ to all the cild classes.
E.g.

 $GPIB_Address=$instrument->Config(gpib_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_Address = $connection->Config()->{'gpib_address'};
 
=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection::GPIB>

=item * L<Lab::Connection::VISA_GPIB>

=item * L<Lab::Connection::MODBUS>

=item and all the others...

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut


1;
