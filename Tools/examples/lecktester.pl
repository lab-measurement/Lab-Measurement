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

open GP,">$filename.gnuplot" or die "cannot open gnuplot file";
print GP <<GNUPLOT;
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M:%S"
set ylabel "Leak rate (10^{-9} mbar l s^{-1})"
set xlabel "Time"
set xtics rotate
set title "$comment"
plot "$filename" using 1:3 with lines
pause 5
reread
GNUPLOT
close GP;

open LOG,">$filename" or die "cannot open log file";
my $old_fh = select(LOG);
$| = 1;
select($old_fh);

#nur fdamit gnuplot kein leeres file findet
    my $read_volt=$hp->read_voltage_dc(10,0.0001);
    $read_volt=12 if ($read_volt > 12);
    my $rate=($read_volt/10)*$bereich;
    my ($s,$ms)=gettimeofday();
    my ($sec,$min,$hour,$mday,$mon,$year)=localtime($s);
    $year+=1900;$mon++;
    printf LOG "%4d-%02d-%02d %02d:%02d:%.2f\t%f\n",$year,$mon,$mday,$hour,$min,$sec+$ms/1e6,$rate;

system("gnuplot $filename.gnuplot &");

print "Leak test in progress\n";
print LOG "#$comment\n";

my $key;
while (not defined ($key=ReadKey(-1))) {
    my $read_volt=$hp->read_voltage_dc(10,0.0001);
    $read_volt=12 if ($read_volt > 12);
    my $rate=($read_volt/10)*$bereich;
    my ($s,$ms)=gettimeofday();
    my ($sec,$min,$hour,$mday,$mon,$year)=localtime($s);
    $year+=1900;$mon++;
    printf LOG "%4d-%02d-%02d %02d:%02d:%.2f\t%f\n",$year,$mon,$mday,$hour,$min,$sec+$ms/1e6,$rate;
    usleep(500000);
}
close LOG;
