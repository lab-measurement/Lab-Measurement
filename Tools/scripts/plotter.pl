#!/usr/bin/perl

use strict;
use Lab::Data::Plotter;

my $plotter=new Lab::Data::Plotter();

my $gp=$plotter->plot(@ARGV);

my $a=<stdin>;