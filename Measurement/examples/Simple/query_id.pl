#!/usr/bin/perl

use strict;
use Lab::Instrument;

################################

unless (@ARGV > 0) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $gpib=$ARGV[0];

print "Querying ID of instrument at GPIB address $gpib\n";

my $i=new Lab::Instrument(
	connection_type=>'LinuxGPIB',
	gpib_address => $gpib,
	gpib_board=>0,
);

my $id=$i->query('*IDN?');

print "Query result: \"$id\"\n";
