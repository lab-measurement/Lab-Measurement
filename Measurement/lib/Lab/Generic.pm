package Lab::Generic;

our $VERSION = '3.31';

use strict;
use Term::ReadKey;

our @OBJECTS = ();

sub new { 
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self={};
	push(@OBJECTS, $self);
	
	bless ($self, $class);
	return $self;
}

sub set_name {
	my $self = shift;	
	my ($name) = $self->_check_args( \@_, ['name'] );
	$self->{name} = $name;	
}

sub get_name {
	my $self = shift;
	return $self->{name};	
}

sub abort {}

sub print {
	my $self = shift;
	my @data = @_;
	my ($package, $filename, $line, $subroutine) = caller(1);
	
	if ( ref(@data[0]) eq 'HASH' )
		{
		while ( my ($k,$v) = each %{@data[0]} ) 
			{
			my $line = "$k => ";
			$line.= $self->print($v);
			if ($subroutine =~ /print/)
				{
				return $line;
				}
			else
				{
				print $line."\n";
				}
			}
		}
	elsif ( ref(@data[0]) eq 'ARRAY' )
		{
		my $line ="[";
		foreach (@{@data[0]})
			{
			$line .= $self->print($_);
			$line .= ", ";
			}
		chop ($line);
		chop ($line);
		$line .= "]";
		if ($subroutine =~ /print/)
				{
				return $line;
				}
			else
				{
				print $line."\n";
				}
		}
	else
		{
		if ($subroutine =~ /print/)
				{
				return @data[0];
				}
			else
				{
				print @data[0]."\n";
				}
		}	
		
}


# IO Channel Output: prepare and forward data to channel
sub out_channel {		
  my $self = shift;
	my $chan = shift;  
	
	Lab::GenericIO::channel_write($chan, $self, @_);
}
# IO Channel aliases
sub out_message {
  my $self = shift;
	$self->out_channel('MESSAGE', @_);  
}
sub out_error {
  my $self = shift;
  $self->out_channel('ERROR', @_);
}
sub out_warning {
  my $self = shift;
 $self->out_channel('WARNING', @_);
}
sub out_debug {
  my $self = shift;
	$self->out_channel('DEBUG', @_);
}

sub _check_args {
	my $self = shift;
	my $args = shift;
	my $params = shift;
	
	my $arguments = {};

	my $i = 0;
	foreach my $arg (@{$args}) 
	{
		if ( ref($arg) ne "HASH" )
			{
			if ( defined @{$params}[$i] )
				{
				$arguments->{@{$params}[$i]} = $arg;				
				}
			$i++;
			}
		else
			{
			%{$arguments} = (%{$arguments}, %{$arg});
			$i++;
			}
	}

			
	my @return_args = ();
	
	foreach my $param (@{$params}) 
		{
		if (exists $arguments->{$param}) 
			{
			push (@return_args, $arguments->{$param});
			delete $arguments->{$param};
			}
		else
			{
			push (@return_args, undef);
			}
		}

	foreach my $param ('from_device', 'from_cache') 	# Delete Standard option parameters from $arguments hash if not defined in device driver function
		{
		if (exists $arguments->{$param}) 
			{
			delete $arguments->{$param};
			}
		}
		

	push(@return_args, $arguments);
	# if (scalar(keys %{$arguments}) > 0) 
		# {
		# my $errmess = "Unknown parameter given in $self :";
		# while ( my ($k,$v) = each %{$arguments} ) 
			# {
			# $errmess .= $k." => ".$v."\t";
			# }
		# print Lab::Exception::Warning->new( error => $errmess);
		# }
			
	return @return_args;
}
	
sub my_sleep {
	my $sleeptime = shift;
	my $self = shift;
	my $user_command = shift;
	if ( $sleeptime >= 5 )
		{
		countdown($sleeptime*1e6, $self, $user_command); 
		}
	else
		{
		usleep($sleeptime*1e6)
		}
}

sub my_usleep {
	my $sleeptime = shift;
	my $self = shift;
	my $user_command = shift;
	if ( $sleeptime >= 5 )
		{
		countdown($sleeptime, $self, $user_command); 
		}
	else
		{
		usleep($sleeptime)
		}
}

sub countdown {
	my $self = shift;
	my $duration = shift;	
	my $user_command = shift;

	ReadMode('cbreak');

	$duration /= 1e6;	
	my $hours = int($duration/3600);
	my $minutes = int(($duration-$hours*3600)/60);
	my $seconds = $duration -$hours*3600 - $minutes*60;

	my $t_0 = time();

	local $| = 1;

	my $message = "Waiting for ";

	if ($hours > 1) { $message .= "$hours hours "; } 
	elsif ($hours == 1) { $message .= "one hour "; } 
	if ($minutes > 1) { $message .= "$minutes minutes "; } 
	elsif ($minutes == 1) { $message .= "one minute "; } 
	if ($seconds > 1) { $message .= "$seconds seconds "; }
	elsif ($seconds == 1) { $message .= "one second "; } 

	$message .= "\n";

	print $message;

	while (($t_0+$duration-time()) > 0) {

		my $char = ReadKey(1);
		
		if (defined($char) && $char eq 'c') {
			last;
		}
		elsif ( defined($char) )
			{
			if (defined $user_command)
				{
				$user_command->($self, $char);
				}
			else
				{
				user_command($char);
				}
			}
		
		my $left = ($t_0+$duration-time());
		my $hours = int($left/3600);
		my $minutes = int(($left-$hours*3600)/60);
		my $seconds = $left -$hours*3600 - $minutes*60;
		
		print sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
		print "\r";
		#sleep(1);
	
	}  
	ReadMode('normal');
	$| = 0;
	print "\n\nGO!\n";
	
}

sub timestamp {

	my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat,
    $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime(time);
	
	$Monat+=1;
	$Jahrestag+=1;
	$Monat = $Monat < 10 ? $Monat = "0".$Monat : $Monat;
	$Monatstag = $Monatstag < 10 ? $Monatstag = "0".$Monatstag : $Monatstag;
	$Stunden = $Stunden < 10 ? $Stunden = "0".$Stunden : $Stunden;
	$Minuten = $Minuten < 10 ? $Minuten = "0".$Minuten : $Minuten;
	$Sekunden = $Sekunden < 10 ? $Sekunden = "0".$Sekunden : $Sekunden;
	$Jahr+=1900;
	
	return   "$Monatstag.$Monat.$Jahr", "$Stunden:$Minuten:$Sekunden";

}

sub seconds2time {
	my $duration = shift;
	
	my $hours = int($duration/3600);
	my $minutes = int(($duration-$hours*3600)/60);
	my $seconds = $duration -$hours*3600 - $minutes*60;
	
	my $formated = $hours."h ".$minutes."m ".$seconds."s ";
	
	
	return $formated;
}


package Lab::GenericSignals;

use sigtrap 'handler' => \&abort_all, qw(normal-signals error-signals);

sub abort_all {  
  foreach my $object (@{Lab::Generic::OBJECTS}) {
		$object->abort();		
	}
	@{Lab::Generic::OBJECTS} = ();	
}

END {  
  abort_all();
}

package Lab::GenericIO;

use Devel::StackTrace;

our $DEFAULT = 'Lab::IO::Interface::Term';

our $IO_CHANNELS;
$IO_CHANNELS->{MESSAGE} = [];
$IO_CHANNELS->{ERROR} = [];
$IO_CHANNELS->{WARNING} = [];
$IO_CHANNELS->{DEBUG} = [];
$IO_CHANNELS->{PROGRESS} = [];

init();

# init
sub init {  

	# load and bind default interfaces:
	my $interface = interface_load($DEFAULT);
	interface_bind($interface);

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
	
	my $DATA = data_prepare(@_); # supply everything including $self!
	if (not defined $DATA || ref($DATA) ne 'HASH') {print "CW-01: Oops!"; return;} # ...?	
	
	channel_data_write($chan, $DATA);
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
	my ($msg, $class, $params, $options) = Lab::Generic->_check_args(\@_, ['msg', 'class', 'params', 'options']);
	
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
			undef $params;
		}
		# OK -> create custom object
		else {		  
			$DATA = $class->new();
		}
	}
	# Case B: generic class (explicit complementary IF on purpose -> catches error in A)
	if (not defined $class) {
	  eval "require $base_class; $base_class->import(); 1;" or die "Could not load base data class $base_class\n($@)\n";
	  $DATA = $base_class->new();
	}
	# DATA object exists in any case -> pass msg / params
	if (defined $msg) {$DATA->{msg} = $msg;}
	if (defined $params) {$DATA->{params} = $params;}	
	if (defined $options) {$DATA->{options} = $options;}
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

# Handle to replace STDOUT (routes messages on STDOUT to MESSAGE channel):
package Lab::GenericIO::STDoutHandle;

use Symbol qw<geniosym>;

use base qw<Tie::Handle>;

sub TIEHANDLE { return bless geniosym, __PACKAGE__ }

sub PRINT {

	shift;
	my $string = join("", @_);

	Lab::GenericIO::channel_write("MESSAGE", undef, $string);
}

sub PRINTF {

	shift;
	my $format = shift;

	my $string = sprintf "$format", @_;

	Lab::GenericIO::channel_write("MESSAGE", undef, $string);
}

# Handle to replace STDERR (routes messages on STDERR to ERROR channel):
package Lab::GenericIO::STDerrHandle;

use Symbol qw<geniosym>;

use base qw<Tie::Handle>;

sub TIEHANDLE { return bless geniosym, __PACKAGE__ }

sub PRINT {

	shift;
	my $string = join("", @_);

	Lab::GenericIO::channel_write("ERROR", undef, $string);
}

sub PRINTF {

	shift;
	my $format = shift;

	my $string = sprintf "$format", @_;

	Lab::GenericIO::channel_write("ERROR", undef, $string);
}

# Process Command Line Options (i.e. flag -d | -debug):
package Lab::Generic::CLOptions;

use Getopt::Long;

our $DEBUG = 0;

GetOptions("debug|d" => \$DEBUG);

1;
