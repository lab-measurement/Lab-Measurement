#!/usr/bin/perl

use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP34970A;
use Time::HiRes qw/usleep/;

my $yoko=new Lab::Instrument::Yokogawa7651({GPIB_address=>16});
my $hp=new Lab::Instrument::HP34970A({GPIB_address=>25});

$hp->conf_monitor(101);

for (my $V=0;$V<1;$V+=.1) {
    $yoko->set_voltage($V);
    usleep(50000);
    my $read=$hp->read_monitor();
    print "$V\t$read\n";
}
