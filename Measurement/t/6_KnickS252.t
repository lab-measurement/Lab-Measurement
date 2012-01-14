#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 3;

BEGIN { use_ok('Lab::Instrument::KnickS252') };

ok(my $knick=new Lab::Instrument::KnickS252({
	'GPIB_board'				=> 0,
	'GPIB_address'				=> 15,
	'gp_max_volt_per_second'	=> 0.021}),'Open any Knick');
ok(my $voltage=$knick->get_voltage(),'get_voltage()');
diag "read $voltage";
