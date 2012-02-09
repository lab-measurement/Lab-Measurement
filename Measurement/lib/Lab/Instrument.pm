#!/usr/bin/perl -w
package Lab::Instrument;
use strict;
use warnings;

our $VERSION = '2.94';

use Lab::Exception;
use Lab::Connection;
use Carp qw(cluck croak);
use Data::Dumper;
use Clone qw(clone);

use Time::HiRes qw (usleep sleep);
use POSIX; # added for int() function

our @ISA = ();

our $AUTOLOAD;


our %fields = (

	device_name => undef,
	device_comment => undef,

	ins_debug => 0, # do we need additional output?

	connection => undef,
	supported_connections => [ 'ALL' ],
	# for connection default settings/user supplied settings. see accessor method.
	connection_settings => {
		connection_type => 'LinuxGPIB',	
	},

	# default device settings/user supplied settings. see accessor method.
	device_settings => {
		wait_status => 10e-6, # sec
		wait_query => 10e-6, # sec
		query_length => 300, # bytes
		query_long_length => 10240, # bytes
	},
	
	device_cache => {},

	config => {},
);



sub new { 
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $config = undef;
	if (ref $_[0] eq 'HASH') { $config=shift }
	else { $config={@_} }

	my $self={};
	bless ($self, $class);

	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	$self->config($config);

	#
	# In most inherited classes, configure() is run through _construct()
	#
	$self->${\(__PACKAGE__.'::configure')}($self->config()); # use local configure, not possibly overwritten one
	if( $class eq __PACKAGE__ ) {
		# _setconnection after providing $config - needed for direct instantiation of Lab::Instrument
		$self->_setconnection();
	}

	# digest parameters
	$self->device_name($self->config('device_name')) if defined $self->config('device_name');
	$self->device_comment($self->config('device_comment')) if defined $self->config('device_comment');

	return $self;
}



#
# Call this in inheriting class's constructors to conveniently initialize the %fields object data.
#
sub _construct {	# _construct(__PACKAGE__);
	(my $self, my $package) = (shift, shift);
	my $class = ref($self);
	my $fields = undef;
	{
		no strict 'refs';
		$fields = *${\($package.'::fields')}{HASH};
	}	


	foreach my $element (keys %{$fields}) {
		# handle special subarrays
		if( $element eq 'device_settings' ) {
			# don't overwrite filled hash from ancestor
			$self->{device_settings} = {} if ! exists($self->{device_settings});
			for my $s_key ( keys %{$fields->{'device_settings'}} ) {
				$self->{device_settings}->{$s_key} = clone($fields->{device_settings}->{$s_key});
			}
		}
		elsif( $element eq 'connection_settings' ) {
			# don't overwrite filled hash from ancestor
			$self->{connection_settings} = {} if ! exists($self->{connection_settings});
			for my $s_key ( keys %{$fields->{connection_settings}} ) {
				$self->{connection_settings}->{$s_key} = clone($fields->{connection_settings}->{$s_key});
			}
		}
		else {
			# handle the normal fields - can also be hash refs etc, so use clone to get a deep copy
			$self->{$element} = clone($fields->{$element});
		}
		$self->{_permitted}->{$element} = 1;
	}
	# @{$self}{keys %{$fields}} = values %{$fields};

	#
	# run configure() of the calling package on the supplied config hash.
	# this parses the whole config hash on every heritance level (and with every version of configure())
	# For Lab::Instrument itself it does not make sense, as $self->config() is not set yet. Instead it's run from the new() method, see there.
	#
	$self->${\($package.'::configure')}($self->config()) if $class ne 'Lab::Instrument'; # use configure() of calling package, not possibly overwritten one

	#
	# Check and parse the connection data OR the connection object in $self->config(), but only if 
	# _construct() has been called from the instantiated class (and not from somewhere up the heritance hierarchy)
	# That's because child classes can add new entrys to $self->supported_connections(), so delay checking to the top class.
	# Also, don't run _setconnection() for Lab::Instrument, as in this case the needed fields in $self->config() are not set yet.
	# It's run in Lab::Instrument::new() instead if needed.
	#
	# Also, other stuff that should only happen in the top level class instantiation can go here.
	#
	if( $class eq $package && $class ne 'Lab::Instrument' ) {
		$self->_setconnection();
		
		# Match the device hash with the device
		# The cache carries the default values set above and was possibly modified with user
		# defined values through configure() before the connection was set. These settings are now transferred
		# to the device.
		$self->_device_init(); # enable device communication if necessary
		$self->_cache_init();  # transfer configuration to/from device
	}
}


#
# Sync the field set in $self->device_cache with the device.
# Undefined fields are filled in from the device, existing values in device_cache are written to the device.
# Without parameter, parses the whole $self->device_cache. Else, the parameter list is parsed as a list of
# field names. Contained fields for which have no corresponding getter/setter/device_cache entry exists will result in an exception thrown.
#
sub _cache_init {
	my $self = shift;
	my $subname = shift;
	my @ckeys = scalar(@_) > 0 ? @_ : keys %{$self->device_cache()}; 
	
	if( $self->{'device_cache'} && $self->connection() ) {
		for my $ckey ( @ckeys ) {
			Lab::Exception::CorruptParameter->throw( "No field with name $ckey in device_cache!\n" ) if !exists $self->device_cache()->{$ckey};
			if( !defined $self->device_cache()->{$ckey}  ) {
				$subname = 'get_' . $ckey;
				Lab::Exception::CorruptParameter->throw("No get method defined for device_cache field $ckey! \n") if ! $self->can($subname);
				$self->device_cache()->{$ckey} = $self->$subname( from_device => 1 );
			}
			else {
				$subname = 'set_' . $ckey;
				Lab::Exception::CorruptParameter->throw("No set method defined for device_cache field $ckey!\n") if ! $self->can($subname);
				$self->$subname($self->device_cache()->{$ckey});
			}
		}
	}
}



#
# Sync the device cache with the device. 
# Options: 
# 	Preference of the sync: 'device' (default) or 'driver'
#	Name of variable to sync.											  
#

sub device_sync{
	my $self = shift;
	
	my $pref = shift || 'device';
	
			
	if( $self->{'device_cache'}){
		if($pref eq 'driver'){			
			if($_[0]){
				$self->${\('set_'.$_[0])}($self->{'device_cache'}->{$_[0]});
				return 1;
			}		
			else{
				my $count = 0;
				foreach my $key (keys %{$self->{'device_cache'}} ){
					$self->${\('set_'.$key)}($self->{'device_cache'}->{$key});
					$count += 1;
				}				
				return $count;
			}
		}
		else{
			if($_[0]){
				$self->{'device_cache'}->{$_[0]} = $self->${\('get_'.$_[0])}( device_cache => 1 );
				return 1;
			}
			else{
				my $count = 0;
				foreach my $key (keys %{$self->{'device_cache'}} ){
					$self->{'device_cache'}->{$key} = $self->${\('get_'.$key)}( device_cache => 1 );
					$count += 1;
				}				
				return $count;
			}
		}
	}
				

				

}



#
# Fill $self->device_settings() from config parameters
#
sub configure {
	my $self=shift;
	my $config=shift;

	if( ref($config) ne 'HASH' ) {
		Lab::Exception::CorruptParameter->throw( error=>'Given Configuration is not a hash.');
	}
	else {
		#
		# fill matching fields defined in %fields from the configuration hash ($self->config )
		# this will also catch an explicitly given device_settings, default_device_settings (see Source.pm) or connection_settings hash ( overwritten default config )
		#
		for my $fields_key ( keys %{$self->{_permitted}} ) {
			{	# restrict scope of "no strict"
				no strict 'refs';
				$self->$fields_key($config->{$fields_key}) if exists $config->{$fields_key};
			}
		}

		#
		# fill fields $self->device_settings and $self->device_cache from entries given in configuration hash (this is usually the same as $self->config )
		#
		$self->device_settings($config);
		$self->device_cache($config);
	}
}




sub _checkconnection { # Connection object or connection_type string (as in Lab::Connections::<connection_type>)
	my $self=shift;
	my $connection=shift || undef;
	my $found = 0;

	$connection = ref($connection) || $connection;

	return 0 if ! defined $connection;

	no strict 'refs';
	if( grep(/^ALL$/, @{$self->supported_connections()}) == 1 ) {
		return $connection;
	}
	else {
		for my $conn_supp ( @{$self->supported_connections()} ) {
			return $conn_supp if( $connection->isa('Lab::Connection::'.$conn_supp));
		}
	}

	return undef;
}



sub _setconnection { # $self->setconnection() create new or use existing connection
	my $self=shift;

	#
	# fill in unset connection parameters with the defaults from $self->connections_settings to $self->config
	#
	my $config = $self->config();
	my $connection_type = undef;
	my $full_connection = undef;

	for my $setting_key ( keys %{$self->connection_settings()} ) {
		$config->{$setting_key} = $self->connection_settings($setting_key) if ! defined $config->{$setting_key};
	}

	# check the configuration hash for a valid connection object or connection type, and set the connection
	if( defined($self->config('connection')) ) {
		if($self->_checkconnection($self->config('connection')) ) {
			$self->connection($self->config('connection'));
		}
		else { Lab::Exception::CorruptParameter->throw( error => "Received invalid connection object!\n" ); }
	}
#	else {
#		Lab::Exception::CorruptParameter->throw( error => 'Received no connection object!\n' );
#	}
	elsif( defined $self->config('connection_type') ) {
		$connection_type = $self->config('connection_type');

		if( $connection_type !~ /^[A-Za-z0-9_\-\:]*$/ ) { Lab::Exception::CorruptParameter->throw( error => "Given connection type is does not look like a valid module name.\n"); };

		if( $connection_type eq 'none' ) { return; };
		# todo: allow this only if the device supports connection_type none

		$full_connection = "Lab::Connection::" . $connection_type;
		eval("require ${full_connection};");
		if ($@) {
			Lab::Exception::Error->throw(
				error => 	"Sorry, I was not able to load the connection ${full_connection}.\n" .
							"The error received from the connections was\n===\n$@\n===\n"
			);
		}

		if($self->_checkconnection("Lab::Connection::" . $connection_type)) {

			# let's get creative
			no strict 'refs';

			# yep - pass all the parameters on to the connection, it will take the ones it needs.
			# This way connection setup can be handled generically. Conflicting parameter names? Let's try it.
			$self->connection( $full_connection->new ($config) ) || Lab::Exception::Error->throw( error => "Failed to create connection $full_connection!\n" );

			use strict;
		}
		else { Lab::Exception::CorruptParameter->throw( error => "Given Connection not supported!\n"); }
	}
	else {
		Lab::Exception::CorruptParameter->throw( error => "Neither a connection nor a connection type was supplied.\n");	}
}


sub _checkconfig {
	my $self=shift;
	my $config = $self->config();

	return 1;
}


#
# To be overwritten...
# Returned $errcode has to be 0 for "no error"
#
sub get_error {
	my $self=shift;
	
	# overwrite with device specific error retrieval...
	
	return (0, undef); # ( $errcode, $message )
}

#
# Optionally implement this to return a hash with device specific named status bits for this device, e.g. from the status byte/serial poll for GPIB
# return { ERROR => 1, READY => 1, DATA => 0, ... }
#
sub get_status {
	my $self=shift;
	Lab::Exception::Unimplemented->throw( "get_status() not implemented for " . ref($self) . ".\n" );
	return undef;
}

sub check_errors {
	my $self=shift;
	my $command=shift;
	my @errors=();
	
	if($self->get_status('ERROR')) {
	
		my ( $code, $message )  = $self->get_error();	
		while( $code != 0 ) {
			push @errors, [$code, $message];
			warn "\nReceived device error with code $code\nMessage: $message\n";
			( $code, $message )  = $self->get_error();
		}

		if(@errors) {
			Lab::Exception::DeviceError->throw (
				error => 'An Error occured in the device.',
				device_class => ref $self,
				command => $command,
				error_list => \@errors,
			)
		}
	}
}

#
# Generic utility methods for string based connections (most common, SCPI etc.).
# For connections not based on command strings these should probably be overwritten/disabled!
#

#
# passing through generic write, read and query from the connection.
#

sub write {
	my $self=shift;
	my $command= scalar(@_)%2 == 0 && ref $_[1] ne 'HASH' ? undef : shift;  # even sized parameter list and second parm no hashref? => Assume parameter hash
	my $args = scalar(@_)%2==0 ? {@_} : ( ref($_[0]) eq 'HASH' ? $_[0] : undef );
	Lab::Exception::CorruptParameter->throw( "Illegal parameter hash given!\n" ) if !defined($args);

	$args->{'command'} = $command if defined $command;
	
	$self->connection()->Write($args);
	$self->check_errors($args->{'command'}) if $args->{error_check};
}


sub read {
	my $self=shift;
	my $args = scalar(@_)%2==0 ? {@_} : ( ref($_[0]) eq 'HASH' ? $_[0] : undef );
	Lab::Exception::CorruptParameter->throw( "Illegal parameter hash given!\n" ) if !defined($args);

	my $result = $self->connection()->Read($args);
	$self->check_errors('Just a plain and simple read.') if $args->{error_check};
	return $result;
}


# query( $command, { channel => 1 })
# query( $command, channel => 1 )
# query({ command => $cmd, channel => 1 })
# query( command => $cmd, channel => 1 )

# $time, $true_scalar

sub query {
	my $self=shift;
	my ($command, $args) = $self->parse_optional(@_);

	$args->{'command'} = $command if defined $command;

	my $result = $self->connection()->Query($args);
	$self->check_errors($args->{'command'}) if $args->{error_check};
	return $result;
}








#
# infrastructure stuff below
#

#
# tool function to safely handle an optional scalar parameter in presence with a parameter hash/list
# only one optional scalar parameter can be handled, and its value must not be a hashref!
#
sub parse_optional {
	my $self = shift;

	my $optional= scalar(@_)%2 == 0 && ref $_[1] ne 'HASH' ? undef : shift;  # even sized parameter list and second parm no hashref? => Assume parameter hash
	my $args = scalar(@_)%2==0 ? {@_} : ( ref($_[0]) eq 'HASH' ? $_[0] : undef );
	Lab::Exception::CorruptParameter->throw( "Illegal parameter hash given!\n" ) if !defined($args);
	
	return $optional, $args;
}



#
# accessor for device_settings
#
sub device_settings {
	my $self = shift;
	my $value = undef;
		
	#warn "device_settings got this:\n" . Dumper(@_) . "\n";

	if( scalar(@_) == 0 ) {  # empty parameters - return whole device_settings hash
		return $self->{'device_settings'};
	}
	elsif( scalar(@_) == 1 ) {  # one parm - either a scalar (key) or a hashref (try to merge)
		$value = shift;
	}
	elsif( scalar(@_) > 1 && scalar(@_)%2 == 0 ) { # even sized list - assume it's keys and values and try to merge it
		$value = {@_};
	}
	else {  # uneven sized list - don't know what to do with that one
		Lab::Exception::CorruptParameter->throw( error => "Corrupt parameters given to " . __PACKAGE__ . "::device_settings().\n" );
	}

	#warn "Keys present: \n" . Dumper($self->{device_settings}) . "\n";

	if(ref($value) =~ /HASH/) {  # it's a hash - merge into current settings
		for my $ext_key ( keys %{$value} ) {
			$self->{'device_settings'}->{$ext_key} = $value->{$ext_key} if( exists($self->device_settings()->{$ext_key}) );
		}
		return $self->{'device_settings'};
	}
	else {  # it's a key - return the corresponding value
		return $self->{'device_settings'}->{$value};
	}
}

#
# Accessor for device_cache settings
#

sub device_cache {
	my $self = shift;
	my $value = undef;
		
	#warn "device_cache got this:\n" . Dumper(@_) . "\n";

	if( scalar(@_) == 0 ) {  # empty parameters - return whole device_settings hash
		return $self->{'device_cache'};
	}
	elsif( scalar(@_) == 1 ) {  # one parm - either a scalar (key) or a hashref (try to merge)
		$value = shift;
	}
	elsif( scalar(@_) > 1 && scalar(@_)%2 == 0 ) { # even sized list - assume it's keys and values and try to merge it
		$value = {@_};
	}
	else {  # uneven sized list - don't know what to do with that one
		Lab::Exception::CorruptParameter->throw( error => "Corrupt parameters given to " . __PACKAGE__ . "::device_cache().\n" );
	}

	#warn "Keys present: \n" . Dumper($self->{device_settings}) . "\n";

	if(ref($value) =~ /HASH/) {  # it's a hash - merge into current settings
		for my $ext_key ( keys %{$value} ) {
			$self->{'device_cache'}->{$ext_key} = $value->{$ext_key} if( exists($self->device_cache()->{$ext_key}) );
		}
		return $self->{'device_cache'};
	}
	else {  # it's a key - return the corresponding value
		return $self->{'device_cache'}->{$value};
	}
}


#
# accessor for connection_settings
#
sub connection_settings {
	my $self = shift;
	my $value = undef;

	if( scalar(@_) == 0 ) {  # empty parameters - return whole device_settings hash
		return $self->{'connection_settings'};
	}
	elsif( scalar(@_) == 1 ) {  # one parm - either a scalar (key) or a hashref (try to merge)
		$value = shift;
	}
	elsif( scalar(@_) > 1 && scalar(@_)%2 == 0 ) { # even sized list - assume it's keys and values and try to merge it
		$value = {@_};
	}
	else {  # uneven sized list - don't know what to do with that one
		Lab::Exception::CorruptParameter->throw( error => "Corrupt parameters given to " . __PACKAGE__ . "::connection_settings().\n" );
	}

	if(ref($value) =~ /HASH/) {  # it's a hash - merge into current settings
		for my $ext_key ( keys %{$value} ) {
			$self->{'connection_settings'}->{$ext_key} = $value->{$ext_key} if( exists($self->{'connection_settings'}->{$ext_key}) );
			# warn "merge: set $ext_key to " . $value->{$ext_key} . "\n";
		}
		return $self->{'connection_settings'};
	}
	else {  # it's a key - return the corresponding value
		return $self->{'connection_settings'}->{$value};
	}
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

#
# provides generic accessor methods to the fields defined in %fields and to the elements of $self->device_settings
#
sub AUTOLOAD {

	my $self = shift;
	my $type = ref($self) or croak "\$self is not an object";
	my $value = undef;

	my $name = $AUTOLOAD;
	$name =~ s/.*://; # strip fully qualified portion

	if( exists $self->{_permitted}->{$name} ) {
		if (@_) {
			return $self->{$name} = shift;
		} else {
			return $self->{$name};
		}
	}
	elsif( $name =~ qr/^(get_|set_)(.*)$/ ) {
		if(exists $self->device_settings()->{$2}){
			return $self->getset($1,$2,"device_settings",@_);
		}
		elsif(exists $self->device_cache()->{$2}){
			return $self->getset($1,$2,"device_cache",@_);
		}
		else{
			Lab::Exception::Warning->throw( error => "AUTOLOAD could not find var for getter/setter: $name \n");
		}
	}
	elsif( exists $self->{'device_settings'}->{$name} ) {
		if (@_) {
			return $self->{'device_settings'}->{$name} = shift;
		} else {
			return $self->{'device_settings'}->{$name};
		}
	}
	else {
		Lab::Exception::Warning->throw( error => "AUTOLOAD in " . __PACKAGE__ . " couldn't access field '${name}'.\n" );
	}
}

# needed so AUTOLOAD doesn't try to call DESTROY on cleanup and prevent the inherited DESTROY
sub DESTROY {
        my $self = shift;
	#$self->connection()->DESTROY();
        $self -> SUPER::DESTROY if $self -> can ("SUPER::DESTROY");
}

sub getset{
	my $self = shift;
	my $gs = shift;
	my $varname = shift;
	my $subfield = shift;
	if( $gs eq 'set_' ) {
				my $value = shift;
				if( !defined $value || ref($value) ne "" ) { Lab::Exception::CorruptParameter->throw( error => "No or no scalar value given to generic set function $AUTOLOAD in " . __PACKAGE__ . "::AUTOLOAD().\n" ); }
				if( @_ > 0 ) { Lab::Exception::CorruptParameter->throw( error => "Too many values given to generic set function $AUTOLOAD " . __PACKAGE__ . "::AUTOLOAD().\n" ); }
				return $self->{$subfield}->{$varname} = $value;
			}
			else {
				if( @_ > 0 ) { Lab::Exception::CorruptParameter->throw( error => "Too many values given to generic get function $AUTOLOAD " . __PACKAGE__ . "::AUTOLOAD().\n" ); }
				return $self->{$subfield}->{$varname};
			}
}

#
# This is a hook which is called after connection initialization and before the device cache is synced (see _construct).
# Necessary for some devices to put them into e.g. remote control mode or otherwise enable communication.
# Overwrite this if needed.
#
sub _device_init {
} 


#
# This tool just returns the index of the element in the provided list
#

sub function_list_index{
 1 while $_[0] ne pop; 
 $#_;
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



=pod

=encoding utf-8

=head1 NAME

Lab::Instrument - instrument base class

=head1 SYNOPSIS

Lab::Instrument is meant to be used as a base class for inheriting instruments.
For very simple applications it can also be used directly, like

  $generic_instrument = new Lab::Instrument ( connection_type => VISA_GPIB, gpib_address => 14 );
  my $idn = $generic_instrument->query('*IDN?');

Every inheriting class constructor should start as follows:

  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    $self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);  # check for supported connections, initialize fields etc.
    ...
  }

Beware that only the first set of parameters specific to an individual GPIB board 
or any other bus hardware gets used. Settings for EOI assertion for example.

If you know what you're doing or you have an exotic scenario you can use the connection 
parameter "ignore_twins => 1" to force the creation of a new bus object, but this is discouraged
- it will kill bus management and you might run into hardware/resource sharing issues.



=head1 DESCRIPTION

C<Lab::Instrument> is the base class for Instruments. It doesn't do much by itself, but
is meant to be inherited in specific instrument drivers.
It provides general C<read>, C<write> and C<query> methods and basic connection handling 
(internal, C<_set_connection>, C<_check_connection>).


=head1 CONSTRUCTOR

=head2 new

This blesses $self (don't do it yourself in an inheriting class!), initializes the basic "fields" to be accessed
via AUTOLOAD and puts the configuration hash in $self->config to be accessed in methods and inherited
classes.

Arguments: just the configuration hash (or even-sized list) passed along from a child class constructor.

=head1 METHODS

=head2 write

 $instrument->write($command <, {optional hashref/hash}> );
 
Sends the command C<$command> to the instrument. An option hash can be supplied as second or also as only argument.
Generally, all options are passed to the connection/bus, so additional named options may be supported based on the connection and bus
and can be passed as a hashref or hash. See L<Lab::Connection>.
 
Optional named parameters for hash:
error_check => 1/0	Invoke $instrument->check_errors after write. Default off.

=head2 read

 $result=$instrument->read({ read_length => <max length>, brutal => <1/0>);

Reads a result of C<ReadLength> from the instrument and returns it.
Returns an exception on error.

If the parameter C<brutal> is set, a timeout in the connection will not result in an Exception thrown,
but will return the data obtained until the timeout without further comment.
Be aware that this data is also contained in the the timeout exception object (see C<Lab::Exception>).

Generally, all options are passed to the connection/bus, so additional named options may be supported based on the connection and bus
and can be passed as a hashref or hash. See L<Lab::Connection>.

=head2 query

 $result=$instrument->query({ command => $command,
 	                          wait_query => $wait_query,
                              read_length => $read_length);

Sends the command C<$command> to the instrument and reads a result from the
instrument and returns it. The length of the read buffer is set to C<read_length> or to the
default set in the connection.

Waits for C<wait_query> microseconds before trying to read the answer.

Generally, all options are passed to the connection/bus, so additional named options may be supported based on the connection and bus
and can be passed as a hashref or hash. See L<Lab::Connection>.


=head2 WriteConfig

this is NOT YET IMPLEMENTED in this base class so far

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

=head2 get_error

	($errcode, $errmsg) = $instrument->get_error();

Method stub to be overwritten. Implementations read one error (and message, if available) from
the device.

=head2 get_status

	$status = $instrument->get_status();
	if( $instrument->get_status('ERROR') ) {...}
	
Method stub to be overwritten.
This returns the status reported by the device (e.g. the status byte retrieved via serial poll from
GPIB devices). When implementing, use only information which can be retrieved very fast from the device,
as this may be used often. 

Without parameters, has to return a hashref with named status bits, e.g.

$status => {
	ERROR => 1,
	DATA => 0,
	READY => 1
}

If present, the first argument is interpreted as a key and the corresponding value of the hash above is
returned directly.

The 'ERROR'-key has to be implemented in every device driver!


=head2 check_errors

	$instrument->check_errors($last_command);
	
	# try
	eval { $instrument->check_errors($last_command) };
	# catch
	if ( my $e = Exception::Class->caught('Lab::Exception::DeviceError')) {
		warn "Errors from device!";
		@errors = $e->error_list();
		@devtype = $e->device_class();
		$command = $e->command();		
	}

Uses get_error() to check the device for occured errors. Reads all present errors and throws a
Lab::Exception::DeviceError. The list of errors, the device class and the last issued command(s)
(if the script provided them) are enclosed.

=head1 CAVEATS/BUGS

Probably many, with all the porting. This will get better.

=head1 SEE ALSO

=over 4

=item * L<Lab::Bus>

=item * L<Lab::Connection>

=item * L<Lab::Instrument::HP34401A>

=item * L<Lab::Instrument::HP34970A>

=item * L<Lab::Instrument::Source>

=item * L<Lab::Instrument::Yokogawa7651>

=item * and many more...

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2004-2006 Daniel Schröer <schroeer@cpan.org>, 
           2009-2010 Daniel Schröer, Andreas K. Hüttel (L<http://www.akhuettel.de/>) and David Kalok,
           2010      Matthias Völker <mvoelker@cpan.org>
           2011      Florian Olbrich, Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

