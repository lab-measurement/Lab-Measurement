#!/usr/bin/perl -w

# Daniel Schmid, July 2010, composed following Markus'  & David's perl-scripts
 
use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP3458A;
use Lab::Instrument::SR830;
use Time::HiRes qw/gettimeofday/;
use Lab::Measurement;


my $DividerAC=0.0001;

#---gate---
############################## !!!!!!!!!!!!!!

my $Vgatestart = 0.6;
my $Vgatestop = 0.8;
my $stepgate = 0.0001;

my $gateprotect = 1;			# 0 ist aus, 1 ist an
my $Vgatemax = 7;			# wird unten fürs gateprotect verwendet

my $gpib_yoko_backgate = 3;	
my $gpib_hp2 = 15;
my $gpib_lia = 7;

####################################################################

my @starttime = localtime(time);
my $startstring=sprintf("%04u-%02u-%02u_%02u-%02u-%02u",$starttime[5]+1900,$starttime[4]+1,$starttime[3],$starttime[2],$starttime[1],$starttime[0]);


my $Datum = "2012_05_16";
my $Time_Start=[gettimeofday()];
my $bias=-10; # *10 mV
my $sample="CB3224";
my $filename="$startstring gatesweep sample$sample ";
my $ampI=1e-11;
my $risetime=10; #ms

my $multitime = 10; # Integration time of multimeter in PLCs

my $lockinsettings='Frequency 47.7Hz, amplitude 100mV*10^-4=10µV RMS, Phase 0, sens=10mV, integ. time 0.3s';

#---init Yokogawa--- Gatespannung
my $type_gate="Lab::Instrument::Yokogawa7651";
my $YokGate=new $type_gate({
	'connection_type' =>'VISA_GPIB',
    'gpib_board'    => 0,
    'gpib_address'  => $gpib_yoko_backgate,
    'gate_protect'  => $gateprotect,
    'gp_max_units_per_second' => 0.05,
    'gp_max_step_per_second' => 10,
    'gp_max_units_per_step' => 0.01,
    #'gp_min_units' => -$Vgatemax,
    #'gp_max_units'  => $Vgatemax,
});

$YokGate->set_voltage($Vgatestart);

print "setting up Agilent for current through sample \n";
my $hp2=new Lab::Instrument::HP3458A({
	'connection_type' =>'VISA_GPIB',
	'gpib_board' => 0,
	'gpib_address' => $gpib_hp2,
	});

my $lia=new Lab::Instrument::SR830({
	'connection_type' =>'VISA_GPIB',
	'gpib_board' => 0,
	'gpib_address' => $gpib_lia,
	});
	print "setting up LIA finished! \n";
#my $lia=new Lab::Instrument::SR830(0,$gpib_lia);
#my $lia_amplitude=($lia->get_amplitude())*$DividerAC;


###################################################################################

my $comment=<<COMMENT;
Sample $sample
Gate sweep from $Vgatestart to $Vgatestop bias $bias mV
Ithako amp = $ampI; risetime= $risetime ms;
Messen der Ausgangsspannung des Ithaco über Agilent und Lock-in;
Lock-in-Einstellungen $lockinsettings;
Voltage divider AC: 1:10000
Multimeter integ. time (PLC) 10

B-field 0T at reference angle.
Temperature 35mK

COMMENT


####################################################################################



my $measurement=new Lab::Measurement(
    sample          => $sample,
    filename_base   => $filename,
    description     => $comment,

    live_plot       => 'Gatetrace',
    live_refresh    => '30',

    constants       => [
        {
            'name'          => 'ampI',
            'value'         => $ampI,
        },
    ],
    columns         => [
        {
            'unit'          => 'V',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gate',
        },
    	{
            'unit'          => 'A',
            'label'         => 'meas ac current $sample',
            'description'   => "meausred ac current through $sample",
        }
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => 'gate voltage',
            'description'   => 'Applied to backgate via 5Hz filter.',
        },
	{
            'unit'          => 'A',
            'expression'    => '$C2',
            'label'         => 'meas ac current through sample.',
            'description'   => 'Measured current through $sample',
        }
    ],
    plots           => {
        'Gatetrace'    => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'grid'          => 'xtics ytics',
        },
    },
);

###############################################################################

 
unless (($Vgatestop-$Vgatestart)/$stepgate > 0) {
    $stepgate = - $stepgate;
};
my $stepsign_gate=$stepgate/abs($stepgate);

$hp2->write("TARM AUTO");
$hp2->write("NPLC $multitime");


$measurement->start_block();		# von Markus

##Start der Messung
for (my $Vgate=$Vgatestart; $stepsign_gate*$Vgate<=$stepsign_gate*$Vgatestop; $Vgate+=$stepgate) {
	$YokGate->set_voltage($Vgate);
	#sleep(1);
	
	my $measIsample =$hp2->get_value();	# lese Strominfo von Ithaco
	chomp $measIsample;
	my ($Vacx,$Vacy)=$lia->get_xy();
		
    my $Idc = -($measIsample*$ampI);              # '-' für den Ithako, damit positives G rauskommt
	my $Iacx= -($Vacx*$ampI);
	my $Iacy= -($Vacy*$ampI);
    my $Iacr=sqrt($Iacx*$Iacx+$Iacy*$Iacy);
		
	$measurement->log_line($Vgate, $Idc, $Iacx, $Iacy, $Iacr);
    }

my $meta=$measurement->finish_measurement();

