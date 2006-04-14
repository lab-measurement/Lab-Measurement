#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Lab::Instrument::KnickS252;
use Time::HiRes qw/usleep gettimeofday/;
use File::Basename;

###################################

my $start_voltage=-0.38;
my $end_voltage=0;
my $step=5e-4;

my $knick_gpib=14;
my $hp_gpib=24;

my $v_sd=0.78/1563;
my $ithaco_amp=1e-7;

my $U_Kontakt=1.821;    #die Spannung, die Stromverstärker bei V_Gate=0 anzeigt

my $title="S5a-III (81059) QPC rechts oben";
my $comment=<<COMMENT;
Abgekuehlt mit +150mV
Strom von 5 nach 13, Ithaco amp $ithaco_amp, supr 10^{-10}, rise 0.3ms
Gates 3 und 6
Hi und Lo der Kabel aufgetrennt
Tuer zu, Deckel zu, Licht aus
Nur Rotary, ca. 85mK
COMMENT

###################################

unless (@ARGV == 1) {
    print "This program pinches-off a QPC using a Knick.\n";
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
    gate_protect            => 1,
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

print "Driving source to start voltage...\n";
$knick->sweep_to_voltage($start_voltage);

my ($sec,$min,$hour,$mday,$mon,$year)=localtime(time);
$year+=1900;$mon++;
my $timestamp=sprintf "%4d-%02d-%02d %02d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec;
my $fn=$filename;$fn=~s/_/\\\\_/g;
my $left=($start_voltage<$end_voltage) ? $start_voltage : $end_voltage;
my $right=($start_voltage<$end_voltage) ? $end_voltage : $start_voltage;
my $gp1=<<GNUPLOT1;
set xlabel "Gate voltage (V)"
set xrange [$left:$right]
set title "$title"
set grid ytics
unset key
vsd=$v_sd
amp=$ithaco_amp
g0=7.748091733e-5
Ukontakt=$U_Kontakt
set label "$fn; started at $timestamp." at graph 0.02, graph 0.95
set label "V_{SD}=%1.2e V",vsd at graph 0.02, graph 0.91
GNUPLOT1
my $h=0.91;
for (split "\n",$comment) {
    $h-=0.04;
    $gp1.=qq(set label "$_" at graph 0.02, graph $h\n);
}
my $gp2=<<GNUPLOT2;
set ylabel "Total Conductance (2e^2/h)"
plot "$filename$suffix" using 1:(abs(\$2) * (amp/(vsd*g0)) ) with lines
GNUPLOT2
my $gp2qpc=<<GNUPLOT2QPC;
set ylabel "QPC Conductance (2e^2/h)"
set yrange [-0.1:5]
plot "$filename$suffix" using 1:( (1/(1/abs(\$2)-1/Ukontakt)) * (amp/(vsd*g0)) ) with lines
GNUPLOT2QPC

my $gpipe=get_pipe() or die;
print $gpipe $gp1;

open LOG,">$path$filename$suffix" or die "cannot open log file";
my $old_fh = select(LOG);
$| = 1;
select($old_fh);

my $fcomment="#$comment";$fcomment=~s/(\n|\n\r)([^\n\r]*)/$1#$2/g;
print LOG "#$title\n$fcomment",'#Measured with $Id$',"\n#Parameters: Knick-GPIB: $knick_gpib; HP-GPIB: $hp_gpib; Amplification: $ithaco_amp\n";

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
print GP <<GNUPLOT3,$gp1,$gp2qpc;
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
