package Lab::GenericIO;

our $VERSION='3.512';

use Devel::StackTrace;
use Lab::Generic;
use Lab::GenericIO::STDoutHandle;
use Lab::GenericIO::STDerrHandle;

our $DEFAULT = 'Term';

our $IO_CHANNELS;
$IO_CHANNELS->{MESSAGE} = [];
$IO_CHANNELS->{ERROR} = [];
$IO_CHANNELS->{WARNING} = [];
$IO_CHANNELS->{DEBUG} = [];
$IO_CHANNELS->{PROGRESS} = [];
# init
if (defined ${Lab::Generic::CLOptions::IO_INTERFACE}) {
	init(${Lab::Generic::CLOptions::IO_INTERFACE});
}
else {
	init($DEFAULT);	
}


sub init {

	# load and bind default interfaces:
	my $interface = shift;
	
	$interface = interface_load($interface);

	interface_bind($interface);

	$SIG{__WARN__} = sub {
	    my $message = shift;
	    channel_write("WARNING", undef, $message);
	};

	#Backup STDOUT and STDERR:
	our $STDOUT = *STDOUT;
	our $STDERR = *STDERR;

	#tie STDOUT AND STDERR to custom handles:

	tie *OUT_HANDLE, 'Lab::GenericIO::STDoutHandle';
	*STDOUT = *OUT_HANDLE;

	tie *ERR_HANDLE, 'Lab::GenericIO::STDerrHandle';
	*STDERR = *ERR_HANDLE;
}

# interface_load: import, create and return interface from class
sub interface_load {
	my $class = shift;

	$class = 'Lab::IO::Interface::'.$class;

	eval "require $class; $class->import(); 1;"
		or die "Could not load interface class $class\n($@)\n";
	return $class->new();
}

# interface_bind: bind all available interface channels to IO_CHANNELS
sub interface_bind {
	my $interface = shift;
	for my $chan (keys %{$IO_CHANNELS}) {
	  if ($interface->valid_channel($chan)) {
		  channel_bind_interface($chan, $interface);
		}
	}
}

# channel_bind_interface: bind interface to single channel
sub channel_bind_interface {
	my $chan = shift;
	my $interface = shift;
	if (not defined $chan || not defined $interface) {print "CBI-01: Missing arguments!\n"; return;}

  if (exists $IO_CHANNELS->{$chan}) {
    if ($interface->valid_channel($chan)) {
			push (@{$IO_CHANNELS->{$chan}}, $interface);
		}
		else {print "CBI-03: Interface $interface doesn't support $chan!"; return;}
  }
  else {print "CBI-02: Channel $chan doesn't exist!"; return;}
}

# channel_write: create DATA object -> channel_data_write (chan, DATA)
sub channel_write {
  my $chan = shift;

	if($chan eq 'DEBUG' && !$Lab::Generic::CLOptions::DEBUG) {return;}

	my $DATA = data_prepare(@_); # supply everything including $self!
	if (not defined $DATA || ref($DATA) ne 'HASH') {print "CW-01: Oops!"; return;} # ...?

	channel_data_write($chan, $DATA);

	if ($chan eq 'ERROR') {exit;}
}

# channel_data_write: send DATA object to channel
sub channel_data_write {
	my $chan = shift;
	my $DATA = shift;
	if (not defined $chan || not defined $DATA) {print "CDW-01: Missing arguments!\n"; return;}

  if (exists $IO_CHANNELS->{$chan}) {
		foreach my $interface (@{$IO_CHANNELS->{$chan}}) {
		  $interface->receive($chan, $DATA);
		}
  }
	else {print "CW-02: Channel $chan doesn't exist!"; return;}
}

# out_prepare: return DATA object
sub data_prepare {
  my $object = shift;
	my ($msg, $class, $tail) = Lab::Generic->_check_args(\@_, ['msg', 'class']);

	my $base_class = "Lab::IO::Data";
	my $DATA;
	# Case A: custom class
	if (defined $class) {
	  $class = $base_class."::".$class;
	  my $require = $class =~ /^(\S+)(::\w+)$/ ? $1 : $class;
		eval "require $require; $require->import(); 1;";
		# Error -> revert to base class
		if($@) {
		  $msg = "Could not load custom data class $class (from $require): $@";
			undef $class;
		}
		# OK -> create custom object
		else {
			$DATA = $class->new();
		}
	}
	# Case B: generic class (explicit complementary IF on purpose -> catches error in A)
	if (not defined $class) {
	  my $trace = $DATA->{trace} = new Devel::StackTrace();
	  eval "require $base_class; $base_class->import(); 1;" or die "Could not load base data class $base_class\n($@): $msg\n";
	  $DATA = $base_class->new();
	}
	# DATA object exists in any case -> pass msg / params
	if (defined $msg) {$DATA->{msg} = $msg;}
	if (defined $tail) {$DATA->{data} = $tail;}
	# Object & Caller
	$DATA->{object} = $object;
	($DATA->{package}, $DATA->{filename}, $DATA->{line}, $DATA->{subroutine}) = caller(2); # +1 out_prepare; +1 out_channel
	# Create Stacktrace
	$DATA->{trace} = new Devel::StackTrace(
		ignore_package => ['Lab::GenericIO', 'Lab::Generic', 'Lab::GenericIO::STDoutHandle', 'Lab::GenericIO::STDerrHandle']
		);

	# Done
	return $DATA;
}

1;
