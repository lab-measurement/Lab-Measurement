#!/usr/bin/perl
#$Id: simple_knick.pl 85 2005-11-10 23:35:43Z schroeer $

use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP34401A;
use Lab::Measurement;

my $yoko=new Lab::Instrument::Yokogawa7651({
	'GPIB_board'				=> 0,
	'GPIB_address'				=> 10,
	'gp_max_volt_per_second'	=> 0.001});

my $hp=new Lab::Instrument::HP34401A(0,24)

my $log=new Lab::Measurement();	#auto filename generation

for (273..432) {
    my $volt=$_/1000;
    $yoko->set_voltage($volt);
    my $meas=$hp->get_voltage();
    log_line($volt,$meas);
}
