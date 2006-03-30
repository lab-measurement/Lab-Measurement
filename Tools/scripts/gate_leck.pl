#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Lab::Instrument::KnickS252;
use Time::HiRes qw/usleep gettimeofday/;
use File::Basename;

my $start_voltage=0;
my $end_voltage=-0.01;
my $step=-2e-4;

my $knick_gpib=14;
my $hp_gpib=24;

my $title="Gate-Leck-Testmessung";
my $comment=<<COMMENT;
Teste Gates auf Kurzschluesse.
Gate 16.
COMMENT

unless (@ARGV == 1) {
    print "This program tests a gate using a Knick.\n";
    print "Usage: $0 Filename\n";
    exit;
}
my ($file)=@ARGV;
my ($filename,$path,$suffix)=fileparse($file, qr/\.[^.]*/);
unless (($end_voltage-$start_voltage)/$step > 0) {
    warn "This will not work: start=$start_voltage, end=$end_voltage, step=$step\n";
    exit;
}

my $knick=new Lab::Instrument::KnickS252({
    GPIB_address            => $knick_gpib,
    gate_protect            => 0,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

print "Driving source to start voltage...\n";
$knick->sweep_to_voltage($start_voltage);

my $gp1=<<GNUPLOT1;
set ylabel "Measured voltage (V)"
set xlabel "Applied voltage (V)"
set title "$title"
unset key
GNUPLOT1
my $h=0.93;
for (split "\n|(\n\r)",$comment) {
    $h-=0.02;
    $gp1.=qq(set label "$_" at graph 0.02, graph $h\n);
}
my $gp2=<<GNUPLOT2;
plot "$filename$suffix" using 1:2 with lines
GNUPLOT2

my $gpipe=get_pipe() or die;
print $gpipe $gp1;

open LOG,">$path$filename$suffix" or die "cannot open log file";
my $old_fh = select(LOG);
$| = 1;
select($old_fh);

my $fcomment="#$comment";$fcomment=~s/(\n|\n\r)([^\n\r]*)/$1#$2/g;
print LOG "#$title\n$fcomment",'#Measured with $Id$',"\n#Parameters: Knick-GPIB: $knick_gpib; HP-GPIB: $hp_gpib\n";

my $stepsign=$step/abs($step);

for (my $volt=$start_voltage;$stepsign*$volt<=$stepsign*$end_voltage;$volt+=$step) {
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
