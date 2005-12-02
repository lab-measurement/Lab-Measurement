#!/usr/bin/perl

use strict;

for (@ARGV) {
	unless ($_ =~ /\.TSK$/) {die;}
	open IN,"<$_" or die;
	my $newname=$_;
	$newname=~s/\.TSK/.RAW/;
	open OUT,">$newname" or die;
	for (1..4) {
		my $line=<IN>;
		print OUT "#$line";
	}
	while (<IN>) {
		print OUT $_;
	}
	close OUT;
	close IN;
}

