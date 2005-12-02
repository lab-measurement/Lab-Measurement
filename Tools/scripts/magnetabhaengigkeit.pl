#!/usr/bin/perl

use strict;

my @sd_values=(-0.2,-0.15,-0.1,0,0.05,0.1,0.15,0.2,0.25,0.3,0.35);


my ($filename,$newname)=@ARGV;
 
#Daten einlesen
open FILE,"<$filename";
my $blocknum;
my $linenum;
my $data=[[[]]];
while (chomp(my $line=<FILE>)) {
	unless ($line =~ /^#/) {
		if ($line eq "") {
			$blocknum++;
			$linenum=0;
		} else {
			@{$data->[$blocknum]->[$linenum++]}=split"\t",$line;
		}
	}
}
close FILE;

my $mag;
my @output=();

for $blocknum (0..$#{$data}) {
	for $linenum (0..$#{$data->[$blocknum]}) {
		($mag,my $vsd,my $cond)=@{$data->[$blocknum]->[$linenum]};
		for (0..$#sd_values) {
			if ($vsd == $sd_values[$_]) {
				$output[$_].="$vsd\t$mag\t$cond\n";
			}
		}
	}
}

open OUTFILE,">$newname";
for (@output) {
	print OUTFILE "$_\n";
}
close OUTFILE;

print "plot ";
for (0..$#sd_values) {
	print qq("$newname" using (\$2*1000):3 every :1::$_\::$_ title "V_{sd}=),$sd_values[$_]*2,qq(mV" with linespoints);
	if ($_<$#sd_values) { print ", "; }
}
print "\n";
