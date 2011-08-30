#!/usr/bin/perl -w

# (c) Daniel Schmid, Markus Gaass, David Kalok, Andreas Hüttel 2011
 
use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/gettimeofday/;
use Lab::Measurement;


########## configuration block ############

#---gate settings---

my $Vgatestart= 0;			# all gate voltages in V
my $Vgatestop = 0.1;
my $Vgatestep = 0.001;

my $Vgatemax = 7;			# for gateprotect

#---bias settings---

# we assume a 1:1000 voltage divider at the bias input

my $Vbiasstart= -5;			# all bias voltages in mV
my $Vbiasstop = 5;
my $Vbiasstep = 0.01;

my $Vbiasmax = 20;			# for "gateprotect"

#---about the sample---

my $sample="DB_3224";

#---about the setup---

my $preampVpI=1.0e10;			# preamplification ( V/A )

my $gpib_yoko_backgate = 3;
my $gpib_yoko_bias = 4;
my $gpib_hp = 12;

########## end configuration block ############


# day and time
my @starttime = localtime(time);
my $startstring=sprintf("%04u-%02u-%02u_%02u-%02u-%02u",
                $starttime[5]+1900, $starttime[4]+1, $starttime[3],
                $starttime[2], $starttime[1], $starttime[0]);

# filename
my $filename=$startstring."_sample_".$sample."_diamond";

# gate voltage source
my $YokGate=new Lab::Instrument::Yokogawa7651({
    'connection_type' => 'LinuxGPIB',
    'gpib_address'  => $gpib_yoko_backgate,
    'gate_protect'  => 1,
    'gp_max_volt_per_second' => 0.05,
    'gp_max_step_per_second' => 10,
    'gp_max_volt_per_step' => 0.005,
    'gp_min_volt' => -$Vgatemax,
    'gp_max_volt'  => $Vgatemax,
});

$YokGate->set_voltage($Vgatestart);

# bias voltage source
my $YokBias=new Lab::Instrument::Yokogawa7651({
    'connection_type' => 'LinuxGPIB',
    'gpib_address'  => $gpib_yoko_bias,
    'gate_protect'  => 1,
    'gp_max_volt_per_second' => 10,
    'gp_max_step_per_second' => 10,
    'gp_max_volt_per_step' => 1,
    'gp_min_volt' => -$Vbiasmax,
    'gp_max_volt'  => $Vbiasmax,
});

$YokBias->set_voltage($Vbiasstart);

# current measurement multimeter (measures voltage at output of preamp)
my $HP=new Lab::Instrument::HP34401A(
    'connection_type' => 'LinuxGPIB',
    'gpib_address'  => $gpib_hp,
);

# the comment text for the metadata
my $comment=<<COMMENT;
Sample $sample
Coulomb diamond measurement
Gate from $Vgatestart to $Vgatestop step $Vgatestep V
Bias from $Vbiasstart to $Vbiasstop step $Vbiasstep mV
Preamplifier setting $preampVpI V/A
$startstring
COMMENT

# the measurement
my $measurement=new Lab::Measurement(
    sample          => $sample,
    filename_base   => $filename,
    description     => $comment,

    live_plot       => 'diamonds',
    live_refresh    => '200',

    constants       => [
        {
            'name'          => 'ampI',
            'value'         => $preampVpI,
        },
    ],
    columns         => [
        {
            'unit'          => 'V',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gate',
        },
        {
            'unit'          => 'mV',
            'label'         => 'Bias voltage',
            'description'   => 'Applied to source',
        },
    	{
            'unit'          => 'A',
            'label'         => 'meas dc current $sample',
            'description'   => "meausred current through $sample",
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
            'unit'          => 'mV',
            'expression'    => '$C1',
            'label'         => 'bias voltage',
            'description'   => 'Applied to source.',
        },
	{
            'unit'          => 'A',
            'expression'    => '$C2',
            'label'         => 'meas dc current through sample.',
            'description'   => 'Measured current through $sample',
        }
    ],
    plots           => {
        'diamonds'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
	    'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
    },
);


#########################################################################


# all setup is done, now comes the actual measurement

# for the gate:

# we have to make sure that the step size has the correct sign to 
# go from start to stop 
if (($Vgatestop-$Vgatestart)/$Vgatestep<0) { $Vgatestep=-$Vgatestep; };

# which way are we going?
my $stepsign_gate=$Vgatestep/abs($Vgatestep);

# for the bias:

# we have to make sure that the step size has the correct sign to 
# go from start to stop 
if (($Vbiasstop-$Vbiasstart)/$Vbiasstep<0) { $Vbiasstep=-$Vbiasstep; };

# which way are we going?
my $stepsign_bias=$Vbiasstep/abs($Vbiasstep);




# the outer measurement loop
for (my $Vgate=$Vgatestart;
     $stepsign_gate*$Vgate<=$stepsign_gate*$Vgatestop; 
     $Vgate+=$Vgatestep) {

	# set gate voltage
	$YokGate->set_voltage($Vgate);

	# set bias voltage
	$YokBias->set_voltage($Vbiasstart);

	# wait a moment
	sleep(1);

	# every "trace" in a measurement has to start with this
	$measurement->start_block();

	# the inner measurement loop
	for (my $Vbias=$Vbiasstart;
	    $stepsign_bias*$Vbias<=$stepsign_bias*$Vbiasstop; 
	    $Vbias+=$Vbiasstep) {

		# set bias voltage
		$YokBias->set_voltage($Vbias);

		# read out multimeter
		my $measVpreamp =$HP->get_value();

		# make sure the result does not contain any linefeeds
		chomp $measVpreamp;

		# write into datafile
		$measurement->log_line($Vgate, $Vbias,
				       $measVpreamp/$preampVpI);

	}
}


# and we're done
my $meta=$measurement->finish_measurement();

