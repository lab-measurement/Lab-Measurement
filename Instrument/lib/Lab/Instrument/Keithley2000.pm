package Lab::Instrument::Keithley2000;


use strict;
use Lab::Instrument;
use Lab::Instrument::TemperatureDiodes;
use Time::HiRes qw (usleep);


our $VERSION = sprintf("0.%04d", q$Revision: 650 $ =~ / (\d+) /);

# ---------------------- Init DMM --------------------------------------------------------

sub new { # basic
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self
}

sub reset { # basic
	my $self = shift;
	$self->{vi}->Write("*RST");
	return "RESET";
}


# ----------------------- Config DMM ------------------------------------------------------

sub set_function { # basic
	my $self = shift;
	my $function = shift;
	
	if (not defined $function){
		$function =  $self->{vi}->Query(":SENSE:FUNCTION?");
		chomp($function); # cut off \n\r
		return substr($function,1,-1); # cut off quotes ""
	}
	
	if ($function =~ /\b(PERIOD|period|PER|per|FREQUENCY|frequency|FREQ|freq|TEMPERATURE|temperature|TEMP|temp|DIODE|diode|DIOD|diod","CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac","CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/)
		{
		return $self->{vi}->Query(sprintf(":SENSE:FUNCTION '%s'; FUNCTION?", $function)); 
		}
	else {
		die "unexpected value in sub config_function. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, PERIOD, FREQUENCY, TEMPERATURE, DIODE";
		}
}

sub set_range { # basic
	my $self = shift;
	my $function = shift;
	my $range = shift;
	
	# return settings
	if (not defined $range) {
		if (not defined $function) {
			$function = $self->set_function();
			}
		$range = $self->{vi}->Query(":SENSE:$function:RANGE?");
		chomp($range);
		return $range;
		}
	
	#set range
	if ($function =~ /\b(CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac","CURRENT:DC|current:dc|CURR:DC|curr:dc)\b/) {
		if (($range >= 0 && $range <= 3.03) || $range =~/\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/)
			{$range = sprintf("%.2f", $range);}
		else {
			die "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 3.03.";
			}
		}
	
	elsif($function =~ /\b(VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac)\b/)
		{
		if (($range >= 0 && $range <= 757.5) || $range =~/\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/)
			{
			$range = sprintf("%.1f", $range);
			}
		else 
			{
			die "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 757.5.";
			}
		}
	elsif($function =~ /\b(VOLTAGE|voltage|VOLT|volt|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc)\b/)
		{		
		if (($range >= 0 && $range <= 1010) || $range =~/\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/)
			{
			$range = sprintf("%.1f", $range);
			}
		else 
			{
			die "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 1010.";
			}
		}
	elsif($function =~ /\b(RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/){		
		if (($range >= 0 && $range <= 101e6) || $range =~/\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/)
			{$range = sprintf("%d", $range);}
		else {
			die "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 101E6.";
			}
		}
	elsif($function =~ /\b(DIODE|DIOD|diode|diod)\b/){
		$function = "DIOD:CURRENT";
		if ($range < 0 || $range > 1e-3){
			die "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 1E-3.";
			}
		}	
	else {
		die "unexpected value in sub config_range. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE";
	}
	
	
	# set range	
	if ( $range =~/\b(AUTO|auto)\b/ ) {
		return $self->{vi}->Query(sprintf(":SENSE:%s:RANGE:AUTO ON; RANGE?",$function));
		}
	elsif ( $range =~/\b(MIN|min|MAX|max|DEF|def)\b/ )
		{
		return $self->{vi}->Query(sprintf(":SENSE:%s:RANGE %s; RANGE?", $function, $range));
		}
	else{
		return $self->{vi}->Query(sprintf(":SENSE:%s:RANGE %.2f; RANGE?", $function, $range));
		}
	
}

sub set_nplc {# basic
	my $self = shift;
	my $function = shift;
	my $nplc = shift;
	
	# return settings if no new values are given
	if (not defined $nplc) {
		if (not defined $function){
			$function = $self->set_function();
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
			$function = $self->set_function();
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
			print "sub set_nplc: use AVERAGING of ".$self->set_averaging($averaging)."\n";
			$nplc /= $averaging;
			}
		else
			{			
			$self->set_averaging('OFF');
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

sub set_averaging { # advanced
	my $self = shift;
	my $count = shift;
	my $mode = shift;
	
	my $function = $self->set_function(); # get selected function
	
	# return settings if no new values are given
	if (not defined $count) { return $self->{vi}->Query(":SENSE:$function:AVERAGE:STATE?; COUNT?; TCONTROL?");}	
	
	
	# check given data
	if (not defined $mode) { $mode = "REPEAT";} # set REPeating as standard value; MOVing would be 2nd option
	
	if ($mode =~ /\b(REPEAT|repeat|MOVING|moving)\b/)
		{
		if ($count >= 0.5 and $count <= 100.5)
			{
			# set averaging	
			$self->{vi}->Write(":SENSE:$function:AVERAGE:STATE ON");
			$self->{vi}->Write(":SENSE:$function:AVERAGE:TCONTROL $mode");
	
			if ($count =~/\b(MIN|min|MAX|max|DEF|def)\b/ or $count =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ ) 
				{
				$count = $self->{vi}->Query(":SENSE:$function:AVERAGE:COUNT $count; STATE?; COUNT?; TCONTROL?");
				chomp ($count);
				return $count;
				}
			}
		elsif ( $count =~ /\b(OFF|off)\b/ or $count == 0 )
			{
			$self->{vi}->Write(":SENSE:$function:AVERAGE:STATE OFF"); # switch OFF Averaging
			return $self->{vi}->Query(":SENSE:$function:AVERAGE:STATE?");
			}
		else
			{
			die "unexpected value for COUNT in sub set_averaging. Expected values are between 1 ... 100 or MIN/MAX/DEF/OFF.";
			}
		
		}
	else
		{
		die "unexpected value for FILTERMODE in sub set_averaging. Expected values are REPEAT and MOVING.";
		}	
	
		
	
	
	
	
}





# ----------------------------------------- MEASUREMENT ----------------------------------

sub get_value { # basic
	my $self = shift;
	my $function = shift;
	
	if ($function =~ /\b(PERIOD|period|PER|per|FREQUENCY|frequency|FREQ|freq|TEMPERATURE|temperature|TEMP|temp|DIODE|diode|DIOD|diod|CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac|CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/)
		{
		my $cmd = sprintf(":MEASURE:%s?", $function);
		my $value = $self->{vi}->Query($cmd);
		return $value;
		}
	else {
		die "unexpected value for 'function' in sub measure. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, PERIOD, FREQUENCY, TEMPERATURE, DIODE";
		}
}

sub get_temperature { # basic
	my $self = shift;
	my $sensor = shift;
	my $function = shift;
	my $range = shift;
	
	# check if given sensorname is in sensors list
	if ( not Lab::Instrument::TemperatureDiodes->valid_sensor($sensor))
		{
		die "unexpected value for SENSOR in sub temperature. Expected values are defined in package Lab::Instrument::TemperatureDiodes.pm -> SENSOR."
		}		
	
	# check measurment mode
	if (not defined $function) 
		{
		$function = "DIODE";
		}
		
	if ($function =~ /\b(DIODE|diode|DIOD|diod|RESISTNACE|fresistance|FRES|fres)\b/) 
		{
		# set range
		if (not defined $range) {$range = "DEF";}
		$self->set_range($function,$range);
	
		# measure temperature
		my $value = $self->measure($function);
		return Lab::Instrument::TemperatureDiodes->convert2Kelvin($value,$sensor);
		}
	else
		{
		die "unexpected value for FUNCTION in sub temperature. Expected values are DIODE and FRESISTANCE.";
		}	

}

sub config_measurement { # basic
	my $self = shift;
	my $function = shift;
	my $range = shift;
	my $nplc = shift;
	my $nop = shift;
	my $trigger = shift;
	
	# check input data
	if (not defined $trigger)
		{
		$trigger = 'BUS';
		}
	if (not defined $nop)
		{
		$nop = 2500;
		}
	if (not defined $nplc)
		{
		$nplc = 1;
		}
	if (not defined $range)
		{
		$range = 'DEF';
		}
	if (not defined $function)
		{
		die "too view arguments given in sub config_measurement. Expected arguments are FUNCTION, <RANGE>, <NPLC>, <#POINTS>, <TRIGGERSOURCE>";
		}

	$self->set_function($function);
	print "sub config_measurement: set FUNCTION: ".$self->set_function()."\n";
	
	$self->set_range($function, $range);
	print "sub config_measurement: set RANGE: ".$self->set_range()."\n";
		
	$self->set_nplc($function, $nplc);	
	print "sub config_measurement: set NPLC: ".$self->set_nplc()."\n";

	$self->_init_buffer($nop);
	print "sub config_measurement: init BUFFER: ".$self->_init_buffer($nop)."\n";

	$self->_init_trigger($trigger);
	print "sub config_measurement: init TRIGGER: ".$self->_init_trigger($trigger)."\n";
	
	
	return $nplc;
	
}

sub trg { # basic
	my $self = shift;
	$self->{vi}->Write("*TRG");
}

sub abort { # basic
	my $self = shift;
	$self->{vi}-Write("ABORT");
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

sub get_data { # basic
	my $self = shift;
	return $self->_read_buffer();
}





# ------------------------------------ DATA BUFFER ----------------------------------------

sub _clear_buffer { # internal
	my $self = shift;
	$self->{vi}->Write(":DATA:CLEAR");
	return $self->{vi}->Query(":DATA:FREE?");
}

sub _init_buffer { # internal
	my $self = shift;
	my $nop = shift;
	
	$self->_clear_buffer();
	
	if ( $nop >= 2 && $nop <=1024) {
		$self->{vi}->Write("*CLS");
		$self->{vi}->Write(":STATUS:OPERATION:ENABLE 16"); # enable status bit for measuring/idle status
		$self->{vi}->Write("INIT:CONT OFF"); # set DMM to IDLE-state
		$self->_init_trigger("BUS"); # trigger-count = 1, trigger-delay = 0s, trigger-source = IMM/EXT/TIM/MAN/BUS
		$self->_set_triggercount(1);	
		$self->_set_triggerdelay(0);
		my $return_nop = $self->_set_samplecount($nop);		
		$self->{vi}->Write(":INIT"); # set DMM from IDLE to WAIT-FOR_TRIGGER status
		return $return_nop;
		}
	else{
		die "unexpected value in sub set_nop_for_buffer. Must be between 2 and 1024.";
		}
}

sub _read_buffer { # basic
	my $self = shift;
	my $print = shift;
	
	# wait until data are available	
	$self->wait();
	
	#read data
	$self->{vi}->Write(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS READING"); # select Format for reading DATA
	my $data = $self->{vi}->LongQuery(":DATA:DATA?");
	chomp $data;
	my @data = split(",",$data);
	
	#print data
	if ($print eq "PRINT"){
		foreach my $item (@data) {print $item."\n";}
		}
	
	return @data	
}





# -------------------------------------- TRIGGER ----------------------------------------------

sub _init_trigger { # internal
	my $self = shift;
	my $source = shift;
	
	if (not defined $source) {$source ="BUS";} # set BUS as default trigger source
	
	$self->_set_triggercount("DEF"); # DEF = 1
	$self->_set_triggerdelay("DEF"); # DEF = 0
	$self->_set_triggersource("BUS");
	
	return "trigger initiated";
	
}

sub _set_triggersource { # internal
	my $self = shift;
	my $triggersource = shift;
	
	#return setting
	if (not defined $triggersource){
		$triggersource =  $self->{vi}->Query(":TRIGGER:SOURCE?");
		chomp($triggersource);
		return $triggersource;
		}
	
	#set triggersoource
	if ( $triggersource =~ /\b(IMM|imm|EXT|ext|TIM|tim|MAN|man|BUS|bus)\b/ ) {
		return $self->{vi}->Query(sprintf(":TRIGGER:SOURCE %s; SOURCE?", $triggersource));
		}
	else {
		die "unexpected value for SOURCE in sub _init_trigger. Must be IMM, EXT, TIM, MAN or BUS.";
		}
}

sub _set_samplecount { # internal
	my $self = shift;
	my $samplecount = shift;
	
	#return setting
	if (not defined $samplecount){
		$samplecount = $self->{vi}->Query(":SAMPLE:COUNT?");
		chomp($samplecount);
		return $samplecount;
		}
	
	#set samplecount
	if ($samplecount >=1 && $samplecount <=1024) {
		return $self->{vi}->Query(sprintf(":SAMPLE:COUNT %d; COUNT?",$samplecount));
		}
	else {
		die "unexpected value for SAMPLECOUNT in  sub _set_samplecount. Must be between 1 and 1024.";
		}
	
}

sub _set_triggercount { # internal
	my $self = shift;
	my $triggercount = shift;
	
	#return setting
	if (not defined $triggercount){
		$triggercount = $self->{vi}->Query(":TRIGGER:COUNT?");
		chomp($triggercount);
		return $triggercount;
		}
		
	#set triggercount
	if (($triggercount >=1 && $triggercount <=1024) or $triggercount =~/\b(MIN|min|MAX|max|DEF|def)\b/) {
		return $self->{vi}->Query(":TRIGGER:COUNT $triggercount; COUNT?");
		}
	else {
		die "unexpected value for TRIGGERCOUNT in  sub _set_triggercount. Must be between 1 and 1024 or MIN/MAX/DEF.";
		}
}

sub _set_triggerdelay { # internal
	my $self = shift;
	my $triggerdelay = shift;
	
	#return setting
	if (not defined $triggerdelay){
		$triggerdelay = $self->{vi}->Query(":TRIGGER:DELAY?");
		chomp($triggerdelay);
		return $triggerdelay;
		}
	
	#set triggerdelay
	if (($triggerdelay >= 0 && $triggerdelay <=999999.999) or $triggerdelay =~/\b(MIN|min|MAX|max|DEF|def)\b/) {
		return $self->{vi}->Query(":TRIGGER:DELAY $triggerdelay; DELAY?");
		}
	else {
		die "unexpected value for TRIGGERDELAY in  sub _set_triggerdelay. Must be between 0 and 999999.999sec or MIN/MAX/DEF.";
		}
}

sub set_timer { # advanced
	my $self = shift;
	my $timer = shift;
	
	#return setting
	if (not defined $timer){
		$timer = $self->{vi}->Query(":TRIGGER:TIMER?");
		chomp($timer);
		return $timer;
		}
	
	#set timer
	if (($timer >= 1e-3 && $timer <=999999.999) or $timer =~/\b(MIN|min|MAX|max|DEF|def)\b/) {
		return $self->{vi}->Query(":TRIGGER:TIMER $timer; TIMER?");
		}
	else {
		die "unexpected value for TIMER in  sub set_timer. Must be between 0 and 999999.999sec or MIN/MAX/DEF.";
		}
}





# -----------------------------------------DISPLAY --------------------------------

sub display_on { # basic
    my $self=shift;
    $self->{vi}->Write(":DISPLAY:ENABLE 1");
}

sub display_off { # basic
    my $self=shift;
    $self->{vi}->Write(":DISPLAY:ENABLE 0"); # when display is disabled, the instrument operates at a higher speed. Frontpanel commands are frozen.
}

sub display_text { # basic
    my $self=shift;
    my $text=shift;
    
    if ($text) {
		$self->{vi}->Write(":DISPLAY:TEXT:STATE ON");
        $self->{vi}->Write(sprintf(":DISPLAY:TEXT:DATA '%s'",$text));
    } else {
        chomp($text=$self->{vi}->Query(":DISPLAY:TEXT:DATA?"));
        $text=~s/\"//g;
    }
    return $text;
}

sub display_clear { # basic
    my $self=shift;
    $self->{vi}->Write(":DISPlay:TEXT:STATE OFF");
}





# ----------------------------------------------------------------------------------------



1;



=head1 NAME

Lab::Instrument::Keithley2000 - Keithley 2000 digital multimeter

=head1 SYNOPSIS

    use Lab::Instrument::Keithley2000;
    
    my $DMM=new Lab::Instrument::Keithley2000(0,22);
    print $DMM->measure('VOLTAGE:DC');

=head1 DESCRIPTION

The Lab::Instrument::Keithley2000 class implements an interface to the Keithley 2000 digital multimeter.

=head1 CONSTRUCTOR

    my $DMM=new(\%options);

=head1 METHODS

=head2 get_value

    $value=$DMM->get_value($function);

Make a measurement defined by $function with the previously specified range
and integration time.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2000.
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

FUNCTION can be one of the measurement methods of the Keithley2000.
	"DIODE", "DIOD", "diode", "diod" --> read out temperatuer diode
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)
	
=item $range
	
RANGE is given in terms of amps or ohms and can be C< 1e-5 | 1e-4 | 1e-3 | MIN | MAX | DEF > or C< 0...101e6 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=back
=head2 config_measurement

	$K2000->config_measurement($function, $range, $number_of_points, $nplc);

Preset the Keithley2000 for a TRIGGERED measurement.
WARNING: It's not recomended to perform triggered measurments with the KEITHLEY 2000 DMM due to unsolved timing problems!!!!!

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2000.
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
The single measured points will be stored in the internal memory of the Keithley2000.
For the Keithley2000 the internal memory is limited to 1024 values.


=item $nplc

Preset the NUMBER of POWER LINE CYCLES which is actually something similar to an integration time for recording a single measurement value.
The values for $nplc can be any value between 0.01 ... 10.
Example: Assuming $nplc to be 10 and assuming a netfrequency of 50Hz this results in an integration time of 10*50Hz = 0.2 seconds for each measured value. Assuming $number_of_points to be 100 it takes in total 20 seconds to record all values for the trace.



=head2 trg

	$K2000->trg();

Sends a trigger signal via the GPIB-BUS to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Keithley2000.

=head2 abort

    $K2000->abort();

Aborts current (triggered) measurement.


=head2 get_data

	@data = $K2000->get_data();
	
Reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
Reading the buffer will start immediately after the triggered measurement has finished. The LabVisa-script cannot be continued until all requested readings have been recieved.




=head2 set_function

	$K2000->set_function($function);
	
Set a new value for the measurement function of the Keithley2000.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2000.
	"CURRENT", "current", "CURR", "curr", "CURRENT:DC", "current:dc", "CURR:DC", "curr:dc" --> DC current measurement 
	"CURRENT:AC", "current:ac", "CURR:AC", "curr:ac" --> AC current measurement 
	"VOLTAGE", "voltage", "VOLT", "volt", "VOLTAGE:DC", "voltage:dc", "VOLT:DC", "volt:dc" --> DC voltage measurement 
	"VOLTAGE:AC", "voltage:ac", "VOLT:AC", "volt:ac" --> AC voltage measurement 
	"RESISTANCE", "resisitance", "RES", "res" --> resistance measurement (2-wire)
	"FRESISTANCE", "fresistance", "FRES", "fres" --> resistance measurement (4-wire)
	

=head2 set_range

	$K2000->set_range($function,$range);
	
Set a new value for the predefined RANGE for the measurement function $function of the Keithley2000.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2000.
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

	$K2000->set_nplc($function,$nplc);
	
Set a new value for the predefined NUMBER of POWER LINE CYCLES for the measurement function $function of the Keithley2000.

=over 4

=item $function

FUNCTION can be one of the measurement methods of the Keithley2000.
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

	$K2000->set_averaging($count, $filter);
	
Set a new value for the predefined NUMBER of POWER LINE CYCLES for the measurement function $function of the Keithley2000.

=over 4

=item $count

COUNT is the number of readings to be taken to fill the AVERAGING FILTER. COUNT can be 1 ... 100.
	
=item $filter

FILTER can be MOVING or REPEAT. A detailed description is refered to the user manual.
 
=head2 display_on

    $K2000->display_on();

Turn the front-panel display on.

=head2 display_off

    $K2000->display_off();

Turn the front-panel display off.

=head2 display_text

    $K2000->display_text($text);
    print $K2000->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 display_clear

    $K2000->display_clear();

Clear the message displayed on the front panel.


=head2 reset

    $K2000->reset();

Reset the multimeter to its power-on configuration.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

