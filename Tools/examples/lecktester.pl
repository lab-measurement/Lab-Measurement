#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep gettimeofday/;
use Term::ReadKey;

unless (@ARGV == 4) {
    print "Usage: $0 GPIB-address Sensitivity Filename Comment\n";
    print $#ARGV,join " - ",@ARGV;
    exit;
}
my ($gpib,$bereich,$filename,$comment)=@ARGV;

my $hp=new Lab::Instrument::HP34401A({GPIB_board=>0,GPIB_address=>$gpib});

my $gp1=<<GNUPLOT1;
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M:%S"
set ylabel "Leak rate (10^{-9} mbar l s^{-1})"
set xlabel "Time"
set xtics rotate
set title "$comment"
plot "$filename" using 1:3 with lines
GNUPLOT1
my $gp2=<<GNUPLOT2;
replot
pause 3
reread
GNUPLOT2
open GP,">$filename.gnuplot" or die "cannot open gnuplot file";
print GP $gp1,$gp2;
close GP;

open LOG,">$filename" or die "cannot open log file";
my $old_fh = select(LOG);
$| = 1;
select($old_fh);

print LOG "#$comment\n";

#nur damit gnuplot kein leeres file findet
    my $read_volt=$hp->read_voltage_dc(10,0.0001);
    $read_volt=12 if ($read_volt > 12);
    my $rate=($read_volt/10)*$bereich;
    my ($s,$ms)=gettimeofday();
    my ($sec,$min,$hour,$mday,$mon,$year)=localtime($s);
    $year+=1900;$mon++;
    printf LOG "%4d-%02d-%02d %02d:%02d:%.2f\t%f\n",$year,$mon,$mday,$hour,$min,$sec+$ms/1e6,$rate;

system("gnuplot $filename.gnuplot &");

print "Leak test in progress\nPress 's' to stop; 'm' to mark position.\n";

my $key;
ReadMode('cbreak');
while ($key ne "s") {
    my $read_volt=$hp->read_voltage_dc(10,0.0001);
    $read_volt=12 if ($read_volt > 12);
    my $rate=($read_volt/10)*$bereich;
    my ($s,$ms)=gettimeofday();
    my ($sec,$min,$hour,$mday,$mon,$year)=localtime($s);
    $year+=1900;$mon++;
    my $timestamp=sprintf "%4d-%02d-%02d %02d:%02d:%.2f\t%f",$year,$mon,$mday,$hour,$min,$sec+$ms/1e6,$rate;
    print LOG "$timestamp\n";
    if ($key eq "m") {
        print "Marking position $timestamp\n";
        $gp1.=qq(set arrow from "$timestamp", graph 0 to "$timestamp", graph 1 nohead\n);
        open GP,">$filename.gnuplot" or die "cannot open gnuplot file";
        print GP $gp1,$gp2;
        close GP;
    }
    usleep(500000);
    $key=ReadKey(-1);
}
ReadMode('normal');
close LOG;
