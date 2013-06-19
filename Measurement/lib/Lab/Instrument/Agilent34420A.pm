package Lab::Instrument::Agilent34420A;
our $VERSION = '3.19';

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our @ISA = ("Lab::Instrument");

our %fields = (
	supported_connections => [ 'VISA', 'VISA_GPIB', 'GPIB', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
		timeout => 2,
	},

	device_settings => { 
		pl_freq => 50,
	},
	
	device_cache =>{
		id => "Agilent34420A",
		# TO DO: add range and resolution + get/setter
	}

);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	return $self;
}

sub _device_init {
	my $self = shift;
	
	$self->write("InPut:FILTer:STATe OFF");
}

sub get_error {
    my $self=shift;
    chomp(my $err=$self->query("SYSTem:ERRor?"));
    my ($err_num,$err_msg)=split ",",$err;
    $err_msg=~s/\"//g;
	my $result;
	$result->{'err_num'} = $err_num;
	$result->{'err_msg'} = $err_msg;
    return $result;
}

sub reset { # basic
    my $self=shift;
    $self->write("*RST");
}

sub selftest {
	my $self = shift;
	
	# internal selftest:
	# returns 0 if passed and 1 if failed
	
	$self->write("*TST?");
	usleep(10e6);
	return $self->read();	
}


# ------------------------------- sense ---------------------------------------------------------


sub set_function { # basic
	my $self = shift;
	my ($function) = $self->_check_args( \@_, ['function'] );
	
	# \nAgilent 34420A:\n
	# Expected values for function are:\n
	# voltage:dc, voltage:dc:ratio, voltage:dc:difference, resistance or Fresistance --> to set both input channels\n
	# sense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\n
	# sense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n
	# 
	
	if (not defined $function)
		{
		$function = $self->query("FUNCTION?");
		if ( $function =~ /([\w:]+)/ ) {$self->{config}->{function} = $1; return $1;}
		}
		
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	# check if a specific channel was selected
	my $channel;
	if ($function =~ /^(sense1):(.*)/)
		{
		$channel = "sense1:";
		$function = $2;
		$self->set_channel(1);
		}
	elsif ($function =~ /^(sense2):(.*)/)
		{
		$channel = "sense2:";
		$function = $2;
		$self->set_channel(2);
		}
	
	
	if ($function =~ /^(voltage:dc|voltage|volt:dc|volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/ or $function =~ /^(resistance|fresistance|res|fres)$/)
		{
		$function = $self->query(sprintf("FUNCTION '%s'; FUNCTION?", $function));
		if ( $function =~ /([\w:]+)/ ) {$self->{config}->{function} = $1; return "$channel$1";}	
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for FUNCTION in sub set_function. Expected values are:\nvoltage:dc, resistance or Fresistance --> to set both input channels\nsense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\nsense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n");
		}
	
	
}

sub get_function {
	my $self = shift;
	return $self->set_function();
}

sub set_range { # basic
	my $self = shift;
	my ($function, $range) = $self->_check_args( \@_, ['function', 'range'] );
	
	
	# \nAgilent 34420A:\n
	# Expected values for function are:\n
	# voltage:dc, voltage:dc:ratio, voltage:dc:difference, resistance or Fresistance --> to set both input channels\n
	# sense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\n
	# sense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n
	# 
	# Expected values for RANGE are:\n
	# sense1:voltage:dc --> 1mV...100V 
	# sense2:voltage:dc --> 1mV...10V
	# resistance and Fresistance -->  1...1e6 Ohm
	
	
	if ( not defined $function  and not defined $range)
		{
		$function = $self->set_function();
		$range = $self->query(sprintf("%s:RANGE?", $function));
		$self->{config}->{range} = $range;
		return $range;
		}
		
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	if ( ($function =~ /^(voltage:dc|voltage|volt:dc|volt|sense1:voltage:dc|sense1:voltage|sense1:volt:dc|sense1:volt|sense2:voltage:dc|sense2:voltage|sense2:volt:dc|sense2:volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/ or $function =~ /^(resistance|fresistance|res|fres)$/) and not defined $range)
		{
		$range = $self->query(sprintf("%s:RANGE?", $function));
		$self->{config}->{range} = $range;
		return $range;
		}
	
	# check data
	if ( $function =~ /^(voltage:dc|voltage|volt:dc|volt|sense1:voltage:dc|sense1:voltage|sense1:volt:dc|sense1:volt|sense2:voltage:dc|sense2:voltage|sense2:volt:dc|sense2:volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/ ) {
		if ( abs($range) > 100 ) {
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for RANGE in sub set_range. Expected values are for sense1:voltage:dc  1mV...100V and for sense2:voltage:dc 1mV...10V\n");
		}
	}
	elsif ( $function =~ /^(resistance|fresistance|res|fres)$/) {
		if ( $range < 0 or $range > 1e6 ) {
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for RANGE in sub set_range. Expected values are for resistance and Fresistance mode  1...1e6 Ohm.");
		}
	}
	else {
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for FUNCTION in sub set_range. Expected values are:\nvoltage:dc, resistance or Fresistance --> to set both input channels\nsense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\nsense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n");
		}
	
	# set range
	if ( $range =~ /^(MIN|min|MAX|max|DEF|def)$/) {		
		$range = $self->query(sprintf("%s:RANGE %s; RANGE?", $function, $range));
		$self->{config}->{range} = $range;
		return $range;
	}
	elsif ($range =~ /^(AUTO|auto)$/) {
		$range = "RANGE=AUTO , ".$self->query(sprintf("%s:RANGE:AUTO ON; RANGE?", $function));
		$self->{config}->{range} = $range;
		return $range;
	}
	else {
		$range = $self->query(sprintf("%s:RANGE %e; RANGE?", $function, $range));
		$self->{config}->{range} = $range;
		return $range;
	}
		
	

}

sub set_nplc { # basic
	my $self = shift;
	my ($function, $nplc) = $self->_check_args( \@_, ['function', 'nplc'] );
	
	# Agilent 34420A:\n
	# Expected values for function are:\n
	# voltage:dc, voltage:dc:ratio, voltage:dc:difference, resistance or Fresistance --> to set both input channels\n
	# sense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\n
	# sense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n
	# 
	# Agilent 34420A:
	# unexpected value for NPLC in sub set_nplc. 
	# Expected values are between 0.02 ... 200 power-line-cycles (50Hz).
	
	if ( not defined $function  and not defined $nplc)
		{
		$function = $self->set_function();
		}
	elsif ( not defined $nplc and $function =~ /^([+-]?([0-9]+)(\.[0-9]+)?((e|E)([+-]?[0-9]+))?)$/ )
		{
		$nplc = $function;
		$function = $self->set_function();
		}
	
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	if ( $function =~ /AC|ac/ )
		{
		warn "WARNING: cannot set nplc for ".$self->get_id()." in ac measurement mode.";
		return;
		}
	
	if (($function =~ /^(voltage:dc|voltage|volt:dc|volt|sense1:voltage:dc|sense1:voltage|sense1:volt:dc|sense1:volt|sense2:voltage:dc|sense2:voltage|sense2:volt:dc|sense2:volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/ or $function =~ /^(resistance|fresistance|res|fres)$/) and not defined $nplc)
		{
		$nplc = $self->query(sprintf("%s:NPLC?", $function));
		$self->{config}->{nplc} = $nplc;
		return $nplc;
		}
	
	if ( $function =~  /^(voltage:dc|voltage|volt:dc|volt|sense1:voltage:dc|sense1:voltage|sense1:volt:dc|sense1:volt|sense2:voltage:dc|sense2:voltage|sense2:volt:dc|sense2:volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/ or $function =~ /^(resistance|fresistance|res|fres)$/)
		{
		if ($nplc >= 0.02 and $nplc <= 200 ) #
			{
			$nplc = $self->query(sprintf("%s:NPLC %.3f; NPLC?", $function, $nplc));
			$self->{config}->{nplc} = $nplc;
			return $nplc;
			}
		elsif ($nplc =~ /^(MIN|min|MAX|max|DEF|def)$/) 
			{
			$nplc = $self->query(sprintf("%s:NPLC %s; NPLC?", $function, $nplc));
			$self->{config}->{nplc} = $nplc;
			return $nplc;
			}
		else 
			{
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for NPLC in sub set_nplc. Expected values are between 0.02 ... 200 power-line-cycles (50Hz).");
			}	
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for FUNCTION in sub set_nplc. Expected values are:\nvoltage:dc, resistance or Fresistance --> to set both input channels\nsense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\nsense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n");
		}
	
	

}

sub set_resolution{ # basic
	
	my $self = shift;
	my ($function, $resolution) = $self->_check_args( \@_, ['function', 'resolution'] );
	
	# Agilent 34420A:\n
	# Expected values for FUNCTION are:\n
	# voltage:dc, voltage:dc:ratio, voltage:dc:difference, resistance or Fresistance --> to set both input channels\n
	# sense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\n
	# sense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n
	# 
	# Agilent 34420A:
	# unexpected value for resOLUTION 
	# Expected values are between 0.0001xRANGE ... 0.00000022xRANGE
	
	if ( not defined $function  and not defined $resolution)
		{
		$function = $self->set_function();
		}
	
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	if ( $function =~ /AC|ac/ )
		{
		warn "WARNING: cannot set resolution for ".$self->get_id()." in ac measurement mode.";
		return;
		}
		
		
	if (not defined $function and not defined $resolution) #return settings
		{
		$function = $self->set_function();
		$resolution = $self->query("$function:resOLUTION?");
		$self->{config}->{resolution} = $resolution;
		return $resolution;
		}
	elsif( not defined $resolution and $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/) # get selected function
		{
		$resolution = $function;
		$function = $self->set_function();
		}			
	elsif (($function =~ /^(voltage:dc|voltage|volt:dc|volt|sense1:voltage:dc|sense1:voltage|sense1:volt:dc|sense1:volt|sense2:voltage:dc|sense2:voltage|sense2:volt:dc|sense2:volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/ or $function =~ /^(resistance|fresistance|res|fres)$/) and not defined $resolution)
		{
		$resolution = $self->query(sprintf("%s:resOLUTION?", $function));
		$self->{config}->{resolution} = $resolution;
		return $resolution;
		}
		
	
	
		
	if ( $function =~ /^(voltage:dc|voltage|volt:dc|volt|sense1:voltage:dc|sense1:voltage|sense1:volt:dc|sense1:volt|sense2:voltage:dc|sense2:voltage|sense2:volt:dc|sense2:volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/ or $function =~ /^(resistance|fresistance|res|fres)$/ )
		{
		my $range = $self->set_range($function);
		$self->set_range($function, $range); # switch off autorange function if activated.
	
		if ($resolution >= 0.0001*$range and $resolution <= 0.00000022*$range ) 
			{
			$resolution = $self->query(sprintf("%s:res %.3f; res?", $function, $resolution));
			$self->{config}->{resolution} = $resolution;
			return $resolution;
			}		
		elsif ($resolution =~ /^(MIN|min|MAX|max|DEF|def)$/) 
			{
			$resolution = $self->query(sprintf("%s:res %s; res?", $function, $resolution));
			$self->{config}->{resolution} = $resolution;
			return $resolution;
			}
		else 
			{
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for resOLUTION in sub set_resolution. Expected values are between 0.0001xRANGE ... 0.0000022xRANGE.");
			}	
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for FUNCTION in sub set_resolution. Expected values are:\nvoltage:dc, resistance or Fresistance --> to set both input channels\nsense1:voltage:dc, sense1:voltage:dc:ratio, sense1:voltage:dc:difference, sense1:resistance or sense1:Fresistance --> to set input channel 1 only\nsense2:voltage:dc, sense2:voltage:dc:ratio, sense2:voltage:dc:difference, sense2:resistance or sense2:Fresistance --> to set input channel 2 only\n");
		}
	
	
	
}

sub set_channel{ # basic
	my $self = shift;
	my ($terminal) = $self->_check_args( \@_, ['channel'] );
	
	my $function = $self->set_function();
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	if ($function =~ /(voltage:dc|voltage|volt:dc|volt|sense1:voltage:dc|sense1:voltage|sense1:volt:dc|sense1:volt|sense2:voltage:dc|sense2:voltage|sense2:volt:dc|sense2:volt)/)
		{
		if (not defined $terminal)
			{
			$terminal = $self->query("ROUTE:TERMINALS?");
			$self->{config}->{terminal} = $terminal;
			return $terminal;
			}
		elsif ($terminal == 1 or $terminal == 2)
			{
			$terminal = $self->query(sprintf("ROUTE:TERMINALS FRONT%d; TERMINALS?",$terminal));
			$self->{config}->{terminal} = $terminal;
			return $terminal;
			}
		else
			{
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for CHANNEL in sub set_channel. Expected values are:\n 1 --> for channel 1\n 2 --> for channel 2\n");
			}
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "Can't route CHANNEL in resistance/Fresistance mode.");
		}	
	
}

sub set_averaging { # to be implemented
	my $self = shift;
	my $value = shift;

#INPut:FILTer
#:STATe {OFF|ON}
#:TYPE {ANAlog | DIGital | BOTH}
#:DIGital:resPonse {SLOW|MEDium|FAST}
#:DIGital:PRECharge {ON | OFF}
}



# ----------------------------- TAKE DATA ---------------------------------------------------------


sub get_value { # basic
	my $self = shift;

	my ($channel, $function, $range, $int_value,  $read_mode) = $self->_check_args( \@_, ['channel', 'function', 'range', 'int_value',  'read_mode'] );
	
	my $cmd;
	
	# fast measuremnt:
	# --------------------------------------------- #
	# if ( not defined $function && not defined $range && not defined $int_value)
		# {
		# $self->{value} = $self->query(":READ?");
		# return $self->{value};
		# }
		
		
	# measure with specific settings:
	# --------------------------------------------- #
	
	#$range = 'DEF' unless (defined $range);	
	#$int_value = 'DEF' unless (defined $int_value);					
	#$function = $self->get_function() unless (defined $function);
	if($read_mode eq 'cache' and defined $self->{'device_cache'}->{'value'})
		{
     	return $self->{'device_cache'}->{'value'};
		}
	elsif ( $read_mode eq 'fetch' and $self->{'request'} == 1 )
		{
		$self->{'request'} = 0;
		return $self->device_cache()->{value} = $self->read();
		}
		
	if (defined $channel) {
		$self->set_channel($channel);
	}
	if (defined $function) 
		{
		$function =~ s/\s+//g; #remove all whitespaces
		$function = "\L$function"; # transform all uppercase letters to lowercase letters
		if (not $function =~ /^(voltage:dc|voltage|volt:dc|volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff|resistance|resisitance|res|res|Fresistance|fresistance|fres|fres)$/)
			{
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for FUNCTION in sub get_value. Expected values are voltage:dc|voltage|volt:dc|volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff|resistance|resisitance|res|res|Fresistance|fresistance|fres|fres");
			}
		else 
			{
			$cmd .= ":FUNCTION '$function';";
			}
		}
	else 
		{
		$function = $self->get_function();
		}
	# check input parameter
	
	if (defined $range) 
		{
		$range =~ s/\s+//g; #remove all whitespaces
		if ( $function =~ $function =~ /^(voltage:dc|voltage|volt:dc|volt|voltage:dc:ratio|voltage:ratio|volt:dc:ratio|volt:ratio|voltage:dc:diff|voltage:diff|volt:dc:diff|volt:diff)$/) 
			{
			if ( abs($range) > 100 and not $range =~ /^(MIN|min|MAX|max|DEF|def|AUTO|auto)$/) 
				{
				Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for RANGE in sub get_value. Expected values are for voltage and resistance mode  0.1...100V or 0...1e6 Ohms respectivly");
				}
			}
		elsif ( $function =~ /^(resistance|resisitance|res|res|Fresistance|fresistance|fres|fres)$/ ) 
			{
			if ( abs($range) > 1e6 and not $range =~ /^(MIN|min|MAX|max|DEF|def|AUTO|auto)$/) 
				{
				Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for RANGE in sub get_value. Expected values are for voltage and resistance mode  0.1...100V or 0...1e6 Ohms respectivly");
				}
			}
		else
			{
			$cmd .= ":".(split(/:/,$function))[0].":RANGE $range;";  	
			}
		}
	
	if (defined $int_value)
		{
		$int_value =~ s/\s+//g; #remove all whitespaces
		$int_value = "\L$int_value"; # transform all uppercase letters to lowercase letters
		
		if ( $int_value =~ /^(res=)(.*)/ )
			{
			$int_value = $2;
			if ( $int_value < 0.00000022*$range and not $int_value =~ /^(MIN|min|MAX|max|DEF|def)$/)
				{
				Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for resOLUTION in sub get_value. Expected values are from 0.22e-6xRANGE ... 0.0001xRANGE.");
				}
			else 
				{
				$cmd .= ":".(split(/:/,$function))[0].":RES $int_value;";
				}
			}
		elsif ( $int_value =~ /^(nplc=)(.*)/ )
			{
			$int_value = $2;
			if (  ($int_value < 0.02 or $int_value > 200) and not $int_value =~ /^(MIN|min|MAX|max|DEF|def)$/)
				{
				Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for NPLCin sub get_value. Expected values are from 0.02 ... 200.");
				}
			else 
				{
				$cmd .= ":".(split(/:/,$function))[0].":NPLC $int_value;";
				}
			}
		else
			{
			if ( ($int_value < 0.02 or $int_value > 200) and not $int_value =~ /^(MIN|min|MAX|max|DEF|def)$/)
				{
				Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for INTEGratioN TIME in sub get_value. Expected values are from 0.02 ... 200 power line cycles.");
				}
			else 
				{
				$cmd .= ":".(split(/:/,$function))[0].":NPLC $int_value;";
				}
			}
		}
	
	$cmd .= ":READ?";
	
	#print "\n\n$cmd\n\n";

		
	if($read_mode eq 'request')
		{
    	if ($self->{'request'} != 0) 
			{
    		$self->read();
			}
    	$self->write($cmd);
    	$self->{'request'} = 1;
		return undef;
		
		}
    else
		{
		$self->{'request'} = 0;
    	my $result = $self->query($cmd);
		$result =~ s/^R//;
		return $self->device_cache()->{value} = $result;	
		}
	
	
	
	
	# # check if a specific channel was selected
	# my $channel;
	# if ($function =~ /^(sense1):(.*)/)
		# {
		# $channel = ",(\@FRONT1)";
		# $function = $2;
		# $self->set_channel(1);
		# }
	# elsif ($function =~ /^(sense2):(.*)/)
		# {
		# $channel = ",(\@FRONT2)";
		# $function = $2;
		# $self->set_channel(2);
		# }
		
		
	
	# # get_value	
	# if ( $int_mode eq 'res' )
		# {
		# $self->write(":FUNCTION '$function'; :SENS:$function:ZERO:AUTO OFF; :$function:RANGE $range;  res $int_value");
		# $self->{value} = $self->query(":READ?");	
		# return $self->{value};
		# }
	# elsif ( $int_mode eq 'nplc' )
		# {
		# $self->write(":FUNCTION '$function'; :SENS:$function:ZERO:AUTO OFF; :$function:RANGE $range; NPLC $int_value");
		# $self->{value} = $self->query(":READ?");	
		# return $self->{value};
		# }
	# else
		# {
		# $self->{value} = $self->query(":READ?");	
		# return $self->{value};
		# }
			
}

sub config_measurement { # basic
	my $self = shift;
	my ($function, $nop, $nplc, $range, $trigger) = $self->_check_args( \@_, ['function', 'nop', 'nplc', 'range', 'trigger'] );
	
	# check input data
	if ( not defined $trigger )
		{
		$trigger = 'BUS';
		}
	if (not defined $range )
		{
		$range = 'DEF';
		}
	if ( not defined $nplc )
		{
		$nplc = 2;
		}
	if ( not defined $nop )
		{
		Lab::Exception::CorruptParameter->throw( error => "too view arguments given in sub config_measurement. Expected arguments are FUNCTION, #POINTS, NPLC, <RANGE>, <TRIGGERSOURCE>");
		}
	
	print "--------------------------------------\n";
	print "Agilent34410A: sub config_measurement:\n";
	
	# clear buffer
	my $points = $self->query("DATA:POINTS?");
	if ($points > 0) {
		$points = $self->{vi}->LongQuery("DATA:FETCH?");
	}	
	
	# set function
	
	print "set_function: ".$self->set_function($function)."\n";
		
	
	# set range
	print "set_range: ".$self->set_range($function,$range)."\n";
	
	
	# set nplc/tc
	print "set_nplc: ".$self->set_nplc($function,$nplc)."\n";
	my $time = $nop*$nplc/50;
	print "TIME for measurement trace => $time\n";
	
	
	# set some status registes
	$self->write("*CLS");
	$self->write("*ESE 128");
		
	# triggering
    print "set Trigger Source: ".$self->_set_triggersource("BUS")."\n";
	print "set Trigger Count: ".$self->_set_triggercount(1)."\n";
	print "set Trigger Delay: ".$self->_set_triggerdelay("MIN")."\n";
	
    print "set Sample Count: ".$self->_set_samplecount($nop)."\n";
    print "init()\n"; $self->write("INIT");
	usleep(50e3); # wait 50ms; it takes 20ms until the WAIT-FOR-TRIGGER-STATE has been setteled;

	print "Agilent34410A: sub config_measurement complete\n";
	print "--------------------------------------\n";
	
	return $time;
}

sub trg { # basic
	my $self = shift;
	$self->write("*TRG");
}

sub abort { # doesn't work, because Agilent 34420A doesn't accept any new SPCI COMMAND until last COMMAND has been completed.
	my $self=shift;
    #$self->write("ABOR"); # ??
	#$self->write("SYSTEM:LOCAL");
}

sub get_data { # basic
	my $self = shift;
	my $data;
	my @data;
	
	# wait until data are available	
	$self->write("*STB?");
	while(1) {
		eval '$self->read(100)';
		if (index($@,"Error while reading:") >= 0) {print "waiting for data ...\n";}
		else {last;}
		}
		
	# read data
	$data = $self->{vi}->LongQuery("FETC?");
	chomp $data;	
	@data = split(",",$data);	
	return @data;	
}





# ------------------ TRIGGER and SAMPLE settings ---------------------- #


sub _set_triggersource { # internal only
	my $self = shift;
	my ($source) = $self->_check_args( \@_, ['value'] );
	
	if ( not defined $source) 
		{
		$source = $self->query(sprintf("TRIGGER:SOURCE?"));
		chomp($source);
		return $source;
		}
	
	if ( $source =~/^(IMM|imm|EXT|ext|BUS|bus)$/ )
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for TRIGGER_SOURCE in sub _set_triggersource. Expected values are:\n IMM  --> immediate trigger signal\n EXT  --> external trigger\n BUS  --> software trigger signal via bus\n");
		}
	$source = $self->query(sprintf("TRIGGER:SOURCE %s; SOURCE?", $source));
	
	return $source;	
	}

sub _set_triggercount { # internal only
	my $self = shift;
	my ($count) = $self->_check_args( \@_, ['value'] );
	
	if ( not defined $count) 
		{
		$count = $self->query(sprintf("TRIGGER:COUNT?"));	
		chomp($count);
		return $count;
		}
	
	if ( $count < 0 or $count >= 50000)
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for COUNT in sub _set_triggercount. Expected values are between 1 ... 50.000\n");
		}
	
	return $self->query(sprintf("TRIGGER:COUNT %d; COUNT?", $count));	
	}
	
sub _set_triggerdelay { # internal only
	my $self = shift;
	my ($delay) = $self->_check_args( \@_, ['value'] );
	
	if ( not defined $delay) 
		{
		$delay = $self->query(sprintf("TRIGGER:DELAY?"));
		chomp($delay);
		return $delay;
		}
	
	if ( ($delay < 0 or $delay > 3600) and $delay =~ /^(MIN|min|MAX|max|DEF|def)$/)
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for DELAY in sub _set_triggerdelay. Expected values are between 1 ... 3600, or 'MIN = 0', 'MAX = 3600' or 'AUTO'\n");
		}
		
	if ( $delay =~ /^(AUTO|auto)$/)
		{
		$self->query(sprintf("TRIGGER:DELAY:AUTO ON; AUTO?", $delay));
		return "AUTO ON";
		}
	elsif ($delay =~ /^(MIN|min|MAX|max|DEF|def)$/)
		{
		return $self->query(sprintf("TRIGGER:DELAY %s; DELAY?", $delay));
		}
	else
		{
		return $self->query(sprintf("TRIGGER:DELAY %.5f; DELAY?", $delay));
		}
	}
	
sub _set_samplecount { # internal only
	my $self = shift;
	my ($count) = $self->_check_args( \@_, ['value'] );
	
	if ( not defined $count) 
		{
		$count = $self->query(sprintf("SAMPLE:COUNT?"));	
		chomp($count);
		return $count;
		}
	
	elsif ( $count < 0 or $count > 1024)
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34420A:\nunexpected value for COUNT in sub _set_samplecount. Expected values are between 1 ... 1024\n");
		}
	else
		{
		return $self->query(sprintf("SAMPLE:COUNT %d; COUNT?", $count));
		}
	}


	
	
	
# ------------------------------- DISPLAY and BEEPER --------------------------------------------


sub display_text { # basic
    my $self=shift;
    my ($text) = $self->_check_args( \@_, ['text'] );
    
    if ($text) {
        $self->write(qq(DISPlay:TEXT "$text"));
    } else {
        chomp($text=$self->query(qq(DISPlay:TEXT?)));
        $text=~s/\"//g;
    }
    return $text;
}

sub display_on { # basic
    my $self=shift;
    $self->write("DISPLAY ON");
}

sub display_off { # basic
    my $self=shift;
    $self->write("DISPLAY OFF");
}

sub display_clear { # basic
    my $self=shift;
    $self->write("DISPLAY:TEXT:CLEAR");
}

sub beep { # basic
    my $self=shift;
    $self->write("SYSTEM:BEEPER");
}


1;

=head1 NAME

	Lab::Instrument::Agilent34420A - HP/Agilent 34420A or 34421A digital multimeter

.

=head1 SYNOPSIS

	use Lab::Instrument::Agilent34420A;
	my $agilent=new Lab::Instrument::Agilent34420A(0,22);
	print $agilent->get_value();

.

=head1 DESCRIPTION

The Lab::Instrument::Agilent34420A class implements an interface to the 34420A and 34421A digital multimeters by
Agilent (formerly HP). Note that the module Lab::Instrument::Agilent34420A still works for those older multimeter 
models.

.

=head1 CONSTRUCTOR

	my $agilent=new(\%options);

.

=head1 METHODS

=head2 get_value

	$value=$agilent->get_value(<$function>,<$range>,<$integration>);

Request a measurement value. If optinal paramters are defined, some device paramters can be preset befor the request of a measurement value.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34420A.

	"voltage" --> voltage measurement using the currently selected sense
	"sense1:voltage" --> voltage measurement useing sense #1
	"sense2:voltage" --> voltage measurement useing sense #2
	"voltage:ratio" --> voltage measurment + calculation V[sense #1]/ V[sense #2]
	"voltage:diff" --> voltage measurment + calculation V[sense #1] - V[sense #2]
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $range

C<RANGE> is given in terms of volts or ohms and can be C<1mV...100V|MIN|MAX|DEF|AUTO> or C<1...1e6|MIN|MAX|DEF|AUTO>.
C<DEF> is default C<AUTO> activates the C<AUTORANGE-mode>.
C<DEF> will be set, if no value is given.

=item <$resolution>

C<INTEGratioN> controlles the integration mode and the integration time. It is composed of two parts:

	1.) Integration mode:
		
		'nplc='  -->  Number of Power Line Cycles MODE
		'res='   -->  Resolution-MODE
		
If no Integration mode is given, the 'Number of Power Line Cycles MODE' will be selected as default.
		
	2.) Integration Time:
		
		Floating point number or MIN, MAX, DEF. 

For detailed information about the valid range for the integration time see
L<set_resolution>, L<set_nplc>

Examples:
	
			
	a) $integration = 'nplc=5'
		-->  Integration mode = Number of Power Line Cycles MODE
		-->  Integration Time = 5 Powerline cycles = 5 * 1/50 Hz = 0.1 seconds
		
	b) $integration = 'res=0.00001'
		-->  Integration mode = Resolution-MODE
		-->  Integration Time = will be choosen automaticly to guarantee the requested resolution
	
	c) $integration = '1'
		-->  Integration mode =  Number of Power Line Cycles MODE
		-->  Integration Time = 1 Powerline cycles = 1 * 1/50 Hz = 0.02 seconds


=back

.

=head2 config_measurement

	$agilent->config_measurement($function, $number_of_points, <$nplc>, <$range>);

Preset the Agilent34420A nanovoltmeter for a TRIGGERED measurement.
Returns the duration to record the defined trace.

NOTE:
The Agilent34420A nanovoltmeter allows only specified values for the integration time, namely 0.02, 0.2, 1, 2, 10, 20, 100, or 200 Power-line-cycles.
--> the duration to recored one trace depends on these specific values and the number of points to be recorded. 

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34420A.

	"voltage" --> voltage measurement using the currently selected sense
	"sense1:voltage" --> voltage measurement useing sense #1
	"sense2:voltage" --> voltage measurement useing sense #2
	"voltage:ratio" --> voltage measurment + calculation V[sense #1]/ V[sense #2]
	"voltage:diff" --> voltage measurment + calculation V[sense #1] - V[sense #2]
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $number_of_points

Preset the C<NUMBER OF POINTS> to be taken for one measurement trace.
The single measured points will be stored in the internal memory of the Agilent34420A nanovoltmeter.
for the Agilent34420A nanovoltmeter the internal memory is limited to 1024 values.

=item <$nplc>

Preset the C<NUMBER of POWER LINE CYCLES> which is actually something similar to an integration time for recording a single measurement value.
The values for $nplc can be any value between 0.02 ... 200 but internally the Agilent34420A nanovoltmeter selects the value closest to one of the following fixed values C<0.02 | 0.2 | 1 | 2 | 10 | 20 | 100 | 200 | MIN | MAX>.

Example:
Assuming $nplc to be 20 and assuming a netfrequency of 50Hz this results in an integration time of 20*50Hz = 0.4 seconds for each measured value. Assuming $number_of_points to be 100 it takes in total 40 seconds to record all values for the trace.

=item <$range>

C<RANGE> is given in terms of volts or ohms and can be C<1mV...100V|MIN|MAX|DEF|AUTO> or C<1...1e6|MIN|MAX|DEF|AUTO>.
C<DEF> is default C<AUTO> activates the C<AUTORANGE-mode>.
C<DEF> will be set, if no value is given.

=back

.

=head2 trg

	$agilent->trg();

Sends a trigger signal via the GPIB-BUS to start the predefined measurement.
The Agilent34420A nanovoltmeter won't accept any new commands until data-recording has been finished. Unfortunatelly it is not possible to stop an once started measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Agilent34420A nanovoltmeter.

.

=head2 abort

	$agilent->abort();

doesn't work, because Agilent 34420A doesn't accept any new C<SPCI COMMANDS> until last C<COMMAND> has been completed.

.

=head2 get_data

	@data = $agilent->get_data();

Reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
Reading the buffer will not start before all predevined measurement values ($number_of_points) have been recorded.

.

=head2 set_function

	$agilent->set_function($function);

Set a new value for the measurement function of the Agilent34420A nanovoltmeter.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Agilent34420A.

	"voltage" --> voltage measurement using the currently selected sense
	"sense1:voltage" --> voltage measurement useing sense #1
	"sense2:voltage" --> voltage measurement useing sense #2
	"voltage:ratio" --> voltage measurment + calculation V[sense #1]/ V[sense #2]
	"voltage:diff" --> voltage measurment + calculation V[sense #1] - V[sense #2]
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=back

.

=head2 set_range

	$agilent->set_range($function,$range);

Set a new value for the predefined RANGE for the measurement function $function of the Agilent34420A nanovoltmeter.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Agilent34420A.

	"voltage" --> voltage measurement using the currently selected sense
	"sense1:voltage" --> voltage measurement useing sense #1
	"sense2:voltage" --> voltage measurement useing sense #2
	"voltage:ratio" --> voltage measurment + calculation V[sense #1]/ V[sense #2]
	"voltage:diff" --> voltage measurment + calculation V[sense #1] - V[sense #2]
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $range

C<RANGE> is given in terms of volts or ohms and can be C<1mV...100V|MIN|MAX|DEF|AUTO> or C<1...1e6|MIN|MAX|DEF|AUTO>.
C<DEF> is default C<AUTO> activates the C<AUTORANGE-mode>.
C<DEF> will be set, if no value is given.

=back

.

=head2 set_nplc

	$agilent->set_nplc($function,$nplc);

Set a new value for the predefined C<NUMBER of POWER LINE CYCLES> for the measurement function $function of the Agilent34420A nanovoltmeter.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Agilent34420A.

	"voltage" --> voltage measurement using the currently selected sense
	"sense1:voltage" --> voltage measurement useing sense #1
	"sense2:voltage" --> voltage measurement useing sense #2
	"voltage:ratio" --> voltage measurment + calculation V[sense #1]/ V[sense #2]
	"voltage:diff" --> voltage measurment + calculation V[sense #1] - V[sense #2]
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $nplc

Preset the C<NUMBER of POWER LINE CYCLES> which is actually something similar to an integration time for recording a single measurement value.
The values for $nplc can be any value between 0.02 ... 200 but internally the Agilent34420A nanovoltmeter selects the value closest to one of the following fixed values C<0.02 | 0.2 | 1 | 2 | 10 | 20 | 100 | 200 | MIN | MAX>.

B<Example:>
Assuming $nplc to be 20 and assuming a netfrequency of 50Hz this results in an integration time of 20*50Hz = 0.4 seconds for each measured value.

=back

.

=head2 set_resolution

	$agilent->set_resolution($function,$resolution);

Set a new value for the predefined C<resOLUTION> for the measurement function $function of the Agilent34420A nanovoltmeter.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Agilent34420A.

	"voltage" --> voltage measurement using the currently selected sense
	"sense1:voltage" --> voltage measurement useing sense #1
	"sense2:voltage" --> voltage measurement useing sense #2
	"voltage:ratio" --> voltage measurment + calculation V[sense #1]/ V[sense #2]
	"voltage:diff" --> voltage measurment + calculation V[sense #1] - V[sense #2]
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $resolution

C<resOLUTION> is given in terms of C<$resolution*$range> or C<[MIN|MAX|DEF]>.
C<$resolution=0.0001> means 4 1/2 digits for example.
$resolution can be 0.0001xRANGE ... 0.0000022xRANGE.
The best resolution is 100nV: C<$range=0.1>; C<$resolution=0.000001>.
C<DEF> will be set, if no value is given.

=back

.

=head2 set_channel

	$agilent->set_channel($channel);

Select the active sensing terminal. This function can only be used if the active C<FUNCTION> is in the voltage mode ( not resistance or Fresistance).

=over 4

=item $channel

C<CHANNEL> can be '1' for sense #1 or '2' for sense #2.

=back

.

=head2 display_on

	$agilent->display_on();

Turn the front-panel display on.

.

=head2 display_off

	$agilent->display_off();

Turn the front-panel display off.

.

=head2 display_text

	$agilent->display_text($text);
	print $agilent->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

.

=head2 display_clear

	$agilent->display_clear();

Clear the message displayed on the front panel.

.

=head2 beep

	$agilent->beep();

Issue a single beep immediately.

.

=head2 get_error

	($err_num,$err_msg)=$agilent->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

.

=head2 reset

	$agilent->reset();

Reset the multimeter to its power-on configuration.

.

=head2 id

	$id=$agilent->id();

Returns the instruments ID string.

.

=head1 CAVEATS/BUGS

probably many

.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

.

=head1 AUTHOR/COPYRIGHT

Stefan Geissler

.

