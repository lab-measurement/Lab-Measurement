#!/usr/bin/perl

use strict;

my $lastx=1;
my $lasty;
while (<>) {
	s/\n\r//g;;
	if (/([\d\-\.E];)/) {
		my @values=split ";",$_;
		my $ableitung=($values[1]-$lasty)/($values[0]-$lastx);
		print $values[0],"\t",$ableitung/1000,"\n";
		$lasty=$values[1];
		$lastx=$values[0];
	}
}