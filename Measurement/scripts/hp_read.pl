#!/usr/bin/perl

#$Id$

use strict;
use Lab::Instrument::HP34401A;

################################

unless (@ARGV > 0) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $hp_gpib=$ARGV[0];

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $read_volt=$hp->read_voltage_dc(10,0.00001);

print "$read_volt\n";
