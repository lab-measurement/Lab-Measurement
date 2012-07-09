#!/usr/bin/perl -w

# Daniel Schmid, July 2010, composed following Markus'  & David's perl-scripts
 
use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP3458A;
use Lab::Instrument::PD11042;

use Time::HiRes qw/usleep/;
use Time::HiRes qw/sleep/;
use Time::HiRes qw/tv_interval/;
use Time::HiRes qw/time/;
use Time::HiRes qw/gettimeofday/;

use Lab::Measurement;

use warnings "all";

#general information
my $t = 0;			      # fürs Stoppen der Messzeit
my $temperature = 'falling';      # Temperatur in milli-Kelvin!
my $temperatureunit = 'mK';
my $sample = "thebest";

my @starttime = localtime(time);
my $startstring=sprintf("%04u-%02u-%02u_%02u-%02u-%02u",$starttime[5]+1900,$starttime[4]+1,$starttime[3],$starttime[2],$starttime[1],$starttime[0]);



# measurement constants
#---dc sample1---
my $Divider = 0.001;
my $yok1protect = 1;		# 0 oder 1 für an / aus, analog gateprotect
my $Yok1DcRange = 5;		# Handbuch S.6-22:R2=10mV,R3=100mV,R4=1V,R5=10V,R6=30V
my $Vdcmax1 = 12;	        # wird unten fürs biasprotect verwendet, on 470 MOhm corresponds to about 32 nA  

my $ampI1 = 1e-9;         
my $risetime1 = 100;		# rise time Ithaco Zeit in ms


my $multitime=2;  # multimeter integration time in line power cycles


#---gate---
############################## !!!!!!!!!!!!!!
my $Vgatestart = 2.;
my $Vgatestop = 3.7;
my $stepgate = 0.001;
##############################!!!!!!!!!!!!!!

my $Vgatemax = 5;				# wird unten fürs gateprotect verwendet

my $Vbias = 0.0;				# Bias in milivolt (Results in microvolt after divider) without offset

############################## !!!!!!!!!!!!! MOTOR PART

# Motor Settings

my $anglespeed = 12; 	#deg per minute
my $anglestep = 1;		#deg per step

my $anglestart = 95;  	#Angle in degrees
my $anglestop = -95;    	#Angle in degrees
##############################

# Magnetic Field

my $Bfield = 10;	#B-field in Tesla

# all gpib addresses

my $title = "Angletrace";
my $filename = $startstring."_$sample angle";


####################################################################

#	<---------- set Instruments

#---init Yokogawa--- Gatespannung
my $type_gate="Lab::Instrument::Yokogawa7651";
my $YokGate=new $type_gate({
	'connection_type' =>'VISA_GPIB',
	'gpib_board'    => 0,
    'gpib_address'  => 3,
    'gate_protect'  => 1,
    'gp_max_units_per_second' => 0.05,
    'gp_max_step_per_second' => 10,
    'gp_max_units_per_step' => 0.01,
    'gp_min_units' => -$Vgatemax, 	# gate equipped with 5 Hz filter from Leonid 
    'gp_max_units'  => $Vgatemax,
});


          

		  
print "setting up Agilent for dc current through sample \n";
my $hp2=new Lab::Instrument::HP3458A({
	'connection_type' =>'VISA_GPIB',
	'gpib_board' => 0,
	'gpib_address' => 15,
	});

	

my $motor=new Lab::Instrument::PD11042(
        connection_type=>'RS232',
        port => 'COM2',
);


	
$hp2->write("TARM AUTO");
$hp2->write("NPLC $multitime");

print " done!\n";

#my $lia=new Lab::Instrument::SR830(0,$gpib_lia);
#my $lia_amplitude=($lia->get_amplitude())*$DividerAC;

#print "wait 3 hours for thermalization! \n";
#sleep(10800);
###################################################################################

my $comment=<<COMMENT;
Ithaco: Verstaerkung $ampI1  , Rise Time $risetime1 ms;
Messen der Ausgangsspannung des Ithaco über Agilent;
Voltage dividers DC: $Divider 
Temperatur = $temperature $temperatureunit;

Motor angle speed = $anglespeed;
Angle per step = $anglestep;

Bias without offset = $Vbias;

Angle Vgate Idc  t
COMMENT


####################################################################################



my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => $filename,
    description     => $comment,

    live_plot       => 'currentdc',
    live_refresh    => '100',

constants       => [
        {
            'name'          => 'ampI',
            'value'         => $ampI1,
        },
    ],
    columns         => [
		{
            'unit'          => 'Deg',
            'label'         => 'Angle to ref',
            'description'   => "Angle with respect to reference position",
        },
		{
            'unit'          => 'V',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gate',
        },
		{
			'unit'          => 'A',
            'label'         => 'Idc',
            'description'   => "measured dc current through $sample",
        },
#	----sonstiges---
		{
            'unit'          => 'sec',
            'label'         => 'time',
            'description'   => "Time",
        },
    ],
    axes            => [
		{
            'unit'          => 'Deg',
            'expression'    => '$C0',
			'label'         => 'Angle to ref',
            'description'   => "Angle with respect to reference position",
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => 'gate voltage',
            'description'   => 'Applied to backgate via 5Hz filter.',
        },
		{
	        'unit'          => 'A',
            'expression'    => '$C2',
            'label'         => 'Idc',
            'description'   => 'Measured dc current through $sample',
        },
		{
            'unit'          => 'sec',
			'expression'    => '$C6',
            'label'         => 'time',
            'description'   => "Timestamp (seconds since unix epoch)",
        },
    ],
    plots           => {
        'currentdc'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
    },
);

###############################################################################

 
unless (($Vgatestop-$Vgatestart)/$stepgate > 0) { # um das gate in die richtige Richtung laufen zu lassen
    $stepgate = -$stepgate;
}
my $stepsign_gate=$stepgate/abs($stepgate);

unless (($anglestop-$anglestart)/$anglestep > 0) { # um das bias in die richtige Richtung laufen zu lassen
    $anglestep = -$anglestep;
}
my $stepsign_angle=$anglestep/abs($anglestep);


##Start der Messung
for (my $pos=$anglestart;$stepsign_angle*$pos<=$stepsign_angle*$anglestop;$pos+=$anglestep)	{

	$measurement->start_block();

	#print "setting gate voltage $Vgatestart ";
	my $measVg=$YokGate->set_voltage($Vgatestart);

	
	#print "done\n setting angle: $pos\n";
	$motor->move("ABS",$pos);
	
	while($motor->active()){
		sleep(1);
	}

	sleep(2);
        
	#print "done\n entering inner loop\n";

	for (my $Vgate=$Vgatestart;$stepsign_gate*$Vgate<=$stepsign_gate*$Vgatestop;$Vgate+=$stepgate) {

	    my $Vgate = $YokGate->set_voltage($Vgate);
		
		my $t = gettimeofday();
        my $Vithaco = $hp2 -> get_value();			    # lese Strominfo von Ithako
	    chomp $Vithaco;                                 # raw data (remove line feed from string)
		
		
	    my $Idc = -($Vithaco*$ampI1);              # '-' für den Ithako, damit positives G rauskommt
            
	    $measurement->log_line($pos, $Vgate, $Idc, $t);
	    
	}
}    

my $meta=$measurement->finish_measurement();

printf "End of Measurement!\n";
