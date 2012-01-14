#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep/;

my $hp=new Lab::Instrument::HP34401A({GPIB_board=>0,GPIB_address=>21});

print $hp->read_voltage_dc(10,0.0001),"\n";
