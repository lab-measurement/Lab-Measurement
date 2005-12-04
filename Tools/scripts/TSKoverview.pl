#!/usr/bin/perl

use strict;

my $basename;
unless ($basename=$ARGV[0]) {
	print "This programm generates an overview postscript file of the data files a multidim sweep with GPPlus. usage: $0 <basename>\n";
	exit;
}

open IN,"<$basename\.RAW" or die;
my $numblocks;
my @max=(-1e38)x3;
my @min=(1e38)x3;
while (<IN>) {
	chomp;
	unless ($_) {
		$numblocks++;
	} elsif (/([\d\-\.E]\t)/) {
		my @value=split "\t";
		for (0..2) {
			if ($value[$_] > $max[$_]) {
				$max[$_]=$value[$_];
			}
			if ($value[$_] < $min[$_]) {
				$min[$_]=$value[$_];
			}
		}
	}
}
close IN;

open OUT,">$basename\.gnuplot" or die;
print OUT <<ENDE;
set xlabel 'Gate-Spannung V_{oben} (mV)'
set ylabel 'Source-Drain-Spannung V_{SD} (V)'
set cblabel 'Strom (A)'
set terminal postscript enhanced color
set output "$basename\_overview.ps"
ENDE
for (0..$numblocks-1) {
	print OUT 'set title "Scan '.($_+1).'"',"\n";
	print OUT "plot [$max[1]:$min[1]] [$max[2]:$min[2]] \"$basename\.RAW\" every :::$_\::$_ using 2:3 with lines\n";
}
close OUT;
