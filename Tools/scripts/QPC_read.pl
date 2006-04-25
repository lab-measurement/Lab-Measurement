#!/usr/bin/perl

#$Id: QPC_noise.pl 361 2006-04-18 16:39:19Z schroeer $

use strict;
use Lab::Instrument::HP34401A;

################################

my $hp_gpib=24;

my $v_sd=780e-3/1563;
my $amp=1e-7;    # Ithaco amplification

my $U_Kontakt=(shift @ARGV) || 3.94;

################################

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $read_volt=$hp->read_voltage_dc(1,0.00001);

printf "QPC conductance G=%f\n",(1/(1/abs($read_volt)-1/$U_Kontakt)) * ($amp/($v_sd*7.748091733e-5))
