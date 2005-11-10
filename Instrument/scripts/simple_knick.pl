#!/usr/bin/perl
#$Id: 6_KnickS252.t 75 2005-11-09 23:24:29Z schroeer $

use strict;
use Lab::Instrument::KnickS252;

my $knick=new Lab::Instrument::KnickS252({
	'GPIB_board'				=> 0,
	'GPIB_address'				=> 16,
	'gp_max_volt_per_second'	=> 0.021});
$knick->set_voltage(1);
my $voltage=$knick->get_voltage();
print "read $voltage";
