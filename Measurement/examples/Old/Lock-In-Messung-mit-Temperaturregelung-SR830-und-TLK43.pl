#!/usr/bin/perl


use strict;

use IO::Handle;
use Data::Dumper;
use Carp;
use Math::Trig;

#use Time::HiRes qw/sleep/;
#use Time::HiRes qw/usleep/;
#use Time::HiRes qw/tv_interval/;
#use Time::HiRes qw/gettimeofday/;

use Lab::Measurement;

use Lab::Connection::GPIB;

use Lab::Instrument::SR830;
use Lab::Instrument::TemperatureControl::TLK43;




#
# global parameters and values
#

my $RefNum=7;

my $Sample = "Goldkontakte in NaPi + NaCl";
my $FilePrefix = "Messwerte/Ionenbeweglichkeit";

my $Voltage = 0.1;
my $VoltagePark = 0;
my $Shunt = 4.7;
my @Temperatures = ( 10, 20, 30, 40, 30, 20 );
my $TempComp = 0;
my $FreqStart = 100;
my $FreqStop = 10000;
my $FreqStep = 10;
my $WaitAfterFreq = 5;
my $WaitAfterTemp = 300;

my $TFinish = 23;	# temperature setpoint to set after measurement is finished
my $VFinish = 0;	# voltage to set after measurement is finished

# SR830 Lock-In Amp config
my @sr830_config_commands = (
		'OUTX 1',		# Output to GPIB
		'PHAS 0',		# Phase shift off
		'FMOD 1',		# reference source internal (1)
		'FREQ 5000',	# Frequency
		'HARM 1',		# Harmonic
		"SLVL $VoltagePark",	# Voltage
		'ISRC 1',		# Source	I 1MOhm
		'IGND 0',		# Input Shield grounding OFF
		'ICPL 0',		# Input coupling (0=AC, 1=DC)
		'ILIN 0',		# Input line notch filter (0=no filters, 1=Line notch in, 2=2xLine notch in, 3=Both notch filters in
		'SENS 2,2',		# Sensitivity (50nA/mV)
		'OFLT 9',		# Time constant (averaging) to 300ms
		'RMOD 2',		# Reserve mode (0=High Reserve, 1=Normal, 2=Low Noise/minimum)
		'DDEF 1,1,0',	# Display 1, R(1), Ratio none (0)
		'DDEF 2,1,0',	# Display 2, Phi(1), Ration none(0)
		'FPOP 1,0',		# CH1 Display
		'FPOP 2,0',		# CH2 Display
		'OEXP 3,0,0',	# Set offset for R to 0
   );






#
# Stuff needed later
#
my $STime = 0;
my $TempSTime = 0;
my $DataHandler=undef;
my $CurrentTemp = 0;
my $CurrentFreq = 0;
my $Temp = 0;
my $Time = 0;
my $SysTime = 0;
my $meta = undef;
my $M_Voltage = 0;
my $M_Current = 0;
my $M_Current_X = 0;
my $M_Phase = 0;
my $M_X = 0;
my $M_Y = 0;


my $TempList = join("\n", @Temperatures);

my $DatafileComment=<<COMMENT;
Measurement M${RefNum}
Voltage: $Voltage
Used shunt: $Shunt Ohm
Temperatures: $TempList
Initial volume of solution:
180ul

This measurement ist done to ... yadda yadda.
COMMENT




#
# Yokogawa7651
#
my $gate_protect=0;





# Measurement base config hash

my $MeasureConfig = {
	sample          => $Sample,
	title           => "Title of my Graph",
	filename_base   => $FilePrefix,
	description     => $DatafileComment,
	
	constants       => [
		{
		},
	],
	columns         => [
		{
			'unit'          => '',
			'label'         => "Timestamp",
			'description'   => 'System Timestamp',
		},
		{
			'unit'          => 's',
			'label'         => "Time",
			'description'   => 'Time in seconds since start of measurement',
		},
		{
			'unit'          => '°C',
			'label'         => "Temperature",
			'description'   => 'Measured Temperature',
		},
		{
			'unit'          => 'Hz',
			'label'         => "Frequency",
			'description'   => 'Applied Frequency',
		},
		{
			'unit'          => 'V',
			'label'         => 'applied Lock-In AC Voltage',
			'description'   => "Voltage output by Lock-In amplifier (AC)",
		},
		{
			'unit'          => 'V',
			'label'         => 'Measured Voltage over Shunt (R, amplitude)',
			'description'   => "Voltage measured by Lock-In amplifier, amplitude(R)",
		},
		{
			'unit'          => 'deg',
			'label'         => 'Phase',
			'description'   => "Phase measured by Lock-In amplifier",
		},
		{
			'unit'          => 'V',
			'label'         => 'Measured Voltage over Shunt (real part, X)',
			'description'   => "Voltage measured by Lock-In amplifier, real part (X)",
		},
		{
			'unit'          => 'V',
			'label'         => 'Measured Voltage over Shunt (imaginary part, Y)',
			'description'   => "Voltage measured by Lock-In amplifier, imaginary part (Y)",
		},
		{
			'unit'          => 'A',
			'label'         => 'Measured current through Shunt (amplitude)',
			'description'   => "Current measured by Lock-In amplifier (amplitude)",
		},
		{
			'unit'          => 'A',
			'label'         => 'Measured current through Shunt (real part)',
			'description'   => "Current measured by Lock-In amplifier (real part)",
		},
	],
};


#
# Exit endless measurement with Strg-C, but still perform the cleanup
#

my $ExitReq_SIGINT=0;

# Setting SIGINT handler to gracefully exit
# (to try and prevent USB-GPIB driver crash)
sub handler_SIGINT {
	print "Received SIGINT. Exiting on next opportunity.\n";
	$ExitReq_SIGINT=1;
}
#$SIG{'INT'} = \&handler_SIGINT;	# catch sigint for exit handling - better later, just before main loop, so you can abort while initializing.


#
# Vorlauf, Init
#

$|=1; # disable buffering on standard output
system('mkdir Messwerte');



#
# Connections and devices, initialise
#

#
# GPIB connection
#
print "Setting up GPIB connection.\n";
my $GPIB = new Lab::Connection::GPIB({ GPIB_Board => 0 }) || croak("Failed to set up GPIB connection!\n");


#
# SR830 Lock-In Amp on GPIB
#
print "Setting up SR830 Lock-IN Amp on GPIB.\n";
my $sr = new Lab::Instrument::SR830({ 
		Connection=>$GPIB,
		GPIB_Paddress=>9
}) || croak("Failed to setup SR830 Lock-In Amp!\n");




#
# TLK43 temperature controller on serial/MODBUS connection
#
print "Setting up TLK43 temperature controller on serial/MODBUS.\n";
my $TLK = new Lab::Instrument::TLK43({
		ConnType => 'MODBUS_RS232',
		SlaveAddress => 1,
		Port => '/dev/ttyS0',
		Interface => 'RS232',
		Baudrate => 19200,
		Parity => 'none',
		Databits => 8,
		Stopbits => 1,
		Handshake => 'none'
}) || croak("Failed to setup TLK43 temperature controller!\n");





#
# Start measurement
#

print "Setting up measurement.\n";
print "Voltage: $Voltage\n";

$sr->send_commands(@sr830_config_commands);

$DataHandler=new Lab::Measurement(%{$MeasureConfig});

print "Starting measurement, to stop press STRG-C\n";

$STime = time();
$SIG{'INT'} = \&handler_SIGINT;	# catch sigint for exit handling
while( $ExitReq_SIGINT==0 ) {

	for $Temp ( @Temperatures ) {

		$sr->set_amplitude($VoltagePark);
		$TempComp = sprintf("%.1f", $Temp - TempDiff($Temp));

		print "Going for Temperature $Temp ($TempComp with compensation), please wait.\n";
		$TLK->set_active_setpoint($TempComp);
		do {
			sleep 5;
			$CurrentTemp=$TLK->read_temperature();
			print "Temperature is now at $CurrentTemp\n";
		} until $CurrentTemp == $TempComp || $ExitReq_SIGINT!=0;

		print "Waiting for $WaitAfterTemp seconds\n" if $ExitReq_SIGINT==0;
		sleep $WaitAfterTemp if $ExitReq_SIGINT==0;

		$sr->set_amplitude($Voltage);
		$DataHandler->start_block();
		$TempSTime = time();
		$STime = time() - $Time + 1; # no huge time gaps
		$CurrentFreq = $FreqStart;
		while($CurrentFreq <= $FreqStop && $ExitReq_SIGINT==0) {
			$sr->set_frequency($CurrentFreq);
			sleep($WaitAfterFreq);
			$CurrentTemp = $TLK->read_temperature();
			($M_Voltage, $M_Phase) = $sr->read_rphi();
			$M_X = $M_Voltage * cos( ($M_Phase/360)*pi );
			$M_Y = $M_Voltage * sin( ($M_Phase/360)*pi );
			$M_Current = $M_Voltage / $Shunt;
			$M_Current_X = $M_Current * sin( ($M_Phase/360)*pi );
			$Time = time() - $STime;
			$SysTime = `date +%Y-%m-%d_%H-%M-%S`;
			chomp($SysTime);
			$DataHandler->log_line($SysTime,$Time,$CurrentTemp,$CurrentFreq,$Voltage,$M_Voltage,sprintf("%f",$M_Phase),$M_X,$M_Y,$M_Current,$M_Current_X );
			printf("Time: %4s, Temperature: %4.1fC, Current: %.10f, Phase: %.2f\n", $Time, $CurrentTemp, $M_Current, sprintf("%f",$M_Phase));
			$CurrentFreq = $CurrentFreq + $FreqStep;
		}

		last if($ExitReq_SIGINT!=0);
	}
}

	
$meta=$DataHandler->finish_measurement();
#close(DATAFILE);		




# Nachlauf
#
print "Stopped measurement, cleaning up...\n";

print "Resetting temperature to $TFinish\n";
if(defined($TFinish)) {
	warn "Reset failed!\n" unless $TLK->set_active_setpoint($TFinish); # two times in case an error occurs
	warn "Reset failed!\n" unless $TLK->set_active_setpoint($TFinish);
}
else {
	warn "Reset failed!\n" unless $TLK->set_active_setpoint(23); # room temperature should be safe
	warn "Reset failed!\n" unless $TLK->set_active_setpoint(23);
}

print "Resetting voltage to $VFinish\n";
if(defined($VFinish)) {
	$sr->set_amplitude($VFinish);
	$sr->set_amplitude($VFinish);
}
else {
	$sr->set_amplitude(0);
	$sr->set_amplitude(0);
}

print "Finished, taking a rest!\n";
