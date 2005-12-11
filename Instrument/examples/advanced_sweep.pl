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

my $yoko=new Lab::Instrument::Yokogawa7651({
	'GPIB_board'	=> 0,
	'GPIB_address'	=> 10,

	'gp_max_volt_per_second' => 0.001,

	'unit'		  	=> 'V',
	'label'		  	=> 'Gate voltage',
	'description' 	=> 'Applied to gates 16 and 17 via low path filter',
});

my $knick=new Lab::Instrument::KnickS252({
	'GPIB_board'	=> 0,
	'GPIB_address'	=> 10,

	'gp_max_volt_per_second' => 0.1,

	'unit'			=> 'V',
	'label'			=> 'Bias voltage',
	'description' 	=>
		'Applied to source contact 12 via combined voltage divider (1/1000) and mixer box. '.
		'Mixed to Lock-In signal 1V/50000 @ 33Hz.',
});

my $hp=new Lab::Instrument::HP34401A({
	'GPIB_address'	=> 24,
	'unit'			=> 'V',
	'label'			=> 'Conductance',
	'description' 	=> 'Voltage ',
});


start_measurement(
	sample		=> 'S11_3',
	title		=> 'QPC sweep', #auto name-generation?
	description	=> 'Yet another sweep for the top left quantum point contact',
);

for (273..432) {
    my $volt=$_/1000;
    $yoko->set_voltage($volt);
    my $meas=$hp->get_voltage();
    log_line($volt,$meas);
}

finish_measurement();
