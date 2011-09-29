package Lab::Instrument::Keithley2400;


use strict;
use Switch;
use Lab::Instrument;
use Lab::Instrument::Source;
use Lab::VISA;
use Time::HiRes qw/usleep/, qw/time/;


our $VERSION="1.21";
our @ISA=('Lab::Instrument::Source');


my $default_config={
    gate_protect            => 1,
    gp_equal_level          => 1e-5,
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
    gp_max_step_per_second  => 2,
};

sub new {
    my $proto = shift;
    my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($default_config,@args);
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@args);
	
	    
    return $self
}

sub reset {
	my $self = shift;
	$self->{vi}->Write("*RST");
	return "RESET";
}




# ------------------------------------ OUTPUT ---------------------------------------------

sub set_output {# basic setting
	my $self = shift;
	my $output = shift;
	my $source_ampl;
	
	# check if OUTPUT is allready ON/OFF
	my $status = ($self->{vi}->Query(":OUTPUT?") == 1) ? 'ON' : 'OFF';
	if (($output =~ /\b(ON|on)\b/ and $status eq 'ON') or ($output =~ /\b(OFF|off)\b/ and $status eq 'OFF'))
		{
		return $self->{vi}->Query(":OUTPUT?");
		}
	
	
	
	# set SOURCE AMPLITUDE to ZERO if not ZERO and in GATE-PROTECTION-MODE
	if ( $self->{config}->{gate_protect} )
		{
		# get current SOURCE AMPLITUDE
		$source_ampl = $self->_set_source_amplitude();
		if ( $status eq 'ON' )
			{
			$self->_set_source_amplitude(0);
			}
		else
			{			
			if($self->set_source_mode() =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ )
				{
				$self->_set_voltage(0);
				}
			else
				{		
				$self->set_current(0);
				}
			}
		}		
	
	# swicht OUTPUT ON/OFF 
	if ( $output =~ /\b(ON|on|OFF|off)\b/ ) {
		$self->{vi}->Write(":OUTPUT $output");
		}
	elsif ($output =~ /\b(\d+\.?\d+(e\d+|E\d+)?)?\b/)
		{
		$self->_set_source_amplitude($output);
		}
	else {
		die "unexpected value for OUTPUT STATE in sub_output. Expected values are ON/OFF or any value within the current range setting.";
		}
	
	# set SOURCE AMPLITUDE back to the original value
	if ( defined $source_ampl )
		{
		if ( $output =~/\b(OFF|off)\b/ )
			{
			if($self->set_source_mode() =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ )
				{
				$self->_set_voltage(0);
				}
			else
				{		
				$self->set_current(0);
				}
			}
		elsif ($output =~/\b(ON|on)\b/)
			{
			$self->_set_source_amplitude($source_ampl);
			}
		}	
	
	return $self->{vi}->Query(":OUTPUT?");
	}
	
sub get_output {# basic setting
	my $self = shift;
	my $mode = shift;
	
	if (not defined $mode)
		{
		$mode = 'VALUE';
		}
		
	if ($mode =~ /\b(VALUE|value)\b/)
		{
		return $self->_set_source_amplitude();
		}
	elsif($mode =~ /\b(STATE|state)\b/)
		{
		return ($self->{vi}->Query(":OUTPUT?") == 1) ? 'ON' : 'OFF';
		}
}

sub set_output_offstate { # advanced settings
	my $self = shift;
	my $offstate = shift;
	
	if ( not defined $offstate )
		{
		return $self->{vi}->Query(":OUTPUT:SMODE?");
		}
	elsif ( $offstate =~/\b(HIMPEDANCE|HIMP|himpedance|himp|NORMAL|NORM|normal|norm|ZERO|zero|GUARD|GUAR|guard|guar)\b/ ) 
		{
		return $self->{vi}->Query(":OUTPUT:SMODE $offstate; :OUTPUT:SMODE?");
		}
	else {
		die "unexpected value for OUTPUT OFF STATE in sub set_output_off_state. Expected values are HIMPEDANCE, NORMAL, ZERO or GUARD.";
		}
	}


	
# ------------------------------------ SENSE 1 subsystem ----------------------------------

sub set_sense_terminals {# advanced settings
	my $self = shift;
	my $terminals = shift;
	
	if ($terminals =~ /\b(FRONT|FRON|front|fron|REAR|rear)\b/ ){
		return $self->{vi}->Query(sprintf(":ROUTE:TERMINALS %s; :ROUTE:TERMINALS?",$terminals));
		}
	else {
		die "unexpected value for TERMINAL in sub set_terminals. Expected values are FRONT or REAR.";
		}
	

}

sub set_sense_concurrent {# advanced settings
	my $self = shift;
	my $value = shift;
	
	if ($value =~ /\b(ON|on|1|OFF|off|0)\b/){
		return $self->{vi}->Query(sprintf(":SENSE:FUNCTION:CONCURRENT %s; CONCURRENT?",$value));
		}
	else {
		die "unexpected value in sub set_concurrent. Expected values are ON, OFF, 1 or 0.";
		}
	

}

sub set_sense_onfunction {# advanced settings
	my $self = shift;
	my $list = shift;
	my @list = split(",",$list);

	if ( not defined $list )
		{
		goto RETURN;
		}
	# switch all function off first
	$self->{vi}->Write(":SENSE:FUNCTION:OFF:ALL");
	
	# switch on/off the concurrent-mode
	if ( (my $length = @list) > 1 or $list =~/\b(ALL|all)\b/)
		{
		$self->set_sense_concurrent('ON');
		}
	else
		{
		$self->set_sense_concurrent('OFF');
		}
	
	# check input data
	foreach my $onfunction (@list)	{
		if ( $onfunction =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt)\b/ ) 
			{
			$self->{vi}->Write(sprintf(":SENSE:FUNCTION:ON '%s'",$onfunction));				
			}	
		elsif ($onfunction =~ /\b(RESISTANCE|RES|resistance|res)\b/)
			{
			$self->{vi}->Write(sprintf(":SENSE:FUNCTION:ON '%s'",$onfunction));
			$self->set_sense_resistancemode('MAN');	
			$self->set_sense_resistance_zerocompensated('OFF');
			}	
		elsif ( $onfunction =~/\b(ALL|all)\b/)
			{
			$self->{vi}->Write(":SENSE:FUNCTION:ON:ALL");
			$self->set_sense_resistancemode('MAN');	
			$self->set_sense_resistance_zerocompensated('OFF');
			}
		elsif ( $onfunction =~/\b(OFF|off|NONE|none)\b/ )
			{
			$self->{vi}->Write(":SENSE:FUNCTION:OFF:ALL");
			return;
			}
		else {
			die "unexpected value in sub set_onfunction. Expected values are CURRENT, VOLTAGE, RESISTNCE and ALL.";
			}
		}
		
	# read out onfunctions
	RETURN:
	my $onfunctions = $self->{vi}->Query(":SENSE:FUNCTION:ON?");
	my @onfunctions = split(",",$onfunctions);
	$onfunctions="";
	foreach my $onfunction (@onfunctions)
		{
		if ($onfunction =~ /(VOLTAGE|VOLT|voltage|volt|CURRENT|CURR|current|curr|RESISTANCE|RES|resistance|res)/)
			{
			$onfunction = $1;
			}
		else
			{
			$onfunction = "NONE";
			}
		}
	$onfunctions = join(",",@onfunctions);
		
	return $onfunctions;
}

sub set_sense_resistancemode {# advanced settings
	my $self = shift;
	my $mode = shift;
	
	if ( $mode =~/\b(AUTO|auto|MAN|man)\b/ ) {
		$self->{vi}->Write(sprintf(":SENSE:RESISTANCE:MODE %s",$mode));
	}
	else {
		die "unexpected value for MODE in sub set_resistancemode. Expected values are AUTO or MAN.";
		}
}

sub set_sense_resistance_zerocompensated {# advanced settings
	my $self = shift;
	my $zerocompensation = shift;
	
	if ($zerocompensation  =~ /\b(ON|on|1|OFF|off|0)\b/){
		$self->{vi}->Query(sprintf(":SENSE:RES:OCOM %s; OCOM?",$zerocompensation ));
	}
	else {
		die "unexpected value for ZEROCOMPENSTION in sub set_resistance_zerocompensated. Expected values are ON, OFF, 1 or 0.";
		}

}

sub set_sense_range {# basic setting
	my $self = shift;
	my $function = shift;
	my $range = shift;
	my $llimit = shift;
	my $ulimit = shift;
	
	
	
	if ($function =~ /\b(CURRENT|CURR|current|curr)\b/) {
		if (($range >= -1.05 && $range <= 1.05) || $range =~ /\b(AUTO|auto|UP|up|DOWN|down|MIN|min|MAX|max|DEF|def)\b/)
			{$range = sprintf("%.5f", $range);}
		else {
			die "unexpected value for 'RANGE' in sub set_range. Expected values are between -1.05 and 1.05.";
			}
		}
	
	elsif($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/){		
		if (($range >= -210 && $range <= 210) || $range =~ /\b(AUTO|auto|UP|up|DOWN|down|MIN|min|MAX|max|DEF|def)\b/)
			{$range = sprintf("%.1f", $range);}
		else {
			die "unexpected value for 'RANGE' in sub set_range. Expected values are between -210 and 210.";
			}
		}
	
		
	elsif($function =~ /\b(RESISTANCE|RES|resistance|res)\b/ ){		
		if (($range >= 0 && $range <= 2.1e8) || $range =~ /\b(AUTO|auto|UP|up|DOWN|down|MIN|min|MAX|max|DEF|def)\b/)
			{$range = sprintf("%.1f", $range);}
		else {
			die "unexpected value in sub set_range for 'RANGE'. Expected values are between 0 and 2.1E8.";
			}
		}
			
	else {
		die "unexpected value for FUNCTION in sub set_range. Function can be CURRENT[:DC], VOLTAGE[:DC] or RESISTANCE";
	}
	
	
	# set range	
	my $cmd;
	if ( $range =~ /\b(AUTO|auto)\b/ ) {		
		if ( defined $llimit and  defined $ulimit and $llimit <= $ulimit) # warning: the values for llimit and ulimit are not checked by this function
			{
			$cmd = sprintf(":SENSE:%s:RANGE:AUTO ON; LLIMIT %.5f; ULIMIT %.5f; :SENSE:%s:RANGE?",$function, $llimit, $ulimit, $function);
			}
		else {
			$cmd = sprintf(":SENSE:%s:RANGE:AUTO ON; :SENSE:%s:RANGE?",$function, $function);
			}
		}
	else{
		$cmd = sprintf(":SENSE:$function:RANGE $range; RANGE?");		
		}
	my $return_range = $self->{vi}->Query($cmd);

	printf("set RANGE for %s to %s.", $function, $return_range);
	return $return_range;
	
}

sub set_complience {# basic setting
	my $self = shift;
	my $function = shift;
	my $complience = shift;
	
	
	if (not defined $function and not defined $complience)
		{
		$function = $self->set_source_mode();
		return  $self->{vi}->Query(sprintf(":SENSE:%s:PROTECTION:LEVEL?", $function));
		}
	elsif (not defined $complience and $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ or $function =~ /\b(MIN|min|MAX|max|DEF|def|AUTO|auto)\b/)
		{
		$complience = $function;
		$function = $self->set_source_mode();
		}
	
	
	if ($function =~ /\b(CURRENT|CURR|current|curr)\b/) {
		if ($complience < -210 or $complience > 210 )
			{
			die "unexpected value for COMPLIENCE in sub set_comlience. Expected values are between -210 and +210V.";
			}
		}
	
	elsif($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/){		
		if ($complience < -1.05 or $complience > 1.05 )
			{
			die "unexpected value for COMPLIENCE in sub set_comlience. Expected values are between -1.05 and +1.05A.";
			}
		}
		
	# check if $complience is valid with respect to the selected RANGE; $comlience >= 0.1%xRANGE	
	#if ($complience < 0.001*$self->{vi}->Query(sprintf(":SENSE:%s:RANGE?",$function))){
	#	die "unexpected value for COMPLIENCE in sub set_complience. COMPLIENCE must be greater than 0.001xRANGE.";
	#	}
	
	# set complience
	if ($function =~ /\b(CURRENT|CURR|current|curr)\b/) {
		return $self->{vi}->Query(sprintf(":SENSE:VOLTAGE:PROTECTION:LEVEL %e; LEVEL?",$complience));
		}
	elsif($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/){	
		return $self->{vi}->Query(sprintf(":SENSE:CURRENT:PROTECTION:LEVEL %e; LEVEL?",$complience));
		}
	

}

sub set_sense_nplc {# basic setting
	my $self = shift;
	my $function = shift;
	my $nplc = shift;
	
	# return settings if no new values are given
	if (not defined $nplc) {
		if (not defined $function){
			$function = $self->{vi}->Query(":SOURCE:FUNCTION:MODE?");
			chomp $function;
			$nplc = $self->{vi}->Query(":SENSE:$function:NPLC?");
			chomp($nplc);
			return  $nplc;
			}
		elsif ($function =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt|RESISTANCE|RES|resistance|res)\b/)
			{
			$nplc = $self->{vi}->Query(":SENSE:$function:NPLC?");
			chomp($nplc);
			return  $nplc;
			}
		elsif(($function >= 0.01 && $function <= 1000) or $function =~ /\b(MAX|max|MIN|min|DEF|def)\b/ )
			{
			$nplc = $function;
			$function = $self->{vi}->Query(":SOURCE:FUNCTION:MODE?");
			chomp $function;
			}
		else {
			die "unexpected value for FUNCTION in sub set_sense_nplc. Expected values are CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, TEMPERATURE";
		}
		
		}
	
	
	if (($nplc < 0.01 && $nplc > 1000) and not $nplc =~ /\b(MAX|max|MIN|min|DEF|def)\b/ ) {
		die "unexpected value for NPLC in sub set_sense_nplc. Expected values are between 0.01 and 1000 POWER LINE CYCLES or MIN/MAX/DEF.";
		}
	
		
	if ($function =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt|RESISTANCE|RES|resistance|res)\b/)
		{
		if($nplc > 10) 
			{
			my $averaging = $nplc/10;
			print "sub set_nplc: use AVERAGING of ".$self->set_sense_averaging($averaging)."\n";
			$nplc /= $averaging;
			}
		else
			{
			$self->set_sense_averaging('OFF');
			}
		if ($nplc =~ /\b(MAX|max|MIN|min|DEF|def)\b/ )
			{			
			return $self->{vi}->Query(sprintf(":SENSE:%s:NPLC %s; NPLC?", $function, $nplc));
			}
		elsif ($nplc =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/)	
			{
			return $self->{vi}->Query(sprintf(":SENSE:%s:NPLC %e; NPLC?", $function, $nplc));
			}
		else {
			die "unexpected value for NPLC in sub set_sense_nplc. Expected values are between 0.01 and 10 POWER LINE CYCLES or MIN/MAX/DEF.";
			}
		}
	else {
		die "unexpected value for FUNCTION in sub set_sense_nplc. Expected values are CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, TEMPERATURE";
		}
}

sub set_sense_averaging {# advanced settings
	my $self = shift;	
	my $count = shift;
	my $filter = shift;
	
	if (not defined $count and not defined $filter)
		{
		return $self->{vi}->Query(":SENSE:AVERAGE:COUNT?");
		}
	
	if ($count >= 1 and $count <= 100) {
		if (defined $filter and ($filter =~ /\b(REPEAT|REP|repeat|rep|MOVING|MOV|moving|mov)\b/)) {
			return $self->{vi}->Query(sprintf(":SENSE:AVERAGE:TCONTROL %s; COUNT %d; STATE ON; COUNT?",$filter, $count));
			}
		elsif ( not defined $filter) {
			return $self->{vi}->Query(sprintf(":SENSE:AVERAGE:TCONTROL MOV; COUNT %d; STATE ON; COUNT?", $count));
		}
		else { die "unexpected value for FILTER in sub set_averaging. Expected values are REPEAT or MOVING.";}
	}
	elsif ($count =~/\b(OFF|off|0)\b/) {
		return $self->{vi}->Query(sprintf(":SENSE:AVERAGE:STATE OFF; TCONTROL MOV; STATE?"));
	}
	else { die "unexpected value for COUNT in sub set_averaging. Expected values are between 1 and 100 or 0 or OFF to turn off averaging";}	

}





# ------------------------------------ SOURCE subsystem -----------------------------------

sub set_source_autooutputoff {# advanced settings
	my $self = shift;
	my $mode = shift;

	if ( $mode =~ /\b(ON|on|1|OFF|off|0)\b/) {
		return $self->{vi}->Query(sprintf(":SOURCE:CLEAR:AUTO %s; :SOURCE:CLEAR:AUTO?", $mode));
		}
	elsif (not defined $mode) {
		return $self->{vi}->Query(":SOURCE:CLEAR:AUTO OFF; :SOURCE:CLEAR:AUTO?");
		}
	else { die "unexpected value for MODE in sub set_sourceautooutputoff. Expected values are ON, OFF, 1 or 0.";}
}

sub set_source_mode {# basic setting
	my $self = shift;
	my $mode = shift;
	
	if ( not defined $mode)
		{
		$mode = $self->{vi}->Query(":SOURCE:FUNCTION:MODE?");
		chomp $mode;
		return $mode;
		}
	
	if ( $mode =~ /\b(CURRENT|CURR|current|curr)\b/ or $mode =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
		return $self->{vi}->Query(sprintf(":SOURCE:FUNCTION:MODE %s; :SOURCE:FUNCTION:MODE?", $mode));
		}
	else { die "unexpected value for MODE in sub set_sourcemode. Expected values are ON, OFF, 1 or 0.";}

}

sub set_source_sourcingmode {# advanced settings
	my $self = shift;
	my $function = shift;
	my $mode = shift;
	
	if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/ or $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
		if ( $mode =~ /\b(FIXED|FIX|fixed|fix)\b/ or $mode  =~/\b(LIST|list)\b/  or $mode =~ /\b(SWEEP|SWE|sweep|swe)\b/ ) {
			return $self->{vi}->Query(sprintf(":SOURCE:%s:MODE %s; :SOURCE:%s:MODE?", $function, $mode, $function));
			}
		else { die "unexpected value for MODE in sub set_sourcingmode. Expected values are FIXED, LIST or SWEEP.";}
		}
	else { die "unexpected value for FUNCTION in sub set_sourcingmode. Expected values are CURRENT or VOLTAGE.";}

}

sub set_source_range {# basic setting
	my $self = shift;
	my $function = shift;
	my $range = shift;
	
	if (not defined $function and not defined $range)
		{
		$function = $self->set_source_mode();
		return  $self->{vi}->Query(sprintf(":SOURCE:%s:RANGE?", $function));
		}
	elsif (not defined $range and $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ or $function =~ /\b(MIN|min|MAX|max|DEF|def|AUTO|auto)\b/)
		{
		$range = $function;
		$function = $self->set_source_mode();
		}
	
	
	if ($function =~ /\b(CURRENT|CURR|current|curr)\b/) {
		if (($range >= -1.05 && $range <= 1.05) || $range eq "AUTO")
			{$range = sprintf("%.5f", $range);}
		else {
			die "unexpected value in sub set_source_range for 'RANGE'. Expected values are between -1.05 and 1.05.";
			}
		}
	
	elsif($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/){		
		if (($range >= -210 && $range <= 210) || $range eq "AUTO")
			{$range = sprintf("%.1f", $range);}
		else {
			die "unexpected value in sub set_source_range for 'RANGE'. Expected values are between -210 and 210.";
			}
		}
			
	else {
		die "unexpected value in sub set_source_range. Function can be CURRENT or VOLTAGE";
	}
	
	
	# set range	
	if ( $range =~ /\b(AUTO|auto)\b/ ) {		
		$self->{vi}->Query(sprintf(":SENSE:%s:RANGE:AUTO ON",$function));
		return "AUTO";
		}
	elsif ($range =~ /\b(MIN|min|MAX|max|DEF|def)\b/)
		{
		return $self->{vi}->Query(sprintf(":SOURCE:%s:RANGE %s; RANGE?", $function, $range));
		}
	else{
		return $self->{vi}->Query(sprintf(":SOURCE:%s:RANGE %.5f; RANGE?", $function, $range));
		}


}

sub _set_source_amplitude {# internal/advanced use only
	my $self = shift;
	my $function = shift;
	my $value = shift;
	
	# check trigger status
	my $triggerstatus = $self->{vi}->Query("TRIGGER:SEQUENCE:SOURCE?");
	
	# check input data
	if ( not defined $value and not defined $function )
		{
		$function = $self->set_source_mode();
		return $self->{vi}->Query(sprintf(":SOURCE:%s?", $function));
		}
	elsif ( not defined $value and ($function =~ /\b(CURRENT|CURR|current|curr)\b/ or $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/)) 
		{
		if ($triggerstatus =~ /\b(IMMEDIATE|IMM|immediate|imm)\b/)
			{
			return $self->{vi}->Query(sprintf(":SOURCE:%s?", $function));
			}
		else
			{
			return $self->{vi}->Query(sprintf(":SOURCE:%s:TRIGGERED?", $function));
			}
		}
	
	elsif ( not defined $value and $function >= -210 and $function <= 210 ) {
		$value = $function;
		$function = $self->set_source_mode();
	}
	
	if ( ($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ and $value >= -210 and $value <= 210) or ($function =~ /\b(CURRENT|CURR|current|curr)\b/ and $value >= -1.05 and $value <= 1.05))
		{
		# set source output amplitude
		if ($triggerstatus =~ /\b(IMMEDIATE|IMM|immediate|imm)\b/) {
			if ($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/)
				{
				if($self->get_output('STATE') =~/\b(OFF|off)\b/)
					{
					return $self->_set_voltage($value);
					}
				else
					{
					return $self->set_voltage($value);
					}
				}
			else
				{
				return $self->set_current($value);
				}
			}
		else {
			return $self->{vi}->Query(sprintf(":SOURCE:%s:TRIGGERED %e; TRIGGERED?", $function, $value));
			}
		}
	else { die "unexpected value in sub _set_source_amplitude. Expected values are between -210.. +210 V or -1.05..+1.05 A";}	
	
}

sub set_source_voltagelimit { # advanced settings
	my $self = shift;
	my $limit = shift;
	
	if ( not defined $limit )
		{
		return $self->{vi}->Query(":SOURCE:VOLTAGE:PROTECTION:LIMIT?"); 
		}
	
	elsif ($limit >= -210 and $limit <= 210) 
		{
		return $self->{vi}->Query(sprintf(":SOURCE:VOLTAGE:PROTECTION:LIMIT %d; LIMIT?",$limit)); 
		}
	elsif ($limit =~ /\b(NONE|none|MIN|min|MAX|max|DEF|def)\b/)
		{
		return $self->{vi}->Query(sprintf(":SOURCE:VOLTAGE:PROTECTION:LIMIT %s; LIMIT?",$limit)); 
		}
	else 
		{
		die "unexpected value for VOLTAGE LIMIT in sub set_source_voltagelimit. Expected values are between -210..+210 V.";
		}

}

sub _set_source_delay {# internal/advanced use only
	my $self = shift;
	my $delay = shift;
	
	if (not defined $delay)
		{
		$delay = $self->{vi}->Query(":SOURCE:DELAY?");
		return chomp $delay;
		}
	
	
	if ($delay >= 0 and $delay <= 999.9999) 
		{
		$self->{vi}->Write(":SOURCE:DELAY:AUTO OFF");
		return $self->{vi}->Query(sprintf(":SOURCE:DELAY %.4f; :SOURCE:DELAY?", $delay));
		}
	elsif ( $delay =~ /\b(MIN|min|MAX|max|DEF|def)\b/)
		{
		$self->{vi}->Write(":SOURCE:DELAY:AUTO OFF");
		return $self->{vi}->Query(sprintf(":SOURCE:DELAY %s; :SOURCE:DELAY?", $delay));
		}
	elsif ( $delay =~ /\b(AUTO|auto)\b/) 
		{
		return $self->{vi}->Query(":SOURCE:DELAY:AUTO ON; :SOURCE:DELAY:AUTO?");	
		}
	else { die "unexpected value for DELAY in sub _set_source_delay. Expected values are between 0..999.9999 or AUTO";}
}

sub init_source{ #
	my $self = shift;
	my $function = shift;
	my $range = shift;
	my $complience = shift;
	
	my $sense;
	print "init source ...";
	$self->set_source_autooutputoff("OFF");
	$self->set_source_sourcingmode($function,'FIXED');
	$self->_set_source_delay('DEF');
		
	if ($self->set_sense_onfunction() =~ /\b(RESISTANCE|RES|resistance|res)\b/)
		{
		$self->set_sense_resistancemode('MAN');
		$sense = 'RES';
		}
	$self->set_source_mode($function);
	$self->set_sense_onfunction($function =~ /\b(CURRENT|CURR|current|curr)\b/ ? 'VOLT' : 'CURR'); # important for always beeing able to set the complience
	$self->set_source_range($function, $range);
	if (defined $complience) { $self->set_complience($function, $complience);}
	if (defined $sense)
		{
		$self->set_sense_onfunction($sense);
		}
	$self->set_output("ON");
	print "ok!\n";
	return;

}


# ------------------------------------ INTERNAL SOURCE FUNCTIONS -----------------------------------
sub _set_voltage { # internal use only
	my $self = shift;
	my $value = shift;	
	
	return $self->{vi}->Query(sprintf(":SOURCE:VOLT %e; VOLT?", $value));
}

sub _set_voltage_auto { # internal use only
    	my $self = shift;
	my $value = shift;	
	# not implemented for Keithley 2400
	return $self->{vi}->Query(sprintf(":SOURce:VOLTage:RANGe %e;:SOURce:VOLTage %e; VOLT?", $value,$value))
}

sub set_current {# internal/advanced use only
	my $self = shift;
	my $value = shift;	
	
	return $self->{vi}->Query(sprintf(":SOURCE:CURR %e; CURR?", $value));
}

sub _set_auto { # internal use only
	# not implemented for Keithley 2400
}

sub _get_voltage { # internal use only
	my $self = shift;

	return $self->_set_source_amplitude ('VOLTAGE');	
}

sub get_current { # internal/advanced use only
	my $self = shift;
	
	return $self->_set_source_amplitude ('CURRENT');
}



# -------------------------------------- CONFIG MEASUREMNT and SOURCE SWEEP --------------------------------
#
#
# sweep is working, but you can't define the duration of the sweep properly when performing also measurements. 
# If no ONFUNCTIONS are defined, the duration of the sweep is well defined.
#
#
# In the case of doing source-measurement-sweeps, the duration of the sweep is enlarged and depends on the settings like ...
# The number of points per sweep as well as the integration time (NPLC) give a nonlinear contribution to the total duration of the sweep.
# It alo depends on the number of ONFUNCTIONS.
# Example: Points = 2500, NPLC = 0.01, averaging = OFF, all other delays for source and trigger are set to 0 
#			--> sweep takes   9 sec --> 2500 x NPLC/50Hz = 0.5 sec
#          Points = 2500, NPLC = 0.02, averaging = OFF, all other delays for source and trigger are set to 0 
#			--> sweep takes  11 sec --> 2500 x NPLC/50Hz = 1.0 sec
#          Points = 2500, NPLC = 0.10, averaging = OFF, all other delays for source and trigger are set to 0 
#			--> sweep takes  37 sec --> 2500 x NPLC/50Hz = 5.0 sec
#          Points = 2500, NPLC = 1.00, averaging = OFF, all other delays for source and trigger are set to 0 
#			--> sweep takes 158 sec --> 2500 x NPLC/50Hz = 50.0 sec
# It is similar when choosing e.g. 1000 Points. Maybe you won't see the Problem when choosing only 100 points.
#
# BUT: Where does the difference come from ???
#
# It's the same when performing only a triggered measurment operation.
#

sub get_value { # basic setting
	my $self = shift;
	my $function = shift;
	
	if ($function eq "CURRENT:AC" || $function eq "CURRENT:DC" || $function eq "VOLTAGE:AC" || $function eq "VOLTAGE:DC" || $function eq "RESISTANCE" || $function eq "FRESISTANCE" || $function eq "PERIOD" || $function eq "FREQUENCY" || $function eq "TEMPERATURE" || $function eq "DIODE")
		{
		$self->{vi}->Write(sprintf(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS %s", $function)); # select Format for reading DATA
		my $cmd = sprintf(":MEASURE:%s?", $function);
		my $value = $self->{vi}->Query($cmd);
		return $value;
		}
	else {
		die "unexpected value for 'function' in sub get_value. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, PERIOD, FREQUENCY, TEMPERATURE, DIODE";
		}
}

sub config_measurement{ #
	my $self = shift;
	my $function = shift;
	my $nop = shift;
	my $time = shift;
	my $range = shift;
	
	if ( not defined $range )
			{
			$range = "AUTO";
			}
	
	print "init sense ...";
	$self->set_sense_terminals("FRONT");
	$self->set_sense_onfunction($function);
		
	if ($function =~ /\b(RESISTANCE|RES|resistance|res)\b/)
		{
		$self->set_sense_resistancemode('MAN');	
		$self->set_sense_resistance_zerocompensated('OFF');
		}	

	if ($function eq $self->set_source_mode())
		{
		$self->set_source_range($self->set_source_mode(), $range);
		}
	elsif ($function =~ /\b(ALL|all)\b/ )
		{
		$self->set_source_range($self->set_source_mode(), $range);
		}
	else
		{
		if ( $range <= $self->set_complience())
			{
			$self->set_sense_range($function, $range);
			}
		else
			{
			$self->set_sense_range($function,$self->set_complience());
			}
		}
		
	print "nplc = ".$self->set_sense_nplc($time*50/$nop)."\n";
	$self->_set_source_delay(0);
	$self->_set_trigger_delay(0);
	
	$self->_init_buffer($nop);
	

}

sub config_sweep {# basic setting
	my $self = shift;
	my $stop = shift;
	my $nop = shift;
	my $time = shift;
	
	if ( $time >= 2 )
		{
		$time = $time - 2; # this is a correction, because a typical sweep alwas takes 2 seconds longer than programmed. Reason unknown!
		}
	else
		{
		die "unexpected value for TIME in sub config_sweep. Expected values are between 2 ... 9999.";
		}
		
	my $function = $self->{vi}->Query(":SOURCE:FUNCTION:MODE?");
	chomp $function;
	
	print "set output = ".$self->set_output("ON")."\n";
	my $start = $self->_set_source_amplitude();
	
	print "--- config SWEEP ----\n";
	print "start = ".$self->_set_sweep_start($start);
	if ( $start != $self->_set_source_amplitude() )
		{
		$self->_set_source_amplitude($start);
		}
	print "stop = ".$self->_set_sweep_stop($stop);
	print "nop = ".$self->_set_sweep_nop($nop);
	print "step = ".$self->{vi}->Query(":SOURCE:$function:STEP?")."\n";
	
	print "source_delay = ".$self->_set_source_delay(($time)/$nop);
	print "trigger_delay = ".$self->_set_trigger_delay(0);
	print "integrationtime = ";
	my $tc = $self->set_sense_nplc(10)/50;
	print "$tc\n\n";
	
	print "set_sourcingmode: ".$self->set_source_sourcingmode($function,"SWEEP");
	print "ranging = ".$self->_set_sweep_ranging('FIXED');
	print "spacing = ".$self->_set_sweep_spacing('LIN');
	print "set ONFUNCTIONS = ".$self->set_sense_onfunction('OFF');
	print "set sourc mode = ".$self->set_source_mode($function);

	
	print "init BUFFER: ".$self->_init_buffer($nop)."\n";
	
	print "ready to SWEEP\n";
	
}

sub config_IV {# basic setting
	my $self = shift;
	my $start = shift;
	my $stop = shift;
	my $nop = shift;
	my $nplc = shift;
	my $ranging = shift;
	my $spacing = shift;
	
	# check DATA	
	if( not defined $spacing ) 
		{
		$spacing = 'LIN';
		}
	if( not defined $ranging ) 
		{
		$ranging = 'FIXED';
		}
	if( not defined $nplc ) 
		{
		$nplc = 1;
		}
	if( not defined $nop ) 
		{
		$nop  = 2500;
		}
		

	# config SWEPP parameters	
	print "\n--- config SWEEP ----\n";
	
	print "set sourc mode = ".$self->set_source_mode('VOLT');
	print "set ONFUNCTIONS = ".$self->set_sense_onfunction('CURR,VOLT');
	print "set output = ".$self->set_output("ON")."\n";
	
	print "start = ".$self->_set_sweep_start($start);
	if ( $start != $self->_set_source_amplitude() )
		{
		$self->_set_source_amplitude($start);
		}
	print "stop = ".$self->_set_sweep_stop($stop);
	print "nop = ".$self->_set_sweep_nop($nop);
	print "step = ".$self->{vi}->Query(":SOURCE:VOLT:STEP?")."\n";
	
	print "source_delay = ".$self->_set_source_delay(0);
	print "trigger_delay = ".$self->_set_trigger_delay(0);
	print "integrationtime = ";
	my $tc = $self->set_sense_nplc($nplc)/50;
	print "$tc\n\n";
	
	print "set_sourcingmode: ".$self->set_source_sourcingmode('VOLT',"SWEEP");
	print "ranging = ".$self->_set_sweep_ranging($ranging);
	print "spacing = ".$self->_set_sweep_spacing($spacing);
	print "init BUFFER: ".$self->_init_buffer($nop)."\n";
	
	print "ready to record an IV-trace.\n";
}

sub config_VI {# basic setting
	my $self = shift;
	my $start = shift;
	my $stop = shift;
	my $nop = shift;
	my $nplc = shift;
	my $ranging = shift;
	my $spacing = shift;
	
	# check DATA	
	if( not defined $spacing ) 
		{
		$spacing = 'LIN';
		}
	if( not defined $ranging ) 
		{
		$ranging = 'FIXED';
		}
	if( not defined $nplc ) 
		{
		$nplc = 1;
		}
	if( not defined $nop ) 
		{
		$nop  = 2500;
		}
		

	# config SWEPP parameters	
	print "\n--- config SWEEP ----\n";
	
	print "set sourc mode = ".$self->set_source_mode('CURR');
	print "set ONFUNCTIONS = ".$self->set_sense_onfunction('VOLT,CURR');
	print "set output = ".$self->set_output("ON")."\n";
	
	print "start = ".$self->_set_sweep_start($start);
	if ( $start != $self->_set_source_amplitude() )
		{
		$self->_set_source_amplitude($start);
		}
	print "stop = ".$self->_set_sweep_stop($stop);
	print "nop = ".$self->_set_sweep_nop($nop);
	print "step = ".$self->{vi}->Query(":SOURCE:CURR:STEP?")."\n";
	
	print "source_delay = ".$self->_set_source_delay(0);
	print "trigger_delay = ".$self->_set_trigger_delay(0);
	print "integrationtime = ";
	my $tc = $self->set_sense_nplc($nplc)/50;
	print "$tc\n\n";
	
	print "set_sourcingmode: ".$self->set_source_sourcingmode('CURR',"SWEEP");
	print "ranging = ".$self->_set_sweep_ranging($ranging);
	print "spacing = ".$self->_set_sweep_spacing($spacing);
	
	
	print "init BUFFER: ".$self->_init_buffer($nop)."\n";
	
	print "ready to record an VI-trace.\n";
}

sub get_data { # basic setting
	my $self = shift;
	return $self->_read_buffer();
}

sub trg {# basic setting
	my $self = shift;
	$self->{vi}->Write(":INITIATE:IMMEDIATE");
	
}

sub active { # basic
	my $self = shift;
	my $timeout = shift;
	
	if ( not defined $timeout )
		{
		$timeout = 100;
		}

	my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout);
	if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
	
	# check if measurement has been finished
	if ($self->{vi}->Query(":STATUS:OPERATION:CONDITION?") == 1024) 
		{
		return 0;
		}
	else 
		{
		return 1;
		}
	
	my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
	if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
}

sub wait { # basic
	my $self = shift;
	my $timeout = shift;
	
	if ( not defined $timeout )
		{
		$timeout = 100;
		}

	my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout);
	if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
	
	
	print "waiting for data ... \n";
	while (1)
		{
		if ($self->{vi}->Query(":STATUS:OPERATION:CONDITION?") == 1024) {last;} # check if measurement has been finished
		else {usleep(1e5);}
		}
		
	my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
	if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}

}



sub _set_sweep_ranging {# internal/advanced use only
	my $self = shift;
	my $ranging = shift;
	
	if ( $ranging =~ /\b(BEST|best|FIXED|FIX|fixed|fix|AUTO|auto)\b/ ) {
		return $self->{vi}->Query(sprintf(":SOURCE:SWEEP:RANGING %s; :SOURCE:SWEEP:RANGING?", $ranging));
	}
	else { die "unexpected vlaue for RANGING in sub _set_sweep_ranging. Expected values are BEST, FIXED or AUTO.";}
}

sub _set_sweep_spacing {# internal/advanced use only
	my $self = shift;
	my $spacing = shift;
	
	if ( $spacing =~ /\b(LINEAR|LIN|linear|lin|LOGARITHMIC|LOG|logarithmic|log)\b/ ) {
		return $self->{vi}->Query(sprintf(":SOURCE:SWEEP:SPACING %s; :SOURCE:SWEEP:SPACING?", $spacing));
	}
	else { die "unexpected vlaue for SPACING in sub set_sweep_spaceing. Expected values are LIN or LOG.";}
}

sub _set_sweep_start {# internal/advanced use only
	my $self = shift;
	my $function = shift;
	my $start = shift;
	
	if ( not defined $start and $function >= -210 and $function <= 210 ) {
		$start = $function;
		$function = $self->{vi}->Query(":SOURCE:FUNCTION:MODE?");
		chomp $function;
	}
	else { die "unexpected value in sub _set_sweep_start. Expected values are between -210.. +210 V or -1.05..+1.05 A";}
	

	
	
	if ($function=~ /\b(CURRENT|CURR|current|curr)\b/ and ($start < -1.05 or $start > 1.05 )) {
		die "unexpected value in sub _set_sweep_start. Expected values are between -1.05 and 1.05.";		
		}
	elsif($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ and ($start < -210 or $start > 210)){		
		die "unexpected value in sub _set_sweep_start. Expected values are between -210 and 210.";
		}		
	elsif ($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ or $function=~ /\b(CURRENT|CURR|current|curr)\b/)
		{
		# set startvalue for sweep
		return $self->{vi}->Query(sprintf(":SOURCE:%s:START %.11f; :SOURCE:%s:START?", $function, $start, $function));
		}
	else
		{
		die "unexpected value in sub _set_sweep_start. Function can be CURRENT or VOLTAGE, startvalue is expected to be between -1.05...+1.05A or -210...+210V";
		}
	
}

sub _set_sweep_stop {# internal/advanced use only
	my $self = shift;
	my $function = shift;
	my $stop = shift;
	
	if ( not defined $stop and $function >= -210 and $function <= 210 ) {
		$stop = $function;
		$function = $self->{vi}->Query(":SOURCE:FUNCTION:MODE?");
		chomp $function;
	}
	else { die "unexpected value in sub _set_sweep_stop. Expected values are between -210.. +210 V or -1.05..+1.05 A";}
	
	
	if ($function=~ /\b(CURRENT|CURR|current|curr)\b/ and ($stop < -1.05 or $stop > 1.05 )) {
		die "unexpected value in sub _set_sweep_start. Expected values are between -1.05 and 1.05.";		
		}
	elsif($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ and ($stop < -210 or $stop > 210)){		
		die "unexpected value in sub _set_sweep_start. Expected values are between -210 and 210.";
		}		
	elsif ($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ or $function=~ /\b(CURRENT|CURR|current|curr)\b/)
		{
		# set stop value for sweep
		return $self->{vi}->Query(sprintf(":SOURCE:%s:STOP %.11f; :SOURCE:%s:STOP?", $function, $stop, $function));
		}
	else
		{
		die "unexpected value in sub _set_sweep_stop. Function can be CURRENT or VOLTAGE, startvalue is expected to be between -1.05...+1.05A or -210...+210V";
		}

}

sub _set_sweep_step {# internal/advanced use only
	my $self = shift;
	my $function = shift;
	my $step = shift;
	
	if ( not defined $step and $function >= -420 and $function <= 420 ) {
		$step = $function;
		$function = $self->{vi}->Query(":SOURCE:FUNCTION:MODE?");
		chomp $function;
	}
	else { die "unexpected value in sub _set_sweep_step. Expected values are between -420.. +420V or -2.1..+2.1A";}
	

	
	if ($function =~ /\b(CURRENT|CURR|current|curr)\b/ and ($step < -2.1 or $step > 2.1 )) {
		die "unexpected value in sub _set_sweep_step. Expected values are between -2.1 and 2.1A.";		
	}
	elsif($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ and ($step < -420 or $step > 420)){		
		die "unexpected value in sub _set_sweep_step. Expected values are between -420 and 420A.";
	}		
	else {
		die "unexpected value in sub _set_sweep_step. Function can be CURRENT or VOLTAGE, startvalue is expected to be between -420.. +420V or -2.1..+2.1A";
	}
	
	# check if step matches to start and stop values
	my $start = $self->{vi}->Query(":SOURCE:%s:START?");
	my $stop = $self->{vi}->Query(":SOURCE:%s:STOP?");
	
	if (int(($stop-$start)/$step) != ($stop-$start)/$step) {
		die "ERROR in sub _set_sweep_step. STOP-START/STEP must be an integer value.";
		}
	
	# set startvalue for sweep
	$self->{vi}->Query(sprintf(":SOURCE:%s:STEP %f.11", $function, $step));
	return abs(($stop-$start)/$step+1); # return number of points

}

sub _set_sweep_nop {# internal/advanced use only
	my $self = shift;
	my $nop = shift;
	
	
	if ($nop >= 1 and $nop <= 2500 ) {
		$self->_set_trigger_count($nop);
		return $self->{vi}->Query(sprintf(":SOURCE:SWEEP:POINTS %d; POINTS?",$nop));
	}
	else { die "unexpected value in sub _set_sweep_step. Expected values are between 1..2500";}	

}



# ------------------------------------ DATA BUFFER ----------------------------------------

sub _clear_buffer { # internal/advanced use only
	my $self = shift;
	$self->{vi}->Write(":DATA:FEED:CONTROL NEVER");
	$self->{vi}->Write(":DATA:CLEAR");
}

sub _init_buffer { # internal/advanced use only
	my $self = shift;
	my $nop = shift;
		
	$self->_clear_buffer();
	
	my $function = $self->set_sense_onfunction();
	if ( $function eq "NONE" )
		{
		$self->{vi}->Query(sprintf(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS %s; ELEMENTS?", $self->set_source_mode())); # select Format for reading DATA
		}
	else
		{
		$self->{vi}->Query(sprintf(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS %s; ELEMENTS?", $function)); # select Format for reading DATA
		}
	
	if ( $nop >= 2 && $nop <=2500) {
		my $return_nop = $self->{vi}->Query(sprintf(":DATA:POINTS %d; :DATA:POINTS?", $nop));
		$self->{vi}->Write(":DATA:FEED SENSE"); # select raw-data to be stored.
		$self->{vi}->Write(":DATA:FEED:CONTROL NEXT"); # enable data storage
		$self->{vi}->Write(sprintf(":TRIGGER:COUNT %d",$return_nop)); # set samplecount to buffersize. this setting may not be most general.
		return $return_nop;
		}
	else{
		die "unexpected value in sub set_nop_for_buffer. Must be between 2 and 2500.";
		}
}

sub _read_buffer { # internal/advanced use only
	my $self = shift;
	my $print = shift;
	
	# wait until data are available	
	$self->wait();
	
	# get number of ONFUNCTIONS
	my $onfunctions = $self->set_sense_onfunction();
	my @list = split(",",$onfunctions);
	my $num_of_onfunctions = @list;
	
	# enlarge Query-TIMEOUT
	my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, 20000);
	if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
	
	# read data
	print "please wait while reading DATA ... \n";
	my $data = $self->{vi}->LongQuery("DATA:DATA?");
	chomp $data;
	my @data = split(",",$data);
	
	# Query-TIMEOUT back to default value
	my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
	if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
	
	# split data ( more than one onfunction )
	if ( $num_of_onfunctions > 1 )
		{
		my @DATA;
		for ( my $i = 0; $i < @data; $i++ )
			{
			$DATA[$i%$num_of_onfunctions][int($i/3)] = $data[$i];
			}
		
		if ($print eq "PRINT")
			{
			foreach my $item (@DATA)
				{
				foreach my $i (@$item)
					{
					print "$i\t";
					}
				print "\n";
				}
			}
			
		return @DATA;
		}
		
	if ($print eq "PRINT")
		{
		foreach my $i (@data)
			{
			print $i."\n";
			}
		}
		
	return @data	
}




# -------------------------------------- TRIGGER ----------------------------------------------

sub _set_trigger_count{# internal/advanced use only
	my $self = shift;
	my $triggercount = shift;
	
	if ($triggercount >=1 && $triggercount <=2500) {
		return $self->{vi}->Query(sprintf(":TRIGGER:COUNT %d; COUNT?",$triggercount));
		}
	else {
		die "unexpected value for TRIGGERCOUNT in  sub _set_trigger_count. Must be between 1 and 2500.";
		}
}

sub _set_trigger_delay{# internal/advanced use only
	my $self = shift;
	my $triggerdelay = shift;
	
	if (not defined $triggerdelay)
		{
		$triggerdelay = $self->{vi}->Query(":TRIGGER:DELAY?");
		return chomp $triggerdelay;
		}
	
	if ($triggerdelay >= 0 && $triggerdelay <=999999.999) {
		print "triggerdelay = ".$triggerdelay."\n";
		return $self->{vi}->Query(sprintf(":TRIGGER:DELAY %.3f; DELAY?",$triggerdelay));
		}
	elsif ($triggerdelay =~ /\b(MIN|min|MAX|max|DEF|def)\b/)
		{
		print "triggerdelay = ".$triggerdelay."\n";
		return $self->{vi}->Query(sprintf(":TRIGGER:DELAY %s; DELAY?",$triggerdelay));
		}
	else {
		die "unexpected value for TRIGGERDELAY in  sub _set_trigger_delay. Must be between 0 and 999999.999sec.";
		}
		
}

sub _set_timer { # internal/advanced use only
	my $self = shift;
	my $timer = shift;
	
	if ($timer >= 0 && $timer <=999999.999) {
		$self->{vi}->Write(sprintf(":ARM:TIMER %.3f",$timer));
		}
	else {
		die "unexpected value for TIMER in  sub _set_timer. Must be between 0 and 999999.999sec.";
		}
}




# -----------------------------------------DISPLAY --------------------------------

sub display_on {# basic setting
    my $self=shift;
    $self->{vi}->Write(":DISPLAY:ENABLE 1");
}

sub display_off {# basic setting
    my $self=shift;
    $self->{vi}->Write(":DISPLAY:ENABLE 0"); # when display is disabled, the instrument operates at a higher speed. Frontpanel commands are frozen.
}


sub display_text {# basic setting
    my $self=shift;
    my $text=shift;
    
    if ($text) {
        $self->{vi}->Write(qq(DISPLAY:TEXT "$text"));
    } else {
        chomp($text=$self->{vi}->Query(qq(DISPLAY:TEXT?)));
        $text=~s/\"//g;
    }
    return $text;
}

sub display_clear {# basic setting
    my $self=shift;
    $self->{vi}->Write("DISPlay:TEXT:STATE 0");
}


# ----------------------------------------------------------------------------------------


1;


=head1 NAME

Lab::Instrument::Keithley2400 - Keithley 2400 digital multimeter

=head1 SYNOPSIS

    use Lab::Instrument::Keithley2400;
    
    my $DMM=new Lab::Instrument::Keithley2400(0,GPIB-address);
    print $DMM->get_value('VOLTAGE:DC');

=head1 DESCRIPTION

The Lab::Instrument::Keithley2400 class implements an interface to the Keithley 2400 digital multimeter.

=head1 CONSTRUCTOR

    my $DMM=new(\%options);

=head1 METHODS

=head2 get_value

    $value=$DMM->get_value($function);

Make a measurement defined by $function with the previously specified range
and integration time.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2400.
	"CURRENT", "current", "CURR", "curr", "CURRENT:DC", "current:dc", "CURR:DC", "curr:dc" --> DC current measurement 
	"CURRENT:AC", "current:ac", "CURR:AC", "curr:ac" --> AC current measurement 
	"VOLTAGE", "voltage", "VOLT", "volt", "VOLTAGE:DC", "voltage:dc", "VOLT:DC", "volt:dc" --> DC voltage measurement 
	"VOLTAGE:AC", "voltage:ac", "VOLT:AC", "volt:ac" --> AC voltage measurement 
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)

=back

=head2 get_temperature

    $value=$DMM->get_value($sensor, $function, $range);

Make a measurement defined by $function with the previously specified range
and integration time.

=over 4

=item $sensor

SENSOR can be one of the Temperature-Diodes defined in Lab::Instrument::TemperatureDiodes.


=item $function

FUNCTION can be one of the measurement methods of the Keithley2400.
	"DIODE", "DIOD", "diode", "diod" --> read out temperatuer diode
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)
	
=item $range
	
RANGE is given in terms of amps or ohms and can be C< 1e-5 | 1e-4 | 1e-3 | MIN | MAX | DEF > or C< 0...101e6 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=back
=head2 config_measurement

	$K2400->config_measurement($function, $range, $number_of_points, $nplc);

Preset the Keithley2400 for a TRIGGERED measurement.
WARNING: It's not recomended to perform triggered measurments with the KEITHLEY 2000 DMM due to unsolved timing problems!!!!!

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2400.
	"CURRENT", "current", "CURR", "curr", "CURRENT:DC", "current:dc", "CURR:DC", "curr:dc" --> DC current measurement 
	"CURRENT:AC", "current:ac", "CURR:AC", "curr:ac" --> AC current measurement 
	"VOLTAGE", "voltage", "VOLT", "volt", "VOLTAGE:DC", "voltage:dc", "VOLT:DC", "volt:dc" --> DC voltage measurement 
	"VOLTAGE:AC", "voltage:ac", "VOLT:AC", "volt:ac" --> AC voltage measurement 
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)

=item $range

RANGE is given in terms of amps, volts or ohms and can be C< 0...+3,03A | MIN | MAX | DEF | AUTO >, C< 0...757V(AC)/1010V(DC) | MIN | MAX | DEF | AUTO > or C< 0...101e6 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=item $number_of_points

Preset the NUMBER OF POINTS to be taken for one measurement trace.
The single measured points will be stored in the internal memory of the Keithley2400.
For the Keithley2400 the internal memory is limited to 1024 values.


=item $nplc

Preset the NUMBER of POWER LINE CYCLES which is actually something similar to an integration time for recording a single measurement value.
The values for $nplc can be any value between 0.01 ... 10.
Example: Assuming $nplc to be 10 and assuming a netfrequency of 50Hz this results in an integration time of 10*50Hz = 0.2 seconds for each measured value. Assuming $number_of_points to be 100 it takes in total 20 seconds to record all values for the trace.



=head2 trg

	$K2400->trg();

Sends a trigger signal via the GPIB-BUS to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Keithley2400.

=head2 abort

    $K2400->abort();

Aborts current (triggered) measurement.


=head2 get_data

	@data = $K2400->get_data();
	
Reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
Reading the buffer will start immediately after the triggered measurement has finished. The LabVisa-script cannot be continued until all requested readings have been recieved.




=head2 set_function

	$K2400->set_function($function);
	
Set a new value for the measurement function of the Keithley2400.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2400.
	"CURRENT", "current", "CURR", "curr", "CURRENT:DC", "current:dc", "CURR:DC", "curr:dc" --> DC current measurement 
	"CURRENT:AC", "current:ac", "CURR:AC", "curr:ac" --> AC current measurement 
	"VOLTAGE", "voltage", "VOLT", "volt", "VOLTAGE:DC", "voltage:dc", "VOLT:DC", "volt:dc" --> DC voltage measurement 
	"VOLTAGE:AC", "voltage:ac", "VOLT:AC", "volt:ac" --> AC voltage measurement 
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)
	

=head2 set_range

	$K2400->set_range($function,$range);
	
Set a new value for the predefined RANGE for the measurement function $function of the Keithley2400.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2400.
	"CURRENT", "current", "CURR", "curr", "CURRENT:DC", "current:dc", "CURR:DC", "curr:dc" --> DC current measurement 
	"CURRENT:AC", "current:ac", "CURR:AC", "curr:ac" --> AC current measurement 
	"VOLTAGE", "voltage", "VOLT", "volt", "VOLTAGE:DC", "voltage:dc", "VOLT:DC", "volt:dc" --> DC voltage measurement 
	"VOLTAGE:AC", "voltage:ac", "VOLT:AC", "volt:ac" --> AC voltage measurement 
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)

	
=item $range

RANGE is given in terms of amps, volts or ohms and can be C< 0...+3,03A | MIN | MAX | DEF | AUTO >, C< 0...757V(AC)/1010V(DC) | MIN | MAX | DEF | AUTO > or C< 0...101e6 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.



=head2 set_nplc

	$K2400->set_nplc($function,$nplc);
	
Set a new value for the predefined NUMBER of POWER LINE CYCLES for the measurement function $function of the Keithley2400.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2400.
	"CURRENT", "current", "CURR", "curr", "CURRENT:DC", "current:dc", "CURR:DC", "curr:dc" --> DC current measurement 
	"CURRENT:AC", "current:ac", "CURR:AC", "curr:ac" --> AC current measurement 
	"VOLTAGE", "voltage", "VOLT", "volt", "VOLTAGE:DC", "voltage:dc", "VOLT:DC", "volt:dc" --> DC voltage measurement 
	"VOLTAGE:AC", "voltage:ac", "VOLT:AC", "volt:ac" --> AC voltage measurement 
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)
	
=item $nplc

Preset the NUMBER of POWER LINE CYCLES which is actually something similar to an integration time for recording a single measurement value.
The values for $nplc can be any value between 0.01 ... 10.
Example: Assuming $nplc to be 10 and assuming a netfrequency of 50Hz this results in an integration time of 10*50Hz = 0.2 seconds for each measured value. Assuming $number_of_points to be 100 it takes in total 20 seconds to record all values for the trace.
 
=head2 set_averaging

	$K2400->set_averaging($count, $filter);
	
Set a new value for the predefined NUMBER of POWER LINE CYCLES for the measurement function $function of the Keithley2400.

=over 4

=item $count

COUNT is the number of readings to be taken to fill the AVERAGING FILTER. COUNT can be 1 ... 100.
	
=item $filter

FILTER can be MOVING or REPEAT. A detailed description is refered to the user manual.
 
=head2 display_on

    $K2400->display_on();

Turn the front-panel display on.

=head2 display_off

    $K2400->display_off();

Turn the front-panel display off.

=head2 display_text

    $K2400->display_text($text);
    print $K2400->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 display_clear

    $K2400->display_clear();

Clear the message displayed on the front panel.


=head2 reset

    $K2400->reset();

Reset the multimeter to its power-on configuration.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT
