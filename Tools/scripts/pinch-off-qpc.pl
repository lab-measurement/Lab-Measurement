#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Lab::Instrument::KnickS252;
use Time::HiRes qw/usleep gettimeofday/;
use File::Basename;

my $start_voltage=0;
my $end_voltage=-0.02;

unless (@ARGV == 5) {
    print "This program pinches-off a QPC using a Knick.\n";
    print "Usage: $0 Gate-GPIB Current-GPIB Amplification Filename Comment\n";
    exit;
}
my ($knick_gpib,$hp_gpib,$amp,$file,$comment)=@ARGV;

my ($filename,$path,$suffix)=fileparse($file, qr/\.[^.]*/);

my $knick=new Lab::Instrument::KnickS252(0,$knick_gpib);
my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

print "Driving source to start value...\n";
$knick->sweep_to_voltage($start_voltage);

my $gp1=<<GNUPLOT1;
set ylabel "QPC Current (A)"
set xlabel "Gate voltage (V)"
set title "$comment"
GNUPLOT1
my $gp2=<<GNUPLOT2;
plot "$filename$suffix" using 1:(\$2*$amp) with lines
GNUPLOT2

my $gpipe=get_pipe() or die;
print $gpipe $gp1;

open LOG,">$path$filename$suffix" or die "cannot open log file";
my $old_fh = select(LOG);
$| = 1;
select($old_fh);

print LOG "#$comment\n#\n",'#Measured with $Id$',"\n#Parameters: Knick-GPIB: $knick_gpib; HP-GPIB: $hp_gpib; Amplification: $amp\n";

for (my $volt=$start_voltage;$volt>=$end_voltage;$volt-=5e-4) {
    $knick->set_voltage($volt);
    usleep(500000);
    my $read_volt=$hp->read_voltage_dc(10,0.0001);
    print LOG "$volt\t$read_volt\n";
    print $gpipe $gp2;
}
close LOG;
close $gpipe;

open GP,">$path$filename.gnuplot" or die "cannot open gnuplot file";
print GP <<GNUPLOT3,$gp1,$gp2;
set term post col enh
set out "$filename.ps"
GNUPLOT3

system("gnuplot $path$filename.gnuplot");
system("gv $path$filename.ps &");

sub get_pipe {
	my $gpname;
	if ($^O =~ /MSWin32/) {
		$gpname="pgnuplot";
	} else {
		$gpname="gnuplot";
	}
	if (open my $GP,"| $gpname -noraise") {
		my $oldfh = select($GP);
		$| = 1;
		select($oldfh);
		return $GP;
	}
	return undef;
}
