#!/usr/bin/perl
#$Id$

# This is an example of how to perform a simple gate voltage
# sweep at controlled speed, where the timing is done by the
# gp_... mechanism.

# Adjust the GPIB addresses to your local settings.

use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP34401A;

my $yoko=new Lab::Instrument::Yokogawa7651({
	'GPIB_board'				=> 0,
	'GPIB_address'				=> 10,
	'gp_max_volt_per_second'	=> 0.001});

my $hp=new Lab::Instrument::HP34401A(0,24)

for (273..432) {
    my $volt=$_/1000;
    $yoko->set_voltage($volt);
    my $meas=$hp->get_voltage();
    print "$volt\t$meas\n";
}
