#!/usr/bin/perl
#$Id$

use strict;
use Lab::Instrument::Yokogawa7651;

unless (@ARGV > 0) {
    print "Usage: $0 GPIB-address [goto_voltage]\n";
    exit;
}

my ($gpib,$goto)=@ARGV;

my $source=new Lab::Instrument::Yokogawa7651(
        connection_type=>'LinuxGPIB',
        gpib_address => $gpib,
        gpib_board=>0,
	gate_protect=>1,
	gp_max_volt_per_second=>0.05,
	gp_max_step_per_second=>10,
	gp_max_volt_per_step=>0.005
);

if (defined $goto) {
    $source->set_voltage($goto);
} else {
    print $source->get_voltage();
}
