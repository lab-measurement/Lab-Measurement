#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Lab::Instrument::KnickS252;

# Connect to voltage source
my $knick=new Lab::Instrument::KnickS252({
    GPIB_address    => 14,
    gate_protect    => 0,
});

# Connect to multimeter
my $hp=new Lab::Instrument::HP34401A(0,21);

# Sweep Knick from 0 to 1 volt (10 steps)
for my $volt (0..10) {
    # set Knick
    $knick->set_voltage($volt/10);
    
    # wait a second
    sleep(1);
    
    # read multimeter
    my $v_r=$hp->read_voltage_dc();
    
    # print values
    print $volt/10,"\t$v_r\n";
}
