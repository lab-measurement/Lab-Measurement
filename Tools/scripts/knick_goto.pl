#!/usr/bin/perl
#$Id$

use strict;
use Lab::Instrument::KnickS252;

unless (@ARGV > 0) {
    print "Usage: $0 GPIB-address [goto_voltage]\n";
    exit;
}

my ($gpib,$goto)=@ARGV;

my $source=new Lab::Instrument::KnickS252(0,$gpib);

if (defined $goto) {
    $source->sweep_to_voltage($goto);
} else {
    print $source->get_voltage();
}
