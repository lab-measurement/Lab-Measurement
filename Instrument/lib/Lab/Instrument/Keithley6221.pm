package Lab::Instrument::Keithley6221;


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


		
sub set_output {#
	my $self = shift;
	my $output = shift;
	
	# check if OUTPUT is allready ON/OFF
	my $status = ($self->{vi}->Query(":OUTPUT?") == 1) ? 1 : 0;
	if (($output =~ /\b(ON|on|1)\b/ and $status == 1) or ($output =~ /\b(OFF|ffn|0)\b/ and $status == 0))
		{
		return $self->{vi}->Query(":OUTPUT?");
		}
	
	# get SOURCE AMPLITUDE
	my $source_ampl = $self->set_source_amplitude();
	
	# set SOURCE AMPLITUDE to ZERO if not ZERO
	if ( $source_ampl != 0 )
		{
		$self->set_source_amplitude(0);
		}		
	
	# swicht OUTPUT ON/OFF 
	if ( $output =~ /\b(ON|on|1|OFF|off|0)\b/ ) {
		$self->{vi}->Write(":OUTPUT $output");
		}
	else {
		die "unexpected value for OUTPUT STATE in sub_output. Expected values are ON, OFF, 1 or 0.";
		}
	
	# set SOURCE AMPLITUDE back to the original value
	if ( $source_ampl != 0 )
		{
		$self->set_source_amplitude($source_ampl);
		}	
	
	return $self->{vi}->Query(":OUTPUT?");
	}
	
sub set_output_low {
	my $self = shift;
	my $value = shift;
	
	if ( not defined $value )
		{
		return $self->{vi}->Query("OUTPUT:LTEARTH?");
		}
	elsif ( $value =~ /\b(ON|on|OFF|off)\b/)
		{
		return $self->{vi}->Query("OUTPUT:LTEARTH $value; LTEARTH?");
		}
	else
		{
		die "unexpected value in sub set_outputlow. Expected values are:\n ON --> connecting the OUTPUT LOW to EARTH\n OFF --> FLOAT OUTPUT LOW.";
		}

}

sub set_output_shield {
	my $self = shift;
	my $value = shift;
	
	if ( not defined $value )
		{
		return $self->{vi}->Query("OUTPUT:ISHIELD?");
		}
	elsif ( $value =~ /\b(OLOW|olow|GURAD|guard|GUAR|guar)\b/)
		{
		return $self->{vi}->Query("OUTPUT:ISHIELD $value; ISHIELD?");
		}
	else
		{
		die "unexpected value in sub set_outputshiel. Expected values are:\n OLOW --> connecting SHIELD to OUTPUT LOW \n GURAD --> connecting SHIELD to cable GURAD.";
		}
}

sub set_output_response {
	my $self = shift;
	my $value = shift;
	
	if ( not defined $value )
		{
		return $self->{vi}->Query("OUTPUT:RESPONSE?");
		}
	elsif ( $value =~ /\b(FAST|fast|SLOW|slow)\b/)
		{
		return $self->{vi}->Query("OUTPUT:RESPONSE $value; RESPONSE?");
		}
	else
		{
		die "unexpected value in sub set_outputresponse. Expected values are SLOW and FAST.";
		}
}

# ------------------------------------ SENSE 1 subsystem ----------------------------------

sub measure {
	my $self = shift;	
	chomp(my $value = $self->{vi}->Query(":SENSE:DATA?"));
	my @value = split(",",$value);
	if ( $value = @value > 1)
		{
		return @value;
		}
	else
		{
		return $value[0];
		}
	
}

sub set_sense_averaging {#
	my $self = shift;	
	my $count = shift;
	my $filter = shift;
	my $window = shift;
	
	if (not defined $count)
		{
		return $self->{vi}->Query(":SENSE:AVERAGE:COUNT?");
		}
	
	if ($count >= 2 and $count <= 300) {
		if (defined $filter and ($filter =~ /\b(REPEAT|REP|repeat|rep|MOVING|MOV|moving|mov)\b/)) {
			if ( not defined $window ) 
				{
				$window = 'DEF'; # DEF = 0.00
				}
			elsif ($window >= 0 and $window <= 10)
				{
				# ok
				}
			else
				{
				die "unexpected value for WINDOW in sub set_sense_averaging. Expected values are betwenn 0...10 (percent of full range).";
				}
			return $self->{vi}->Query(":SENS:AVER:TCON $filter; COUN $count; STAT ON; WIND $window; TCON?; COUN?; WIND?");
			}
		elsif ( not defined $filter) {
			$filter = 'DEF'; # DEF = MOV
			if ( not defined $window ) 
				{
				$window = 'DEF'; # DEF = 0.00
				}
			elsif ($window >= 0 and $window <= 10)
				{
				# ok
				}
			else
				{
				die "unexpected value for WINDOW in sub set_sense_averaging. Expected values are betwenn 0...10 (percent of full range).";
				}
			return $self->{vi}->Query(":SENS:AVER:TCON $filter; COUN $count; STAT ON; WIND $window; TCON?; COUN?; WIND?");
		
		}
		else { die "unexpected value for FILTER in sub set_averaging. Expected values are REPEAT or MOVING.";}
	}
	elsif ($count =~/\b(OFF|off|0)\b/) {
		return $self->{vi}->Query(sprintf(":SENS:AVER:STAT OFF; TCON MOV; STAT?"));
	}
	else { die "unexpected value for COUNT in sub set_averaging. Expected values are between 2...300 and 0 or OFF to turn off averaging";}	

}





# ------------------------------------ SOURCE subsystem -----------------------------------
sub set_source_current {
	my $self = shift;
	my $current = shift;
	
	if ( not defined $current)
		{
		chomp ($current = $self->{vi}->Query(":SOURCE:CURRENT?"));
		return $current;
		}
	elsif ($current >= -105e-3 and $current <= 105e-3)	
		{
		chomp ($current = $self->{vi}->Query(":SOURCE:CURRENT $current; CURRENT?"));
		return $current;
		}
	else
		{
		print "Current = $current\n";
		die "unexpected value for CURRENT in sub set_current. Expected values are between -105e-3 ... +105e-3 Amps.";
		}
	
}

sub set_source_range {#
	my $self = shift;
	my $range = shift;
	
	if (not defined $range)
		{
		return  $self->{vi}->Query(":SOURCE:CURRENT:RANGE?");
		}
	
	
	if ( ($range >= -105e-3 and $range <= 105e-3) or $range =~ /\b(MIN|min|MAX|max|DEF|def)\b/)
		{
		return  $self->{vi}->Query(":SOURCE:CURRENT:RANGE $range; RANGE?");
		}
	elsif ( $range =~ /\b(AUTO|auto)\b/ ) 
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:RANGE:AUTO OFF; AUTO?; RANGE?");
		}
	else 
		{
		die "unexpected value for RANGE in sub set_source_range. Expected values are between -105e-3 and 1.05e-3 or AUTO.";
		}
		
}

sub set_source_compliance {
	my $self = shift;
	my $value = shift;
	
	if ( not defined $value )
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:COMPLIANCE?");
		}
	elsif (($value >= 0.1 and $value <= 105) or $value =~ /\b(MIN|min|MAX|max|DEF|def)\b/)
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:COMPLIANCE $value; COMPLIANCE?");
		}
	else
		{
		die "unexpected value for COMPLIANCE in sub set_source_compliance. Expected values are between 0.1 and 105 volts or MIN/MAX/DEF.";
		}
}

sub set_source_filter {
	my $self = shift;
	my $value = shift;
	
	if ( not defined $value )
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:FILTER?");
		}
	elsif ($value  =~ /\b(ON|on|OFF|off|DEF|def)\b/)
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:FILTER $value; FILTER?");
		}
	else
		{
		die "unexpected value for FILTERin sub set_source_filter. Expected values are between ON/OFF/DEF.";
		}
}

sub set_source_amplitude {#
	my $self = shift;
	my $value = shift;	
	return $self->set_source_current($value);
}
	



sub set_source_delay {#
	my $self = shift;
	my $delay = shift;
	
	if (not defined $delay)
		{
		$delay = $self->{vi}->Query(":SOURCE:DELAY?");
		return chomp $delay;
		}	
	elsif (($delay >= 1e-3 and $delay <= 999999.999) or $delay =~ /\b(MIN|min|MAX|max|DEF|def)\b/) 
		{
		$self->{vi}->Write(":SOURCE:DELAY:AUTO OFF");
		return $self->{vi}->Query(":SOURCE:DELAY $delay; DELAY?");
		}
	else { die "unexpected value for DELAY in sub set_source_delay. Expected values are between 0..999999.999";}
}


sub _set_voltage { # internal use only
	my $self = shift;
	my $value = shift;	
	
	return $self->{vi}->Query(sprintf(":SOURCE:VOLT %e; VOLT?", $value));
}

sub _set_voltage_auto { # internal use only
	# not implemented for Keithley 2400
}

sub set_current {#
	my $self = shift;
	my $value = shift;	
	
	return $self->{vi}->Query(sprintf(":SOURCE:CURR %e; CURR?", $value));
}

sub _set_auto { # internal use only
	# not implemented for Keithley 2400
}

sub _get_voltage { # internal use only
	my $self = shift;

	return $self->set_source_amplitude ('VOLTAGE');	
}

sub get_current { # 
	my $self = shift;
	
	return $self->set_source_amplitude ('CURRENT');
}



# -------------------------------------- CONFIG SOURCE SWEEP --------------------------------
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

sub set_sweep_ranging {# not tested
	my $self = shift;
	my $ranging = shift;
	
	if ( $ranging =~ /\b(BEST|best|FIXED|FIX|fixed|fix|AUTO|auto)\b/ ) {
		return $self->{vi}->Query(sprintf(":SOURCE:SWEEP:RANGING %s; :SOURCE:SWEEP:RANGING?", $ranging));
	}
	else { die "unexpected vlaue for RANGING in sub set_sweep_ranging. Expected values are BEST, FIXED or AUTO.";}
}

sub set_sweep_spacing {# not tested
	my $self = shift;
	my $spacing = shift;
	
	if ( $spacing =~ /\b(LINEAR|LIN|linear|lin|LOGARITHMIC|LOG|logarithmic|log)\b/ ) {
		return $self->{vi}->Query(sprintf(":SOURCE:SWEEP:SPACING %s; :SOURCE:SWEEP:SPACING?", $spacing));
	}
	else { die "unexpected vlaue for SPACING in sub set_sweep_spaceing. Expected values are LIN or LOG.";}
}

sub set_sweep_start {#
	my $self = shift;
	my $start = shift;
	
	
	if ( not defined $start )
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:START?");
		}
	elsif (($start >= -105e-3 and $start <= 1.05e-3) or $start =~ /\b(MIN|min|MAX|max|DEF|def)\b/) 
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:START $start; START?");
		}
	else
		{
		die "unexpected value for START in sub set_sweep_start. Expected values are between -105e-3...+105e-3 amps";
		}
	
}

sub set_sweep_stop {#
	my $self = shift;
	my $stop = shift;
	
	
	if ( not defined $stop )
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:STOP?");
		}
	elsif (($stop >= -105e-3 and $stop <= 1.05e-3) or $stop =~ /\b(MIN|min|MAX|max|DEF|def)\b/) 
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:STOP $stop; STOP?");
		}
	else
		{
		die "unexpected value for STOP in sub set_sweep_stop. Expected values are between -105e-3...+105e-3 amps";
		}
	
}

sub set_sweep_step {#
	my $self = shift;
	my $step = shift;
	
	
	if ( not defined $step )
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:STEP?");
		}
	elsif (($step >= 1e-13 and $step <= 1.05e-3) or $step =~ /\b(MIN|min|MAX|max|DEF|def)\b/) 
		{
		return $self->{vi}->Query(":SOURCE:CURRENT:STEP $step; STEP?");
		}
	else
		{
		die "unexpected value for STEP in sub set_sweep_step. Expected values are between 1e-13...+105e-3 amps";
		}
	
}

sub set_sweep_nop {#
	my $self = shift;
	my $nop = shift;
	
	
	if ($nop >= 1 and $nop <= 65535 ) {
		return $self->{vi}->Query(sprintf(":SOURCE:SWEEP:POINTS %d; POINTS?",$nop));
	}
	else { die "unexpected value in sub set_sweep_step. Expected values are between 1..65535";}	

}

sub set_sweep_count {#
	my $self = shift;
	my $count = shift;
	
	if ( not defined $count )
		{
		return $self->{vi}->Query(":SOURCE:SWEEP:COUNT?");
		}
	elsif ($count >= 1 and $count <= 9999 ) 
		{
		return $self->{vi}->Query(":SOURCE:SWEEP:COUNT $count; COUNT?");
		}
	else 
		{
		die "unexpected value in sub set_sweep_count. Expected values are between 1..9999";
		}	

}

sub set_sweep_cabort {
	my $self = shift;
	my $value = shift;
	
	if ( not defined $value )
		{
		return $self->{vi}->Query(":SOURCE:SWEEP:CAB?");
		}
	elsif ( $value =~ /\b(ON|on|OFF|off)\b/)
		{
		return $self->{vi}->Query(":SOURCE:SWEEP:CAB $value; CAB?");
		}
	else
		{
		die "unexpected value in sub set_sweep_cabort. Expected values are ON or OFF";
		}
}

sub set_sweep_arm {
	my $self = shift;
	return $self->{vi}->Write(":SOURCE:SWEEP:ARM");
}

sub sweep_abort {
	my $self = shift;
	return $self->{vi}->Write(":SOURCE:SWEEP:ABORT");
}

sub config_sweep {#
	my $self = shift;
	my $stop = shift;
	my $nop = shift;
	my $time = shift;
	
			
		
	print "set output = ".$self->set_output("ON")."\n";
	my $start = $self->set_source_amplitude();
	#chomp $start;
	print "Start = $start\n";

	print "--- config SWEEP ----\n";
	print "start = ".$self->set_sweep_start($start);
	if ( $start != $self->set_source_amplitude() )
		{
		$self->set_source_amplitude($start);
		}
	print "stop = ".$self->set_sweep_stop($stop);
	print "nop = ".$self->set_sweep_nop($nop);
	print "step = ".$self->set_sweep_step();
	
	print "source_delay = ".$self->set_source_delay(($time)/$nop);
		
	print "ranging = ".$self->set_sweep_ranging('FIXED');
	print "spacing = ".$self->set_sweep_spacing('LIN');
	print "sweep arm ".$self->set_sweep_arm()."\n";
		
	print "init BUFFER: ".$self->init_buffer($nop)."\n";
	
	print "init status request: ".$self->init_statusrequest();
	print "ready to SWEEP\n";
	
}

# ------------------------------------ DATA BUFFER ----------------------------------------

sub clear_buffer { #
	my $self = shift;
	$self->{vi}->Write(":TRACE:FEED:CONTROL NEVER");
	$self->{vi}->Write(":TRACE:CLEAR");
}

sub init_buffer { #
	my $self = shift;
	my $nop = shift;
		
	$self->clear_buffer();	
	$self->{vi}->Query(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS READING; ELEMENTS?", ); # select Format for reading DATA
		
	if ( $nop >= 1 && $nop <=65536) {
		my $return_nop = $self->{vi}->Query("TRACE:POINTS $nop; POINTS?");
		$self->{vi}->Write(":TRACE:FEED SENSE"); # select raw-data to be stored.
		$self->{vi}->Write(":TRACE:FEED:CONTROL NEXT"); # enable data storage
		return $return_nop;
		}
	else{
		die "unexpected value in sub set_nop_for_buffer. Must be between 2 and 2500.";
		}
}

sub read_buffer { #
	my $self = shift;
	my $print = shift;
	
	# wait until data are available	
	$self->wait_while_sweeping();
	
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

sub init_statusrequest {
	my $self = shift;
	return $self->{vi}->Query("*CLS; :status:oper:enab 2; *SRE 128; *STB?");
}

sub wait {
	my $self = shift;
	my $timeout = shift;
	return $self->{vi}->Query("*STB?");
}



sub run{#
	my $self = shift;
	$self->{vi}->Write(":INITIATE:IMMEDIATE");
	
	
}




# -----------------------------------------DISPLAY --------------------------------

sub display_on {#
    my $self=shift;
    $self->{vi}->Write(":DISPLAY:ENABLE ON");
}

sub display_off {#
    my $self=shift;
    $self->{vi}->Write(":DISPLAY:ENABLE OFF"); # when display is disabled, the instrument operates at a higher speed. Frontpanel commands are frozen.
}

sub display {
	my $self = shift;
	my $data = shift;
	
	if ( not defined $data )
		{
		return $self->display_text();
		}
	elsif ($data =~ /\b(ON|on)\b/)
		{
		return $self->display_on();
		}
	elsif ($data =~ /\b(OFF|off)\b/)
		{
		return $self->display_off();
		}
	elsif ($data =~ /\b(CLEAR|clear)\b/)
		{
		return $self->display_clear();
		}
	else
		{
		return $self->display_text($data);
		}
	
	}

sub display_text {#
    my $self=shift;
    my $text=shift;
    
    if ($text) {
        chomp( $text = $self->{vi}->Query("DISPLAY:TEXT '$text'; TEXT?"));
		$text=~s/\"//g;
		return $text;
    } else {
        chomp($text=$self->{vi}->Query("DISPLAY:TEXT?"));
        $text=~s/\"//g;
		return $text;
    }
}

sub display_clear {#
    my $self=shift;
    $self->{vi}->Write("DISPlay:TEXT:STATE 0");
}


# ----------------------------------------------------------------------------------------


1;

