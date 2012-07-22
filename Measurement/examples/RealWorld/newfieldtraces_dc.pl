#!/usr/bin/perl -w

# Daniel Schmid, July 2010, composed following Markus'  & David's perl-scripts
 
use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::IPS12010;
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
my $temperature = '30';      # Temperatur in milli-Kelvin!
my $temperatureunit = 'mK';
my $sample = "CB3224";

my @starttime = localtime(time);
my $startstring=sprintf("%04u-%02u-%02u_%02u-%02u-%02u",$starttime[5]+1900,$starttime[4]+1,$starttime[3],$starttime[2],$starttime[1],$starttime[0]);



# measurement constants
#---ac sample1---

my $DividerDC = 0.001;

my $yok1protect = 1;		# 0 oder 1 für an / aus, analog gateprotect

my $Vdcmax1 = 12;	        # wird unten fürs biasprotect verwendet, on 470 MOhm corresponds to about 32 nA  

my $ampI = 1e-11;         
my $risetime = 100;		# rise time Ithaco Zeit in ms

my $multitime=5;  # multimeter integration time in line power cycles


#---gate---
############################## !!!!!!!!!!!!!!
my $Vgate = 0.675;
##############################!!!!!!!!!!!!!!

my $Vbiasstart = 0;
my $Vbiasstop = 15;
my $Vbiasstep = 0.015;

##############################
# Magnetic Field

my $fieldstart=0.5;
my $fieldstop=-2;
my $fieldstep=0.02;
my $fieldtolerance=$fieldstep/10;

# Angles

my $angle = -23.3;


# all gpib addresses

my $title1 = "Bias and magnetic field sweep at parallel orientation (detail)";
my $filename1 = $startstring."_$sample b-field par biasDC";

####################################################################

#	<---------- set Instruments

#---init Yokogawa--- biasspannung
my $type_bias="Lab::Instrument::Yokogawa7651";
my $YokBias=new $type_bias({
	'connection_type' =>'VISA_GPIB',
	'gpib_board'    => 0,
    'gpib_address'  => 2,
    'gate_protect'  => 1,
    'gp_max_units_per_second' => 5,
    'gp_max_step_per_second' => 10,
    'gp_max_units_per_step' => 0.5,
});
         

		  
print "setting up Agilent for dc current through sample \n";
my $hp2=new Lab::Instrument::HP3458A({
	'connection_type' =>'VISA_GPIB',
	'gpib_board' => 0,
	'gpib_address' => 15,
	});


my $magnet=new Lab::Instrument::IPS12010(
        connection_type=>'VISA_GPIB',
        gpib_address => 24,
		max_current => 123.8,    # A
		max_sweeprate => 0.0167, # A/s
		soft_fieldconstant => 0.13731588, # T/A
		can_reverse => 1,
		can_use_negative_current => 1,
);
	
$hp2->write("TARM AUTO");
$hp2->write("NPLC $multitime");

#print "wait 3 hours for thermalization! \n";
#sleep(10800);
###################################################################################
# Measurment 1
###################################################################################

my $comment1=<<COMMENT;
Current measurement for different magnetic field strength and bias in the few electron regime.
angle setting: $angle, which is most likely parallel field

Ithaco: Verstaerkung $ampI  , Rise Time $risetime ms;
Messen der Ausgangsspannung des Ithaco über Agilent;
Voltage dividers DC: $DividerDC 

Multimeter integ. time (PLC) $multitime

Temperatur = $temperature $temperatureunit;

Gate = $Vgate V;

Field Vbias Idc t
COMMENT


####################################################################################



my $measurement1=new Lab::Measurement(
    sample          => $sample,
    title           => $title1,
    filename_base   => $filename1,
    description     => $comment1,

    live_plot       => 'Idc',
    live_refresh    => '300',

constants       => [
        {
            'name'          => 'ampI',
            'value'         => $ampI,
        },
    ],
    columns         => [
		{
            'unit'          => 'T',
            'label'         => 'Bpar',
            'description'   => "magnetic field parallel to tube",
        },
		{
            'unit'          => 'V',
            'label'         => 'Bias voltage',
            'description'   => 'Applied between source and drain',
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
            'unit'          => 'T',
            'expression'    => '$C0',
			'label'         => 'Bpar',
            'description'   => "magnetic field parallel to tube",
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => 'bias voltage',
            'description'   => 'Applied between source and drain.',
        },
		{
	        'unit'          => 'A',
            'expression'    => '$C2',
            'label'         => 'Idc',
            'description'   => 'Measured dc current through $sample',
        },
		{
            'unit'          => 'sec',
			'expression'    => '$C3',
            'label'         => 'time',
            'description'   => "Timestamp (seconds since unix epoch)",
        },
    ],
    plots           => {
        'Idc'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
    },
);

###############################################################################

unless (($Vbiasstop-$Vbiasstart)/$Vbiasstep > 0) { # um das bias in die richtige Richtung laufen zu lassen
    $Vbiasstep = -$Vbiasstep;
}
my $stepsign_bias=$Vbiasstep/abs($Vbiasstep);


unless (($fieldstop-$fieldstart)/$fieldstep > 0) { # um das bias in die richtige Richtung laufen zu lassen
    $fieldstep = -$fieldstep;
}
my $stepsign_field=$fieldstep/abs($fieldstep);

#sleep(3600);

##Start der Messung
for (my $B=$fieldstart;$stepsign_field*$B<=$stepsign_field*($fieldstop+$fieldtolerance);$B+=$fieldstep)	{

	$measurement1->start_block();

	#print "setting bias voltage $Vbiasstart ";
	my $measVb=$YokBias->set_voltage($Vbiasstart);

	if ( abs($B) < $fieldtolerance ){
		$B = 0;
		}
	
	print "Setting magnetic field: $B T\n";
	$magnet->set_field($B);
 	print "Done, entering inner loop.\n";

	for (my $Vbias=$Vbiasstart;$stepsign_bias*$Vbias<=$stepsign_bias*$Vbiasstop;$Vbias+=$Vbiasstep) {

	    my $Vbias = $YokBias->set_voltage($Vbias);
		
		my $t = gettimeofday();
        my $Vithaco = $hp2 -> get_value();			    # lese Strominfo von Ithako
	    chomp $Vithaco;                                 # raw data (remove line feed from string)
		
		
	    my $Idc = -($Vithaco*$ampI);              # '-' für den Ithako, damit positives G rauskommt
            
	    $measurement1->log_line($B, $Vbias, $Idc, $t);
	    
	}
}    

my $meta=$measurement1->finish_measurement();

printf "End of Measurement 1!\n";