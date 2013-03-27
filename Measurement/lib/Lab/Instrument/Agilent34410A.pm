#!/usr/bin/perl

package Lab::Instrument::Agilent34410A;
our $VERSION = '2.00';

use strict;
use Time::HiRes qw (usleep);
use Scalar::Util qw(weaken);
use Lab::Instrument;
use Carp;
use Data::Dumper;
use Lab::Instrument::Multimeter;


our @ISA = ("Lab::Instrument::Multimeter");

our %fields = (
	supported_connections => [ 'VISA_GPIB', 'GPIB' ],

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
		'function' => undef,
		'range' => undef,
		'nplc' => undef,
		'resolution' => undef,
		'tc' => undef,
		'bandwidth' => undef,		
	}

);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	return $self;
}

sub id {
    my $self=shift;
    return $self->query('*IDN?');	
}

sub get_error {
    my $self=shift;
    chomp(my $err=$self->query( "SYSTem:ERRor?"));
    my ($err_num,$err_msg)=split ",",$err;
    $err_msg=~s/\"//g;
    return ($err_num,$err_msg);
}

sub reset { # basic
    my $self=shift;
    $self->write( "*RST");
}




# ------------------------------- SENSE ---------------------------------------------------------


sub set_function { # basic
	my $self = shift;
	
	
	# any parameters given?
	if (not defined @_[0]) 
		{
		print Lab::Exception::CorruptParameter->new( error => "no values given in ".ref($self)." \n" );
		return;
		}
	
	# parameter == hash??
	my ($function) = $self->_check_args( \@_, ['function'] );
	
	
	#set function:
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	if ( $function =~ /^(current|curr|current:ac|curr:ac|current:dc|curr:dc|voltage|volt|voltage:ac|volt:ac|voltage:dc|volt:dc|resisitance|res|fresistance|fres)$/)
		{
		$function =  $self->query( sprintf("FUNCTION '%s'; FUNCTION?", $function));
		$function =~ s/\"//g; # remove leading and ending "
		chomp($function);
		return $function;
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "Agilent 34410A:\n\nAgilent 34410A:\nunexpected value for FUNCTION in sub set_function. Expected values are VOLTAGE:DC, VOLTAGE:AC, CURRENT:DC, CURRENT:AC, RESISTANCE or FRESISTANCE.\n" );
		}	
	
}

sub get_function {
	my $self = shift;
	
	my $function = $self->query( "FUNCTION?");
	if ( $function =~ /([\w:]+)/ ) 
		{
		return $1;
		}
}

sub set_range { # basic
	my $self = shift;
	
	
	# any parameters given?
	if (not defined @_[0]) 
		{
		print Lab::Exception::CorruptParameter->new( error => "no values given in ".ref($self)." \n" );
		return;
		}
		
	# parameter == hash??
	my ($function, $range) = $self->_check_args( \@_, ['function', 'range'] );
	
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
		
	# parameter 'range' as 'function' given?
	if (not defined $range)
		{		
		if ( $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ )
			{
			$range = $function;
			$function = $self->get_function();
			$function = "\L$function"; # transform all uppercase letters to lowercase letters
			}
		else
			{
			print Lab::Exception::CorruptParameter->new( error => "no valid value for parameter 'range' given.\n" );
			return;
			}
		}
	
			
	
	# check if value of paramter 'range' is valid:
	if ( $function =~ /^(voltage|volt|voltage:ac|volt:ac|voltage:dc|volt:dc)$/ ) {
		if ( abs($range) > 1000 ) {
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for RANGE in sub set_range. Expected values are for CURRENT, VOLTAGE and RESISTANCE mode -3...+3A, 0.1...1000V or 0...1e9 Ohms respectivly");
		}
	}
	elsif ( $function =~ /^(current|curr|current:ac|curr:ac|current:dc|curr:dc)$/) { 	
		if ( abs($range) > 3 ) {
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for RANGE in sub set_range. Expected values are for CURRENT, VOLTAGE and RESISTANCE mode -3...+3A, 0.1...1000V or 0...1e9 Ohms respectivly");
		}
	}
	elsif ( $function =~ /^(resisitance|res|fresistance|fres)$/) { 
		if ( $range < 0 or $range > 1e9 ) {
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for RANGE in sub set_range. Expected values are for CURRENT, VOLTAGE and RESISTANCE mode -3...+3A, 0.1...1000V or 0...1e9 Ohms respectivly");
		}
	}
	else {
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for FUNCTION in sub set_range. Expected values are VOLTAGE:DC, VOLTAGE:AC, CURRENT:DC, CURRENT:AC, RESISTANCE or FRESISTANCE.");
		}
	
	
	
	# set range
	if ( $range =~ /^(min|max|def)$/ or $range =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/) 
		{		
		$range = $self->query( "$function:RANGE $range; RANGE?");
		chomp($range);
		return $range;
		}
	elsif ($range =~ /^(auto)$/) 
		{
		$range =  "RANGE=AUTO , ".$self->query( sprintf("%s:RANGE:AUTO ON; RANGE?", $function));
		chomp($range);
		return $range;
		}
	else 
		{
		Lab::Exception::CorruptParameter->throw( error => "anything's wrong in sub set_range!!");
		}
		
	

}

sub get_range {
	my $self = shift;	
	
		
	# parameter == hash??
	my ($function) = $self->_check_args( \@_, ['function'] );
	
	if (not defined $function) 
		{
		$function = $self->get_function();
		}	
		
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	if ( $function  =~ /^(voltage|volt|voltage:ac|volt:ac|voltage:dc|volt:dc|current|curr|current:ac|curr:ac|current:dc|curr:dc|resisitance|res|fresistance|fres)$/ )
		{
		my $range = $self->query( "$function:RANGE?");
		chomp($range);
		return $range;
		}				
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected parameter $function.");
		}
		
}

sub set_nplc { # basic
	my $self = shift;
	
	
	# any parameters given?
	if (not defined @_[0]) 
		{
		print Lab::Exception::CorruptParameter->new( error => "no values given in ".ref($self)." \n" );
		return;
		}
		
	# parameter == hash??
	my ($function, $nplc) = $self->_check_args( \@_, ['function', 'nplc'] );	
	
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
		
	# parameter 'nplc' as 'function' given?
	if (not defined $nplc)
		{		
		if ( $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ )
			{
			$nplc = $function;
			$function = $self->get_function();
			$function = "\L$function"; # transform all uppercase letters to lowercase letters
			}
		else
			{
			print Lab::Exception::CorruptParameter->new( error => "no valid value for parameter 'nplc' given.\n" );
			return;
			}
		}
	
	# check if value of paramter 'nplc' is valid:
	if (($nplc < 0.006 or $nplc > 100) and not $nplc =~ /^(min|max|def)$/ ) 
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for NPLC in sub set_nplc. Expected values are between 0.006 ... 100 power-line-cycles (50Hz).");
			}
			
			
	# set nplc:
	if ($function =~ /^(current|curr|current:dc|curr:dc|voltage|volt|voltage:dc|volt:dc|resisitance|res|fresistance|fres)$/ )
		{		
		$nplc = $self->query( "$function:NPLC $nplc; NPLC?");
		chomp($nplc);
		return $nplc;
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for FUNCTION in sub set_nplc. Expected values are VOLTAGE:DC, CURRENT:DC, RESISTANCE or FRESISTANCE.");
		}	
	

}

sub get_nplc {
	my $self = shift;	
	
	# parameter == hash??
	my ($function) = $self->_check_args( \@_, ['function'] );
	
	if (not defined $function) 
		{
		$function = $self->get_function();
		}
		
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	if ( $function  =~ /^(voltage|volt|voltage:ac|volt:ac|voltage:dc|volt:dc|current|curr|current:ac|curr:ac|current:dc|curr:dc|resisitance|res|fresistance|fres)$/ )
		{
		my $nplc = $self->query( "$function:NPLC?");
		chomp($nplc);
		return $nplc;
		}				
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected parameter $function.");
		}
}

sub set_resolution{ # basic
	my $self = shift;
	
	# any parameters given?
	if (not defined @_[0]) 
		{
		print Lab::Exception::CorruptParameter->new( error => "no values given in ".ref($self)." \n" );
		return;
		}
		
	# parameter == hash??
	my ($function, $resolution) = $self->_check_args( \@_, ['function', 'resolution'] );	
	
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
		
	# parameter 'resolution' as 'function' given?
	if (not defined $resolution)
		{		
		if ( $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ )
			{
			$resolution = $function;
			$function = $self->get_function();
			$function = "\L$function"; # transform all uppercase letters to lowercase letters
			}
		else
			{
			print Lab::Exception::CorruptParameter->new( error => "no valid value for parameter 'resolution' given.\n" );
			return;
			}
		}
	
	# check if value of paramter 'resolution' is valid:
	my $range = $self->get_range($function);
	if ( $resolution < 0.3e-6*$range and not $resolution =~ /^(min|max|def)$/ ) 
			{
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for RESOLUTION in sub set_resolution. Expected values have to be greater than 0.3e-6*RANGE.");
			}
	
	
	# set resolution:
	if ($function =~ /^(current|curr|current:dc|curr:dc|voltage|volt|voltage:dc|volt:dc|resisitance|res|fresistance|fres)$/ )
		{	
		my $range = $self->get_range($function);
		$self->set_range($function, $range); # switch off autorange function if activated.
		$resolution = $self->query( "$function:RES $resolution; RES?");
		chomp($resolution);
		return $resolution;
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for FUNCTION in sub set_resolution. Expected values are VOLTAGE:DC, CURRENT:DC, RESISTANCE or FRESISTANCE.");
		}	
		
}

sub get_resolution{
	my $self = shift;	
	
	# parameter == hash??
	my ($function) = $self->_check_args( \@_, ['function'] );
	
	if (not defined $function) 
		{
		$function = $self->get_function();
		}
		
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	if ( $function  =~ /^(voltage|volt|voltage:ac|volt:ac|voltage:dc|volt:dc|current|curr|current:ac|curr:ac|current:dc|curr:dc|resisitance|res|fresistance|fres)$/ )
		{
		my $resolution = $self->query( "$function:RES?");
		chomp($resolution);
		return $resolution;
		}				
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected parameter $function.");
		}
}

sub set_tc { # basic
	my $self = shift;
	
	
	# any parameters given?
	if (not defined @_[0]) 
		{
		print Lab::Exception::CorruptParameter->new( error => "no values given in ".ref($self)." \n" );
		return;
		}
		
	# parameter == hash??
	my ($function, $tc) = $self->_check_args( \@_, ['function', 'tc'] );
	
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
		
	# parameter 'tc' as 'function' given?
	if (not defined $tc)
		{		
		if ( $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ )
			{
			$tc = $function;
			$function = $self->get_function();
			$function = "\L$function"; # transform all uppercase letters to lowercase letters
			}
		else
			{
			print Lab::Exception::CorruptParameter->new( error => "no valid value for parameter 'tc' given.\n" );
			return;
			}
		}
	
	# check if value of paramter 'tc' is valid:
	if ( ($tc < 1e-4 or $tc > 1) and not $tc =~ /^(min|max|def)$/ ) 
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for APERTURE in sub set_tc. Expected values are between 1e-4 ... 1 sec.");
			}
	
	# set tc:
	if ($function =~ /^(current|curr|current:dc|curr:dc|voltage|volt|voltage:dc|volt:dc|resisitance|res|fresistance|fres)$/ )
		{
		$tc = $self->query( ":$function:APERTURE $tc; APERTURE:ENABLED 1; :$function:APERTURE?");
		chomp($tc);
		return $tc;
		}
	else
		{	
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for FUNCTION in sub set_tc. Expected values are VOLTAGE:DC, CURRENT:DC, RESISTANCE or FRESISTANCE.");
		}
	

}

sub get_tc{
	my $self = shift;	
	
	# parameter == hash??
	my ($function) = $self->_check_args( \@_, ['function'] );
	
	if (not defined $function) 
		{
		$function = $self->get_function();
		}
	
		
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	if ( $function  =~ /^(voltage|volt|voltage:ac|volt:ac|voltage:dc|volt:dc|current|curr|current:ac|curr:ac|current:dc|curr:dc|resisitance|res|fresistance|fres)$/ )
		{
		my $tc = $self->query( "$function:APERTURE?");
		chomp($tc);
		return $tc;
		}				
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected parameter $function.");
		}
}

sub set_bw { # basic
	my $self = shift;
	
	# any parameters given?
	if (not defined @_[0]) 
		{
		print Lab::Exception::CorruptParameter->new( error => "no values given in ".ref($self)." \n" );
		return;
		}
		
	# parameter == hash??
	my ($function, $bw) = $self->_check_args( \@_, ['function', 'bandwidth'] );	
	
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	# parameter 'bw' as 'function' given?
	if (not defined $bw)
		{		
		if ( $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ )
			{
			$bw = $function;
			$function = $self->get_function();
			$function = "\L$function"; # transform all uppercase letters to lowercase letters
			}
		else
			{
			print Lab::Exception::CorruptParameter->new( error => "no valid value for parameter 'bw' given.\n" );
			return;
			}
		}
		
	# check if value of paramter 'bw' is valid:
	if ( ($bw < 3 or $bw > 200) and not $bw =~ /^(min|max|def)$/ ) 
			{
			Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for BANDWIDTH in sub set_bw. Expected values are between 3 ... 200 Hz.");
			}
	
	# set bw:
	if ( $function =~ /^(current:ac|curr:ac|voltage:ac|volt:ac|)$/ )
		{
		$bw = $self->query( "$function:BANDWIDTH $bw; BANDWIDTH?");
		chomp($bw);
		return $bw;
		}
	else
		{	
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for FUNCTION in sub set_bw. Expected values are VOLTAGE:AC or CURRENT:AC.");
		}
		

}

sub get_bw {
	my $self = shift;
	
	# parameter == hash??
	my ($function) = $self->_check_args( \@_, ['function'] );
	#print $self->_check_args( 10, {'function'} )."\n";
	
	if (not defined $function) 
		{
		$function = $self->get_function();
		}
		
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	
	if ( $function =~ /^(voltage:ac|volt:ac|current:ac|curr:ac)$/ )
		{
		my $bw = $self->query( "$function:BANDWIDTH?");
		chomp($bw);
		return $bw;
		}				
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected parameter $function.");
		}
}





# ----------------------------- TAKE DATA ---------------------------------------------------------


sub get_value { # basic
	my $self = shift;
	
	
	# fastest way to get a value:
	if ( not defined @_[0])
		{
		$self->{value} = $self->query( ":read?");	
		return $self->{value};
		}
	
	# parameter == hash??	
	my ($function, $range, $integration) = $self->_check_args(\@_, ['function', 'range', 'integration']);
	my ($int_time, $int_mode) = $self->_check_args($integration, ['value', 'mode']);
	
	$range='DEF' unless (defined $range);
		
	
	# check input parameter
	$function =~ s/\s+//g; #remove all whitespaces
	$function = "\L$function"; # transform all uppercase letters to lowercase letters
	if ( $function =~ /^(voltage|volt|voltage:ac|volt:ac|voltage:dc|volt:dc)$/ ) 
		{
		if ( abs($range) > 1000 and not $range =~ /^(min|max|def|auto)$/) 
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for RANGE in sub get_value. Expected values are for CURRENT, VOLTAGE and RESISTANCE mode -3...+3A, 0.1...1000V or 0...1e9 Ohms respectivly");
			}
		}
	elsif ($function =~ /^(current|curr|current:ac|curr:ac|current:dc|curr:dc)$/) 
		{	
		if ( abs($range) > 3 and not $range =~ /^(min|max|def|auto)$/) 
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for RANGE in sub get_value. Expected values are for CURRENT, VOLTAGE and RESISTANCE mode -3...+3A, 0.1...1000V or 0...1e9 Ohms respectivly");
			}
		}
	elsif ( $function =~ /^(resisitance|res|fresistance|fres)$/ ) 
		{
		if ( abs($range) > 1e9 and not $range =~ /^(min|max|def|auto)$/) 
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for RANGE in sub get_value. Expected values are for CURRENT, VOLTAGE and RESISTANCE mode -3...+3A, 0.1...1000V or 0...1e9 Ohms respectivly");
			}
		}
	
	
	
	$int_mode =~ s/\s+//g; #remove all whitespaces
	$int_mode = "\L$int_mode"; # transform all uppercase letters to lowercase letters
	if ( $int_mode =~ /resolution|res/ )
		{
		$int_mode = "res";
		if ( $int_value < 0.3e-6*$range and not $int_value =~ /^(MIN|min|MAX|max|DEF|def)$/)
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for RESOLUTION in sub get_value. Expected values are from 0.3e-6xRANGE ... 30e-6xRANGE.");
			}
		}
	elsif ( $int_mode eq "tc" )
		{
		if ( ($int_value < 1e-4 or $int_value > 1) and not $int_value =~ /^(MIN|min|MAX|max|DEF|def)$/)
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for INTEGRATION TIME in sub get_value. Expected values are from 1e-4 ... 1 sec.");
			}
		}
	elsif ( $int_mode eq "nplc" )
		{
		if (  ($int_value < 0.01 or $int_value > 100) and not $int_value =~ /^(MIN|min|MAX|max|DEF|def)$/)
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for NPLC in sub get_value. Expected values are from 0.01 ... 100.");
			}
		}
	elsif ( defined $int_value )  
		{
		$int_mode = 'nplc';
		if (  ($int_value < 0.01 or $int_value > 100) and not $int_value =~ /^(MIN|min|MAX|max|DEF|def)$/)
			{
			Lab::Exception::CorruptParameter->throw( error => "unexpected value for NPLC in sub get_value. Expected values are from 0.01 ... 100.");
			}
		}
	
	
	
	# get_value	
	if ( $int_mode eq 'res' )
		{
		$self->write( ":FUNCTION '$function'; :SENS:$function:ZERO:AUTO OFF; :$function:RANGE $range;  RES $int_value");
		$self->{value} = $self->query( ":read?");	
		return $self->{value};
		}
	elsif ( $int_mode eq 'tc' )
		{
		$self->write( ":FUNCTION '$function'; :SENS:$function:ZERO:AUTO OFF; :$function:RANGE $range; :$function:APER $int_value; APERTURE:ENABLED 1");
		$self->{value} = $self->query( ":read?");	
		return $self->{value};
		}
	elsif ( $int_mode eq 'nplc' )
		{
		$self->write( ":FUNCTION '$function'; :SENS:$function:ZERO:AUTO OFF; :$function:RANGE $range; NPLC $int_value");
		$self->{value} = $self->query( ":read?");	
		return $self->{value};
		}
	else
		{
		$self->write( ":FUNCTION '$function';");
		$self->{value} = $self->query( ":read?");	
		return $self->{value};
		}
	
		
	
}

sub get_T { # basic
	my $self = shift;
	
	# parameter == hash??
	my ( $sensor ) = $self->_check_args(\@_, ['sensor']);
	
	# check if given sensorname is in sensors list
	if ( not Lab::Instrument::TemperatureDiodes->valid_sensor($sensor))
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for SENSOR in sub get_T. Expected values are defined in package Lab::Instrument::TemperatureDiodes.pm -> SENSOR.");
		}
	
	# measure temperature
	my $value = $self->get_value();
	$self->{value} = Lab::Instrument::TemperatureDiodes->convert2Kelvin($value,$sensor);
	return $self->{value};
	
}

sub config_measurement { # basic
	my $self = shift;
	
	# parameter == hash??
	my ( $function, $nop, $time, $range, $trigger ) = $self->_check_args(\@_, ['function', 'nop', 'time', 'range', 'trigger']);
	
	
	# check input data
	if ( not defined $trigger )
		{
		$trigger = 'BUS';
		}
	if ( not defined $range )
		{
		$range = 'DEF';
		}
	if ( not defined $time )
		{
		Lab::Exception::CorruptParameter->throw( error => "too view arguments given in sub config_measurement. Expected arguments are FUNCTION, #POINTS, TIME, <RANGE>, <TRIGGERSOURCE>");
		}
	
	print "--------------------------------------\n";
	print "Agilent34410A: sub config_measurement:\n";
	
	# clear buffer
	my $points = $self->query( "DATA:POINTS?");
	if ($points > 0) {
		$points = $self->connection()->LongQuery( command => "DATA:REMOVE? $points");
	}
	
	
	# set function
	print "set_function: ".$self->set_function($function)."\n";
		
	
	# set range
	print "set_range: ".$self->set_range($function,$range)."\n";
	
	
	# set integration time
	my $tc = $time/$nop;
	print "set_tc: ".$self->set_tc($function,$tc)."\n";
	
	
	# set auto high impedance (>10GOhm) for VOLTAGE:DC for ranges 100mV, 1V, 10V
	if ( $function =~ /^(VOLTAGE|voltage|VOLT|volt|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc)$/ ) {
	print "set_auto_high_impedance\n"; $self->write( "SENS:VOLTAGE:DC:IMPEDANCE:AUTO ON");
	}
	
	# perfome AUTOZERO and then disable 
	if ( $function =~ /^(CURRENT|current|CURR|curr|CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)$/) {
		print "set_AUTOZERO OFF\n"; $self->write( sprintf("SENS:%s:ZERO:AUTO OFF",$function));
	}
	
		
		
	# triggering
    print "set Trigger Source: ".$self->_set_triggersource("BUS")."\n";
	print "set Trigger Count: ".$self->_set_triggercount(1)."\n";
	print "set Trigger Delay: ".$self->_set_triggerdelay("MIN")."\n";
	
    print "set Sample Count: ".$self->_set_samplecount($nop)."\n";
	print "set Sample Delay: ".$self->_set_sampledelay(0)."\n";
    
    print "init()\n"; $self->write( "INIT");
	usleep(5e5);

	print "Agilent34410A: sub config_measurement complete\n";
	print "--------------------------------------\n";
	

}

sub trg { # basic
	my $self = shift;
	$self->write( "*TRG");
}

sub get_data { # basic
	my $self = shift;
	my $data;
	my @data;
	
	# parameter == hash??
	my ( $readings ) = $self->_check_args(\@_, ['readings']);
	
	if ( not defined $readings ) {$readings = "ALL";}
	
	if ($readings >= 1 and $readings <= 50000){
		if ($readings > $self->query( "SAMPLE:COUNT?")) {
			$readings = $self->query( "SAMPLE:COUNT?");
			}
		for ( my $i = 1; $i <= $readings; $i++){
			my $break = 1;
			while($break){
				$data = $self->connection()->LongQuery( command => "R? 1");
				chomp $data;
				my $index;
				if(index($data,"+") == -1){
					$index = index($data,"-");
					}
				elsif(index($data,"-") == -1){
					$index = index($data,"+");
					}
				else {
					$index = (index($data,"-") < index($data,"+")) ? index($data,"-") : index($data,"+");
					}
				$data = substr($data,$index,length($data)-$index);
				if ($data != 0) {$break = 0;}
				else {usleep(1e5); }
				}
				push(@data, $data);
			}
		if ( $readings == 1 ) { return $data; }
		else { return @data; }
		}
	elsif ($readings eq "ALL" or $readings = "all") {
		# wait until data are available
		$self->wait();
		$data = $self->connection()->LongQuery( command => "FETC?");
		chomp $data;	
		@data = split(",",$data);	
		return @data;	
		}
	else 
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for number of readINGS in sub get_data. Expected values are from 1 ... 50000 or ALL.");
		}
	
}

sub abort { # basic
	my $self=shift;
    $self->write( "ABOR");
}

sub wait { # basic
 my $self = shift;
 
 while(1)
	{	
	if ($self->active()) {usleep(1e3);}
	else {last;}
	}	
	
return 0;
	
}

sub active { # basic
	my $self = shift;
 
	my $status = sprintf("%.15b",$self->query( "STAT:OPER:COND?"));
	my @status = split("",$status);
	if ($status[5] == 1 && $status[10] == 0) 
		{
		return 0;
		}
	else 
		{
		return 1;
		}
	
}





# ------------------ TRIGGER and SAMPLE settings ---------------------- #


sub _set_triggersource { # internal
	my $self = shift;
	
	# parameter == hash??
	my ( $source ) = $self->_check_args(\@_, ['trigger_source']);
	
	if ( not defined $source) 
		{
		$source = $self->query( sprintf("TRIGGER:SOURCE?"));
		chomp($source);
		$self->{config}->{triggersource} = $source;
		return $source;
		}
	
	if ( $source =~ /^(IMM|imm|EXT|ext|BUS|bus|INT|int)$/ )
		{
		$source = $self->query( sprintf("TRIGGER:SOURCE %s; SOURCE?", $source));
		$self->{config}->{triggersource} = $source;
		return $source;
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for TRIGGER_SOURCE in sub _set_triggersource. Expected values are:\n IMM  --> immediate trigger signal\n EXT  --> external trigger\n BUS  --> software trigger signal via bus\n INT  --> internal trigger signal\n");
		}
		
}

sub _set_triggercount { # internal
	my $self = shift;
	
	
	# parameter == hash??
	my ( $count ) = $self->_check_args(\@_, ['trigger_count']);
	
	if ( not defined $count) 
		{
		$count =  $self->query( sprintf("TRIGGER:COUNT?"));
		chomp($count);
		$self->{config}->{triggercount} = $count;
		return $count;		
		}
	
	if ( $count >= 0 or $count <= 50000)
		{
		$count = $self->query( sprintf("TRIGGER:COUNT %d; COUNT?", $count));	
		$self->{config}->{triggercount} = $count;
		return $count;
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for COUNT in sub _set_triggercount. Expected values are between 1 ... 50.000\n");
		}

}
	
sub _set_triggerdelay { # internal
	my $self = shift;
		
	# parameter == hash??
	my ( $delay ) = $self->_check_args(\@_, ['trigger_delay']);
	
	if ( not defined $delay) 
		{
		$delay =  $self->query( sprintf("TRIGGER:DELAY?"));	
		chomp($delay);
		$self->{config}->{triggerdely} = $delay;
		return $delay;
		}
	
	if ( ($delay >= 0 or $delay <= 3600) or $delay =~ /^(MIN|min|MAX|max|DEF|def)$/)
		{
		$delay = $self->query( "TRIGGER:DELAY $delay; DELAY?");
		$self->{config}->{triggerdely} = $delay;
		return $delay;
		}
	elsif ( $delay =~/^(AUTO|auto)$/ )
		{
		$delay = $self->query( "TRIGGER:DELAY:AUTO ON; AUTO?");
		$self->{config}->{triggerdely} = "AUTO ON";
		return "AUTO ON";
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for DELAY in sub _set_triggerdelay. Expected values are between 1 ... 3600, or 'MIN = 0', 'MAX = 3600' or 'AUTO'\n");
		}
	}
	
sub _set_samplecount { # internal
	my $self = shift;
	
	# parameter == hash??
	my ( $count ) = $self->_check_args(\@_, ['sample_count']);
	
	if ( not defined $count) 
		{
		$count = $self->query( sprintf("SAMPLE:COUNT?"));	
		chomp($count);
		$self->{config}->{samplecount} = $count;
		return $count;
		}
	
	elsif ( $count < 0 or $count >= 50000)
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for COUNT in sub _set_samplecount. Expected values are between 1 ... 50.000\n");
		}
	else
		{
		$count = $self->query( sprintf("SAMPLE:COUNT %d; COUNT?", $count));
		$self->{config}->{samplecount} = $count;
		return $count;
		}
	}
	
sub _set_sampledelay { # internal
	my $self = shift;	
	
	# parameter == hash??
	my ( $delay ) = $self->_check_args(\@_, ['sample_delay']);
	
	if ( not defined $delay) 
		{
		$delay =  $self->query( sprintf("SAMPLE:TIMER?"));	
		chomp($delay);
		$self->{config}->{sampledelay} = $delay;
		return $delay;
		}
	
	if ( $delay =~ /^(MIN|min|MAX|max|DEF|def)$/)
		{
		$delay = $self->query( sprintf("SAMPLE:TIMER %s; TIMER?", $delay));
		$self->write( "SAMPLE:SOURCE TIM");
		$self->{config}->{samplecount} = $delay;
		return $delay;
		}
	elsif ($delay >= 0 or $delay <= 3600)
		{
		$delay = $self->query( sprintf("SAMPLE:TIMER  %.5f; TIMER?", $delay));
		$self->write( "SAMPLE:SOURCE TIM");
		$self->{config}->{samplecount} = $delay;
		return $delay;
		}
	
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "\nAgilent 34410A:\nunexpected value for DELAY in sub _set_sampledelay. Expected values are between 1 ... 3600, or 'MIN = 0', 'MAX = 3600'\n");
		}
		
	
	}




	
# ------------------------------- DISPLAY and BEEPER --------------------------------------------


sub display_text { # basic
    my $self=shift;
   	
	# parameter == hash??
	my ( $text ) = $self->_check_args(\@_, ['display_text']);
    
    if ($text) {
        $self->write( qq(DISPlay:TEXT "$text"));
    } else {
        chomp($text=$self->query( qq(DISPlay:TEXT?)));
        $text=~s/\"//g;
    }
    return $text;
}

sub display_on { # basic
    my $self=shift;
    $self->write( "DISPLAY ON");
}

sub display_off { # basic
    my $self=shift;
    $self->write( "DISPLAY OFF");
}

sub display_clear { # basic
    my $self=shift;
    $self->write( "DISPLAY:TEXT:CLEAR");
}

sub beep { # basic
    my $self=shift;
    $self->write( "SYSTEM:BEEPER");
}



1;



=head1 NAME

	Lab::Instrument::Agilent34410A - HP/Agilent 34410A or 34411A digital multimeter

.

=head1 SYNOPSIS

	use Lab::Instrument::Agilent34410A;
	my $hp=new Lab::Instrument::Agilent34410A(0,22);
	print $agilent->get_value();

.

=head1 DESCRIPTION

The Lab::Instrument::Agilent34410A class implements an interface to the 34410A and 34411A digital multimeters by
Agilent (formerly HP). Note that the module Lab::Instrument::Agilent34410A still works for those older multimeter 
models.

.

=head1 CONSTRUCTOR

	my $hp=new(\%options);

.

=head1 METHODS

=head2 get_value

	old style:
	$value=$agilent->get_value(<$function>,<$range>,<$integration>);
	
	new style:
	$value=$agilent->get_value({
		'function' => <$function>,
		'range' => <$range>,
		'integration' => {
			'mode' => <int_mode>,
			'value' => <int_value>
			}
		});

Request a measurement value. If optinal paramters are defined, some device paramters can be preset before the request for a measurement value is sent to the device.

=over 4


=item <$function>

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item <$range>

C<RANGE> is given in terms of amps, volts or ohms and can be C<-3...+3A | MIN | MAX | DEF | AUTO>, C<100mV...1000V | MIN | MAX | DEF | AUTO> or C<0...1e9 | MIN | MAX | DEF | AUTO>.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=item <$integration>

C<INTEGRATION> controlles the integration mode and the integration time. It is composed of two parts:

	1.) Integration mode:
		
		'tc='    -->  Integration-Time- or Aperture-MODE
		'nplc='  -->  Number of Power Line Cycles MODE
		'res='   -->  Resolution-MODE
		
If no Integration mode is given, the 'Number of Power Line Cycles MODE' will be selected as default.
		
	2.) Integration Time:
		
		Floating point number or MIN, MAX, DEF. 

For detailed information about the valid range for the integration time see
L<set_tc>, L<set_resolution>, L<set_nplc>

Examples:
	
	a) $integration = 'tc=0.2'
		-->  Integration mode = Integration-Time- or Aperture-MODE
		-->  Integration Time = 0.2 seconds
		
	b) $integration = 'nplc=5'
		-->  Integration mode = Number of Power Line Cycles MODE
		-->  Integration Time = 5 Powerline cycles = 5 * 1/50 Hz = 0.1 seconds
		
	c) $integration = 'res=0.00001'
		-->  Integration mode = Resolution-MODE
		-->  Integration Time = will be choosen automaticly to guarantee the requested resolution
	
	d) $integration = '1'
		-->  Integration mode = Number of Power Line Cycles MODE
		-->  Integration Time = 1 Powerline cycles = 1 * 1/50 Hz = 0.02 seconds


=back

.

=head2 get_T

	old style:
	$value=$agilent->get_value($sensor);
	
	new style:
	$value=$agilent->get_value({
		'sensor' => $sensor
		});

Make a measurement defined by $function with the previously specified range
and integration time.

=over 4

=item $sensor

	SENSOR  can be one of the Temperature-Diodes defined in Lab::Instrument::TemperatureDiodes.

=back

 

=head2 config_measurement

	old style:
	$agilent->config_measurement($function, $number_of_points, <$time>, <$range>);
	
	new style:
	$agilent->config_measurement({
		'function' => $function, 
		'nop' => $number_of_points,
		'time' => <$time>, 
		'range' => <$range>
		});

Preset the Agilent34410A for a TRIGGERED measurement.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $number_of_points

Preset the C<NUMBER OF POINTS> to be taken for one measurement trace.
The single measured points will be stored in the internal memory of the Agilent34410A.
For the Agilent34410A the internal memory is limited to 50.000 values.	
	

=item <$time>

Preset the C<TIME> duration for one full trace. From C<TIME> the integration time value for each measurement point will be derived [TC = (TIME *50Hz)/NOP].
Expected values are between 0.0001*NOP ... 1*NOP seconds.

=item <$range>

C<RANGE> is given in terms of amps, volts or ohms and can be C< -3...+3A | MIN | MAX | DEF | AUTO >, C< 100mV...1000V | MIN | MAX | DEF | AUTO > or C< 0...1e9 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=back

.

=head2 trg

	$agilent->trg();

Sends a trigger signal via the C<GPIB-BUS> to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Agilent34410A.

.

=head2 abort

	$agilent->abort();

Aborts current (triggered) measurement.

.

=head2 wait

	$agilent->wait();

C<WAIT> until triggered measurement has been finished.

.

=head2 active

	$agilent->active();

Returns '1' if the current triggered measurement is still active and '0' if the current triggered measurement has allready been finished.

.

=head2 get_data

	old style:
	@data = $agilent->get_data(<$readings>);
	
	new style:
	@data = $agilent->get_data({
		'readings' => <$readings>
		});

reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
reading the buffer will start immediately. The LabVisa-script cannot be continued until all requested readings have been recieved.

=over 4

=item <$readings>

C<readINGS> can be a number between 1 and 50.000 or 'ALL' to specifiy the number of values to be read from the buffer.
If $readings is not defined, the default value "ALL" will be used.

=back

.

=head2 set_function

	old style:
	$agilent->set_function($function);
	
	new style:
	$agilent->set_function({
		'function' => $function
		});

Set a new value for the measurement function of the Agilent34410A.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=back

.

=head2 set_range
	
	old style:
	$agilent->set_range($function,$range);
	
	new style:
	$agilent->set_range({
		'function' => $function,
		'range' => $range
		});

Set a new value for the predefined RANGE for the measurement function $function of the Agilent34410A.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $range

C<RANGE> is given in terms of amps, volts or ohms and can be C<-3...+3A | MIN | MAX | DEF | AUTO>, C<100mV...1000V | MIN | MAX | DEF | AUTO> or C<0...1e9 | MIN | MAX | DEF | AUTO>.	
C<DEF> is default C<AUTO> activates the C<AUTORANGE-mode>.
C<DEF> will be set, if no value is given.

=back

.

=head2 set_nplc

	old style:
	$agilent->set_nplc($function,$nplc);
	
	new style:
	$agilent->set_nplc({
		'function' => $function,
		'nplc' => $nplc
		});

Set a new value for the predefined C<NUMBER of POWER LINE CYCLES> for the measurement function $function of the Agilent34410A.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $nplc

Preset the C<NUMBER of POWER LINE CYCLES> which is actually something similar to an integration time for recording a single measurement value.
The values for $nplc can be any value between 0.006 ... 100 but internally the Agilent34410A selects the value closest to one of the following fixed values C< 0.006 | 0.02 | 0.06 | 0.2 | 1 | 2 | 10 | 100 | MIN | MAX | DEF >.

Example: 
Assuming $nplc to be 10 and assuming a netfrequency of 50Hz this results in an integration time of 10*50Hz = 0.2 seconds for each measured value. 

NOTE:
1.) Only those integration times set to an integral number of power line cycles (1, 2, 10, or 100 PLCs) provide normal mode (line frequency noise) rejection.
2.) Setting the integration time also sets the resolution for the measurement. The following table shows the relationship between integration time and resolution. 

	Integration Time (power line cycles)		 Resolution
	0.001 PLC  (34411A only)			30 ppm x Range
	0.002 PLC  (34411A only)			15 ppm x Range
	0.006 PLC					6.0 ppm x Range
	0.02 PLC					3.0 ppm x Range
	0.06 PLC					1.5 ppm x Range
	0.2 PLC						0.7 ppm x Range
	1 PLC (default)					0.3 ppm x Range
	2 PLC						0.2 ppm x Range
	10 PLC						0.1 ppm x Range
	100 PLC 					0.03 ppm x Range

=back

.

=head2 set_resolution

	old style:
	$agilent->set_resolution($function,$resolution);
	
	new style:
	$agilent->set_resolution({
		'function' => $function,
		'resolution' => $resolution
		});

Set a new value for the predefined RESOLUTION for the measurement function $function of the Agilent34410A nanovoltmeter.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $resolution

C<RESOLUTION> is given in terms of C<$resolution*$range> or C<[MIN|MAX|DEF]>.
C<$resolution=0.0001> means 4 1/2 digits for example.
$resolution must be larger than 0.3e-6xRANGE.
The best resolution is range = 100mV ==> resoltuion = 3e-8V
C<DEF> will be set, if no value is given.

=back

.

=head2 set_tc

	old style:
	$agilent->set_tc($function,$tc);

	new style:
	$agilent->set_tc({
		'function' => $function,
		'tc' => $tc
		});

Set a new value for the predefined C<INTEGRATION TIME> for the measurement function $function of the Agilent34410A.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $tc

C<INTEGRATION TIME> $tc can be C< 1e-4 ... 1s | MIN | MAX | DEF>.

NOTE: 
1.) Only those integration times set to an integral number of power line cycles (1, 2, 10, or 100 PLCs) provide normal mode (line frequency noise) rejection.
2.) Setting the integration time also sets the resolution for the measurement. The following table shows the relationship between integration time and resolution. 

	Integration Time (power line cycles)		 Resolution
	0.001 PLC  (34411A only)			30 ppm x Range
	0.002 PLC  (34411A only)			15 ppm x Range
	0.006 PLC					6.0 ppm x Range
	0.02 PLC					3.0 ppm x Range
	0.06 PLC					1.5 ppm x Range
	0.2 PLC						0.7 ppm x Range
	1 PLC (default)					0.3 ppm x Range
	2 PLC						0.2 ppm x Range
	10 PLC						0.1 ppm x Range
	100 PLC 					0.03 ppm x Range

=back

.

=head2 set_bw

	old style:
	$agilent->set_bw($function,$bw);

	new style:
	$agilent->set_bw({
		'function' => $function,
		'bandwidth' => $bw
		});

Set a new value for the predefined C<BANDWIDTH> for the measurement function $function of the Agilent34410A. This function can only be used for the functions C<VOLTAGE:AC> and C<CURRENT:AC>.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:ac" --> AC current measurement
	"voltage:ac" --> AC voltage measurement

=item $bw

BANDWIDTH $bw can be C< 3 ... 200Hz | MIN | MAX | DEF>.

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
	
	old style:
	$agilent->display_text($text);
	
	new style:
	$agilent->display_text({
		'display_text' => $text
		});
		

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

query the multimeter's error queue. Up to 20 errors can be stored in the
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

L<set_tc>

=back

.

=head1 AUTHOR/COPYRIGHT

Stefan Geissler

.

