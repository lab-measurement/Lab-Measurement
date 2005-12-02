#!/usr/bin/perl

use strict;

my ($filename,$outname)=@ARGV;
# bluna, knick, cond, curr

open FILE, "$filename";
open OUTF,">$outname";

my $blocknum=0;
my ($sum,$num,$prenum,$magval);
while (chomp(my $line=<FILE>)) {
	unless ($line =~ /^#/) {
		if ($line eq "") {
			print OUTF "$magval\t",$sum/$num,"\n";
			$blocknum++;
			$sum=0;
			$num=0;
			$prenum=0;
		} else {
			my @value=split"\t",$line;
			if ($prenum< 300) {
				$prenum++;
			} else {
				$sum+=$value[2];
				$magval=$value[0];
				$num++;
			}
		}
	}
}
close FILE;
close OUTF;
