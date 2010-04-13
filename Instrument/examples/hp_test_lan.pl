#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34411A;
use Time::HiRes qw/usleep/;

my $resourcename="TCPIP0::10.153.115.250::INSTR";
# replace 10.153.115.250 with the actual IP set via the front panel

my $hp=new Lab::Instrument::HP34411A($resourcename);

print $hp->read_voltage_dc(10,0.0001),"\n";
