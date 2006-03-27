#!/usr/bin/perl
#$Id$

use strict;
use Lab::Instrument::Yokogawa7651;

unless (@ARGV == 2) {
    print "Usage: $0 GPIB-address goto_voltage\n";
    exit;
}

my ($gpib,$goto)=@ARGV;

my $source=new Lab::Instrument::Yokogawa7651(0,$gpib);

$source->sweep_to_voltage($goto);
