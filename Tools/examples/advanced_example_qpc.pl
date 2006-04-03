#!/usr/bin/perl
#$Id$

# This is an example of how to use the advanced features
# to simplify the task of voltage sweeping and data logging.

# Doesn't work yet. 

# The measurement records a conductance curve of a quantum point contact.

# Adjust the GPIB addresses to your local settings.

use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP34401A;
use Lab::Measurement;

my $amp;    # Ithaco amplification
my $v_sd;
my $U_Kontakt;

my $yoko=new Lab::Instrument::Yokogawa7651({
	'GPIB_board'	=> 0,
	'GPIB_address'	=> 10,

	'gp_max_volt_per_second' => 0.001,
});

my $hp=new Lab::Instrument::HP34401A({
	'GPIB_address'	=> 24,
});


start_measurement(
	sample		=> 'S11_3',
	title		=> 'QPC sweep', #auto name-generation?
	description	=> <<END_DESCRIPTION,
Yet another sweep for the top left quantum point contact.
Source-Drain-Voltage $v_sd V applied to contact 24.
END_DESCRIPTION

	columns		=> [
		{
			'unit'		  	=> 'V',
			'label'		  	=> 'Gate voltage',
			'description' 	=> 'Applied to gates 16 and 17 via low path filter.',
		},
		{
			'unit'			=> 'V',
			'label'			=> 'Amplifier output',
			'description' 	=> "Voltage measured by current amplifier set to $amp.",
		}
	],
	axes		=> [
		{
			'unit'			=> 'V',
            'expression'  	=> '$C1',
			'label'		  	=> 'Gate voltage',
			'description' 	=> 'Applied to gates 16 and 17 via low path filter.',
		},
		{
			'unit'			=> 'A',
			'expression'	=> "\$C2*$amp",
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
            'expression'    => "(1/(1/abs(\$C2)-1/$U_kontakt)) * ($amp/($v_sd*$g0))",
            'label'         => "QPC conductance",
        },
        
	],
    plots       => [],
        
);

for (my $gate_volt=0;$gate_volt-=1e-3;$gate_volt>=-0.7) {
    $yoko->set_voltage($gate_volt);
    my $meas=$hp->get_voltage();
    log_line($volt,$meas);
}

finish_measurement();
