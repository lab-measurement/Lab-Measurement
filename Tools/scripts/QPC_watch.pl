#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep gettimeofday tv_interval/;
use Term::ReadKey;
use File::Basename;

##################################

my $hp_gpib=24;

my $v_sd=0.78/1563;
my $v_gate=-0.6594;
my $ithaco_amp=1e-7;

my $U_Kontakt=1.709;    #die Spannung, die Stromverstärker bei V_Gate=0 anzeigt

my $title="S5a-II (81059) QPC links oben";
my $comment=<<COMMENT;
Beobachte Strom von 13 nach 1; Ithaco Amp $ithaco_amp, Sup 10^{-10}, Rise 0.3ms.
Hi und Lo der Kabel aufgetrennt, Tuer zu, Deckel zu, Licht aus.
Nur Rot-Pumpe; ca. 80mK.
COMMENT

my $duration=36000;

##################################

unless (@ARGV == 1) {
    print "This program measures a QPC signal over time using a Knick.\n";
    print "Usage: $0 Filename\n";
    exit;
}
my ($file)=@ARGV;

my ($filename,$path,$suffix)=fileparse($file, qr/\.[^.]*/);

my $hp=new Lab::Instrument::HP34401A({GPIB_board=>0,GPIB_address=>$hp_gpib});

my ($sec,$min,$hour,$mday,$mon,$year)=localtime(time);
$year+=1900;$mon++;
my $timestamp=sprintf "%4d-%02d-%02d %02d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec;
my $fn=$filename;$fn=~s/_/\\\\_/g;

my $gp1=<<GNUPLOT1;
Ukontakt=$U_Kontakt
vsd=$v_sd
amp=$ithaco_amp
g0=7.748091733e-5
set title "$title"
set label "$fn; started at $timestamp." at graph 0.02, graph 0.95
set label "V_{SD}=%1.2e V",vsd at graph 0.02, graph 0.91
set xlabel "Seconds"
set ylabel "Current (A)"
#set yrange [0.46:0.54]
set grid ytics
unset key
GNUPLOT1
my $h=0.91;
for (split "\n",$comment) {
    $h-=0.04;
    $gp1.=qq(set label "$_" at graph 0.02, graph $h\n);
}
my $gp2=<<GNUPLOT2;
plot "$filename$suffix" using 1:(\$2*amp) with lines
GNUPLOT2

my $gpipe=get_pipe() or die;
print $gpipe $gp1;

open LOG,">$path$filename$suffix" or die "cannot open log file";
my $old_fh = select(LOG);
$| = 1;
select($old_fh);

my $fcomment="#$comment";$fcomment=~s/(\n|\n\r)([^\n\r]*)/$1#$2/g;
print LOG "#$title\n$fcomment",'#Measured with $Id: QPC_Noise.pl 313 2006-04-05 17:18:56Z schroeer $',"\n#Parameters: HP-GPIB: $hp_gpib; Amplification: $ithaco_amp; V_SD=$v_sd\n";

print "Measurement running\nPress 's' to stop; 'm' to mark position.\n";

my $key;

ReadMode('cbreak');
my $count=1;
my $elapsed=0;
my $start_int=[gettimeofday];
while (($key ne "s") && ($elapsed < $duration)) {
#while ($key ne "s") {
    my $read_volt=$hp->read_voltage_dc(10,0.0001);
    my ($s,$ms)=gettimeofday();
    my ($sec,$min,$hour,$mday,$mon,$year)=localtime($s);
    $year+=1900;$mon++;
    $timestamp=sprintf "%4d-%02d-%02d %02d:%02d:%.2f",$year,$mon,$mday,$hour,$min,$sec+$ms/1e6;
    $elapsed=tv_interval ( $start_int, [$s, $ms]);
    print LOG "$elapsed\t$timestamp\t$read_volt\n";
    if ($key eq "m") {
        print "Marking position $timestamp\n";
        my $mark=qq(set arrow from "$timestamp", graph 0 to "$timestamp", graph 1 nohead lt 2 lw 2\n);
        print $gpipe $mark;
        $gp1.=$mark;
    }
    if ($count-- == 0) {
        print $gpipe $gp2;
        $count=1;
    }
    sleep(60);
    $key=ReadKey(-1);
}
ReadMode('normal');
close LOG;
close $gpipe;

open GP,">$path$filename.gnuplot" or die "cannot open gnuplot file";
print GP $gp1,<<GNUPLOT3,$gp2;
set xrange [0:$duration]
set term post col enh
set out "$filename.ps"
GNUPLOT3

system("gnuplot $path$filename.gnuplot");
#system("gv $path$filename.ps &");

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
