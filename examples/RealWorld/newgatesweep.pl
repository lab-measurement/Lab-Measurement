#!/usr/bin/perl -w

# Daniel Schmid, July 2010, composed following Markus'  & David's perl-scripts
 
use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP3458A;
use Time::HiRes qw/gettimeofday/;
use Lab::Measurement;



#---gate---
############################## !!!!!!!!!!!!!!

my $Vgatestart = 0.665;
my $Vgatestop = 0.695;
my $stepgate = 0.0001;

my $gateprotect = 1;			# 0 ist aus, 1 ist an
my $Vgatemax = 8;			# wird unten fürs gateprotect verwendet

my $gpib_yoko_backgate = 3;	
my $gpib_hp = 13;

####################################################################

my @starttime = localtime(time);
my $startstring=sprintf("%04u-%02u-%02u_%02u-%02u-%02u",$starttime[5]+1900,$starttime[4]+1,$starttime[3],$starttime[2],$starttime[1],$starttime[0]);


my $bias=2.0; #mV
my $sample="CB3224";
my $filename="$startstring gatesweep sample$sample";
my $ampI=1e-11;


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
	'fast_set' => 1,
    'gp_min_units' => -$Vgatemax,
    'gp_max_units'  => $Vgatemax,
});

$YokGate->set_voltage($Vgatestart);

print "setting up Agilent for current through sample \n";
my $hp=new Lab::Instrument::HP3458A({
	'connection_type' =>'VISA_GPIB',
	'gpib_board' => 0,
	'gpib_address' => 15,
	});

###################################################################################

my $comment=<<COMMENT;
Sample $sample
Gate sweep from $Vgatestart to $Vgatestop bias $bias mV
Ithaco amplification $ampI
Voltage divider 1:1000 on source

COMMENT


####################################################################################



my $measurement=new Lab::Measurement(
    sample          => $sample,
    filename_base   => $filename,
    description     => $comment,

    live_plot       => 'Gatetrace',
    live_refresh    => '5',

    constants       => [
        {
            'name'          => 'ampI',
            'value'         => $ampI,
        },
    ],
    columns         => [
        {
            'unit'          => 'V',
            'label'         => 'Vg',
            'description'   => 'Gate voltage',
        },
    	{
            'unit'          => 'A',
            'label'         => 'I',
            'description'   => "meausred current through $sample",
        }
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => 'Vg',
            'description'   => 'gate voltage',
        },
	{
            'unit'          => 'A',
            'expression'    => '$C1',
            'label'         => 'I',
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

$hp->write("TARM AUTO");
$hp->write("NPLC 8");

$measurement->start_block();

##Start der Messung
for (my $Vgate=$Vgatestart; $stepsign_gate*$Vgate<=$stepsign_gate*$Vgatestop; $Vgate+=$stepgate) {
	#print "Go to $Vgate ";
	$YokGate->set_voltage($Vgate);
	#rint "done\nGet value ";
	my $measIsample =$hp->get_value();	# lese Strominfo von Ithaco
	#print "done\n";
	chomp $measIsample;
	$measurement->log_line($Vgate, -$measIsample*$ampI);
    }

my $meta=$measurement->finish_measurement();

