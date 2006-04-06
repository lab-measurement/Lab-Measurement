#!/usr/bin/perl
#$Id$

# This is an example of how to use the advanced features
# to simplify the task of voltage sweeping and data logging.

# Doesn't work yet. 

# The measurement records a conductance curve of a quantum point contact.

# Adjust the GPIB addresses to your local settings.

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Measurement;

my $start_voltage=0;
my $end_voltage=-0.1;
my $step=-1e-3;

my $amp=1e-8;    # Ithaco amplification
my $v_sd=780e-3/1563;
my $U_Kontakt=12.827;

my $g0=7.748091733e-5;

my $knick=new Lab::Instrument::KnickS252({
	'GPIB_board'	=> 0,
	'GPIB_address'	=> 14,
    'gate_protect'  => 0,

	'gp_max_volt_per_second' => 0.001,
});

my $hp=new Lab::Instrument::HP34401A({
	'GPIB_address'	=> 24,
});


my $measurement=new Lab::Measurement(
	sample			=> 'S11_3',
	title			=> 'QPC sweep',
	filename_base	=> 'qpc_pinch_off',
	description		=> <<END_DESCRIPTION,
Yet another sweep for the top left quantum point contact.
Source-Drain-Voltage $v_sd V applied to contact 24.
END_DESCRIPTION

    live_plot   	=> 'QPC current',
        
	columns			=> [
		{
			'unit'		  	=> 'V',
			'label'		  	=> 'Gate voltage',
			'description' 	=> 'Applied to gates 16 and 17 via low path filter.',
		},
		{
			'unit'			=> 'V',
			'label'			=> 'Amplifier output',
			'description' 	=> "Voltage output by current amplifier set to $amp.",
		}
	],
	axes			=> [
		{
			'unit'			=> 'V',
            'expression'  	=> '$C0',
			'label'		  	=> 'Gate voltage',
            'min'           => ($start_voltage < $end_voltage) ? $start_voltage : $end_voltage,
            'max'           => ($start_voltage < $end_voltage) ? $end_voltage : $start_voltage,
			'description' 	=> 'Applied to gates 16 and 17 via low path filter.',
		},
		{
			'unit'			=> 'A',
			'expression'	=> "\$C1*$amp",
			'label'			=> 'QPC current',
			'description'	=> 'Current through QPC 1',
		},
        {
            'unit'          => '2e^2/h',
            'expression'    => "(\$A1/$v_sd)/$g0)",
            'label'         => "Total conductance",
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(1/(1/abs(\$C1)-1/$U_Kontakt)) * ($amp/($v_sd*$g0))",
            'label'         => "QPC conductance",
        },
        
	],
    plots       	        => {
        'QPC current'    => {
            'type'          => 'line',
            'xaxis'        => 0,
            'yaxis'        => 1,
        },
        'QPC conductance'=> {
            'type'         => 'line',
            'xaxis'        => 0,
            'yaxis'        => 3,
        }
    },
);

my $stepsign=$step/abs($step);

for (my $volt=$start_voltage;$stepsign*$volt<=$stepsign*$end_voltage;$volt+=$step) {
    $knick->set_voltage($volt);
    my $meas=$hp->read_voltage_dc(100,0.0001);
    $measurement->log_line($volt,$meas);
}

$measurement->finish_measurement();
