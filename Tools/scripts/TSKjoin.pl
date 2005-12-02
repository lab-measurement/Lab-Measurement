#!/usr/bin/perl

use strict;

my $basename;
unless ($basename=$ARGV[0]) {
	print "This programm can join the datafiles of a multidim sweep with GPplus\nusage: $0 <basename>\n";
	exit;
}
$basename=~s/_$//;

my @files=sort {
	($a =~ /$basename\_(\d+)\.TSK/)[0] <=> ($b =~ /$basename\_(\d+)\.TSK/)[0]
				} glob $basename."_*.TSK";
(my $path)=($basename =~ m{((/?[^/]+/)+)?[^/]+$})[0];
$basename =~ s{(/?[^/]+/)+}{};
my $newname=$basename.".RAW";
if (-e $path.$newname) {die "destination file $path$newname already exists"}
open OUT,">$path$newname" or die;
for (@files) {
	open IN,"<$_" or die;
	while (<IN>) {
		s/[\n\r]+$//g;
		if (/^([\d\-+\.E]+;?)+$/) {
			if (/E+37/) { print "Attention: Contains bad data due to overload!\n" }
			my @values=split ";";
			print OUT (join "\t",@values),"\n";
		} else {
			print OUT "#$_\n" if ($_);
		}
	}
	print OUT "\n";
	close IN;
}

print $#files+1," files.\n";

print "Move raw data files to subfolder $path$basename\_rawdata/ (y/n)? ";
chomp(my $move=<STDIN>);
if ($move eq 'y') {
	if (-d $path.$basename."_rawdata") {
		die "folder exists";
	} else {
		mkdir $path.$basename."_rawdata" or die "cannot create directory";
	}
	for (glob $path.$basename."_*.TSK") {
		s{(/?[^/]+/)+}{};
		rename $path.$_,$path.$basename."_rawdata/".$_;
	}
}
	
close OUT;
