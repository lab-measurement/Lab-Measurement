#!/usr/bin/perl

use strict;

my ($filename,$outname)=@ARGV;

my (@min,@max);

open FILE,"<$filename";
open OUTF,">$outname";
my $blocknum=0;
my $magval;
while (chomp(my $line=<FILE>)) {
	unless ($line =~ /^#/) {
		if ($line eq "") {
			print OUTF "$magval\t$min[$blocknum]\t$max[$blocknum]\n";
			$blocknum++;
		} else {
			my @value=split"\t",$line;
			$magval=$value[0];
			my $testval=$value[2];
			if (($value[1] > -0.05) && ($value[1] < 0.15)) {
				unless ((defined $max[$blocknum]) && ($max[$blocknum] > $testval)) {
					$max[$blocknum]=$testval;
				}
			}
			unless ((defined $min[$blocknum]) && ($min[$blocknum] < $testval)) {
				$min[$blocknum]=$testval;
			}
		}
	}
}
close FILE;
close OUTF;
		
