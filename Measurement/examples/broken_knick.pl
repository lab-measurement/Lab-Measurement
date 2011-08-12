#!/usr/bin/perl

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34970A;
use Time::HiRes qw/usleep/;

my $knick=new Lab::Instrument::KnickS252({GPIB_board=>0,GPIB_address=>16});
my $hp=new Lab::Instrument::HP34970A({GPIB_board=>0,GPIB_address=>25});

$hp->conf_monitor(101);

open LOG,">$ARGV[0]" or die $!;
my @values=map {$_/10000} (-100000..100000);
push @values,map {cos($_/2000)*10} (0..300000);
my $num=0;
for my $V (@values) {
    $num++;
    $knick->set_voltage($V);
    usleep(50000);
    #my $read_volt=$hp->read_voltage_dc(10,0.0001,101);
    my $read_volt=$hp->read_monitor();
    my $diff=$V-$read_volt;
#    if ($diff > 1e-2) {
#        printf("Alarm: num: %i set: %.4e read: %.4e diff: %.4e\n",$num,$V,$read_volt,$diff);
        printf LOG "%e\t%e\n",$V,$read_volt;
#    }
}
close LOG;
