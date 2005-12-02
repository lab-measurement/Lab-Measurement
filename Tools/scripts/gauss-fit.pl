#!/usr/bin/perl

use strict;

my (@amplitude,@offset,@center1,@center2,@width);

my $filename=$ARGV[0];
for my $num (0..40) {
	open PARAMFILE,">fitparameters$num";
	print PARAMFILE 
		"a=2\n",
#		"o=0\n",
#		"c1=0.02\n",
		"c2=0.03\n",
		"w=0.1\n";
	;
	close PARAMFILE;	

	open FILE,">fit.gnuplot";
	print FILE
#		qq(f1(x)=o+a*exp(-((x-c1)**2)/(2*w**2))\n),
#		qq(f2(x)=o+a*exp(-((x-c2)**2)/(2*w**2))\n),
#		qq(f1(x)=o+a*exp(-((x-c1)**2)/(2*0.0431875**2))\n),
		qq(f1(x)=a*exp(-((x-c2)**2)/(2*w**2))\n),
#		qq(f2(x)=o+a*exp(-((x-c2)**2)/(2*0.0431875**2))\n),
#		qq(f(x)=f1(x)+f2(x)-o\n),
		qq(f(x)=f1(x)\n),
		qq(fit [0.00:0.07] f(x) "$filename" using 2:3 every :1::$num\::$num via "fitparameters$num"\n),
		qq(update "fitparameters$num"\n),
		qq(plot [*:*] "$filename" using 2:3 every :1::$num\::$num with lines,f(x)\n),
		qq(pause 1 "schau schau"\n);
	close FILE;
	`gnuplot "fit.gnuplot"`;

	open PARAMS,"<fitparameters$num";
	chomp($amplitude[$num]=<PARAMS>);
#	chomp($offset[$num]=<PARAMS>);
#	chomp($center1[$num]=<PARAMS>);
	chomp($center2[$num]=<PARAMS>);
	chomp($width[$num]=<PARAMS>);
	$amplitude[$num]=~s/^[^=]*=//;
#	$offset[$num]=~s/^[^=]*=//;
#	$center1[$num]=~s/^[^=]*=//;
	$center2[$num]=~s/^[^=]*=//;
	$width[$num]=~s/^[^=]*=//;
	close PARAMS;

	unlink "fitparameters$num";
	unlink "fitparameters$num.old";	
}
unlink "fit.gnuplot";

open FILE,">amplitudes";
for (0..$#amplitude) {
	print FILE $_,"\t",$amplitude[$_],"\t",$offset[$_],"\t",$center1[$_],"\t",$center2[$_],"\t",$width[$_],"\n";
}
close FILE;

open FILE,">amplitudes.gnuplot";
print FILE qq(plot "amplitudes" with linespoints\n);
close FILE;
