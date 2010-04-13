#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34411A;
use Time::HiRes qw/usleep/;

my $resourcename="USB0::2391::1543::MY47007219::INSTR";
# for the Agilent 34411A, you can get this string via 
# Utility Menu -> Remote I/O -> USB -> USB-ID 

# on a linux system, you need write access to the respective USB device!

my $hp=new Lab::Instrument::HP34411A($resourcename);

print $hp->read_voltage_dc(10,0.0001),"\n";
