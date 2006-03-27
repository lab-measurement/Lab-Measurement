#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep gettimeofday/;
use Term::ReadKey;

unless (@ARGV == 4) {
    print "Usage: $0 GPIB-address Sensitivity Filename Comment\n";
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
GNUPLOT1
my $gp2=<<GNUPLOT2;
plot "$filename" using 1:3 with lines
GNUPLOT2

my $gpipe=get_pipe() or die;
print $gpipe $gp1;

open LOG,">$filename" or die "cannot open log file";
my $old_fh = select(LOG);
$| = 1;
select($old_fh);

print LOG "#$comment\n";

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
    my $timestamp=sprintf "%4d-%02d-%02d %02d:%02d:%.2f",$year,$mon,$mday,$hour,$min,$sec+$ms/1e6;
    print LOG "$timestamp\t$rate\n";
    if ($key eq "m") {
        print "Marking position $timestamp\n";
        my $mark=qq(set arrow from "$timestamp", graph 0 to "$timestamp", graph 1 nohead lt 2 lw 2\n);
        print $gpipe $mark;
        $gp1.=$mark;
    }
    print $gpipe $gp2;
    usleep(500000);
    $key=ReadKey(-1);
}
ReadMode('normal');
close LOG;
close $gpipe;

open GP,">$filename.gnuplot" or die "cannot open gnuplot file";
print GP <<GNUPLOT3,$gp1,$gp2;
set term post col enh
set out "$filename.ps"
GNUPLOT3

system("gnuplot $filename.gnuplot");
system("gv $filename.ps &");

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
