#!/usr/bin/perl -w

# Daniel Schmid, July 2010, composed following Markus'  & David's perl-scripts
 
use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP34401A;
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

my $ampI1 = 1e-8;         
my $risetime1 = 30;		# rise time Ithaco Zeit in ms


my $multitime=2;  # multimeter integration time in line power cycles


#---gate---
############################## !!!!!!!!!!!!!!
my $Vgatestart = 4.35;
my $Vgatestop = 0.5;
my $stepgate = 0.002;
##############################!!!!!!!!!!!!!!

my $Vgatemax = 5;				# wird unten fürs gateprotect verwendet

############################## !!!!!!!!!!!!!!
my $Vbiasstart = -1.4;  #ACHTUNG!!! 1/1000 Teiler für dc-bias! -->1V=1mV
my $Vbiasstop = 1.4;    #ACHTUNG!!! 1/1000 Teiler für dc-bias! -->1V=1mV
my $stepbias = 0.005;   #ACHTUNG!!! 1/1000 Teiler für dc-bias! -->1mV=1µV
##############################

# all gpib addresses

my $gpib_hp2 = 13;			# Spannung output Ithaco für Strommessung durch Probe		

my $title = "Stability diagram";
my $filename = $startstring."_$sample dia $temperature$temperatureunit";


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



#--- init Yoko dc bias sample 1 ----
my $type_bias1="Lab::Instrument::Yokogawa7651";
my $Yok1=new $type_bias1({
	'connection_type' =>'VISA_GPIB',
    'gpib_board'    => 0,
    'gpib_address'  => 2,
    'gate_protect'  => 0,
    'gp_max_units_per_second' => 5,
    'gp_max_step_per_second' => 10,
    'gp_max_units_per_step' => 0.5,
    'gp_min_units' => -5, 	
    'gp_max_units'  => 5,
});
          

		  
print "setting up Agilent for dc current through sample \n";
my $hp2=new Lab::Instrument::HP34401A({
	'connection_type' =>'VISA_GPIB',
	'gpib_board' => 0,
	'gpib_address' => $gpib_hp2,
	});

#$hp2->write("TARM AUTO");
#$hp2->write("NPLC $multitime");

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

Vgate Vbias Idc  t
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
            'unit'          => 'V',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gate',
        },
		{
            'unit'          => 'V',
            'label'         => 'Vbias',
            'description'   => "Vbias",
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
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => 'gate voltage',
            'description'   => 'Applied to backgate via 5Hz filter.',
        },
		{
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => 'dc bias voltage',
            'description'   => 'Applied on sample via $Divider divider',
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
#        'currentacx'    => {
#            'type'          => 'pm3d',
#            'xaxis'         => 0,
#            'yaxis'         => 1,
#            'cbaxis'        => 3,
#            'grid'          => 'xtics ytics',
#        },
#        'currentacr'    => {
#            'type'          => 'pm3d',
#            'xaxis'         => 0,
#            'yaxis'         => 1,
#            'cbaxis'        => 5,
#            'grid'          => 'xtics ytics',
#        },
    },
);

###############################################################################

 
unless (($Vgatestop-$Vgatestart)/$stepgate > 0) { # um das gate in die richtige Richtung laufen zu lassen
    $stepgate = -$stepgate;
}
my $stepsign_gate=$stepgate/abs($stepgate);

unless (($Vbiasstop-$Vbiasstart)/$stepbias > 0) { # um das bias in die richtige Richtung laufen zu lassen
    $stepbias = -$stepbias;
}
my $stepsign_bias=$stepbias/abs($stepbias);


##Start der Messung
for (my $Vgate=$Vgatestart;$stepsign_gate*$Vgate<=$stepsign_gate*$Vgatestop;$Vgate+=$stepgate)	{

	$measurement->start_block();
	
	#print "setting gate voltage ";
	my $measVgate=$YokGate->set_voltage($Vgate);

	#print "done\n setting bias voltage $Vbiasstart ";
	my $measVb=$Yok1->set_voltage($Vbiasstart);
        
	#print "done\n entering inner loop\n";
	sleep(1);

	for (my $Vbias=$Vbiasstart;$stepsign_bias*$Vbias<=$stepsign_bias*$Vbiasstop;$Vbias+=$stepbias) {

	    my $Vbias = $Yok1->set_voltage($Vbias);
		
		my $t = gettimeofday();
        my $Vithaco = $hp2 -> get_value();			    # lese Strominfo von Ithako
	    chomp $Vithaco;                                 # raw data (remove line feed from string)
		
#		my ($Vacx,$Vacy)=$lia->read_xy();
		
	    my $Idc = -($Vithaco*$ampI1);              # '-' für den Ithako, damit positives G rauskommt
#		my $Iacx= -($Vacx*$ampI1);
#		my $Iacy= -($Vacy*$ampI1);
#      my $Iacr=sqrt($Iacx*$Iacx+$Iacy*$Iacy);
		
        my $VbiasComp = $Vbias * $Divider;
            
	    $measurement->log_line($measVgate, $VbiasComp, $Idc, $t);
	    
	}
}    

my $meta=$measurement->finish_measurement();

printf "End of Measurement!\n";
