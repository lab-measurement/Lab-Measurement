#!/usr/bin/perl

#23.11.05: averaged die zweite und dritte Spalte eines Files
#(alle averagen, bei denen erste Spalte gleich ist)

use strict;

my ($filename,$outname)=@ARGV;

open FILE,"<$filename";
open OUTF,">$outname";

my ($min,$minsum,$max,$maxsum,$mag,$oldmag,$numsum);
$oldmag=-1000;

while (chomp(my $line=<FILE>)) {
	my ($mag,$min,$max)=split"\t",$line;
	if ($mag == $oldmag) {
		$maxsum+=$max;
		$minsum+=$min;
		$numsum++;
	} else {
		if ($numsum > 0) {
			print OUTF "$oldmag\t",$minsum/$numsum,"\t",$maxsum/$numsum,"\n";
		}
		$numsum=1;
		$maxsum=$max;
		$minsum=$min;
		$oldmag=$mag;
	}
}
close FILE;
close OUTF;
		
