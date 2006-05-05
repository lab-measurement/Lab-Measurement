#!/usr/bin/perl

#$Id$

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep gettimeofday tv_interval/;
use Term::ReadKey;
use Lab::Measurement;

################################

my $hp_gpib=24;

my $v_gate=-0.1608;
my $v_sd=780e-3/1563;
my $amp=1e-7;    # Ithaco amplification

my $U_Kontakt=1.68;

my $sample="S8c (mbe5-62)";
my $title="QPC links oben";
my $comment=<<COMMENT;
Strom von 1 nach 13, Ithaco amp $amp, supr 10e-10, rise 0.3ms, V_{SD}=$v_sd V.
Gates 2 und 16; V_{Gates}=$v_gate V.
Hi und Lo der Kabel aufgetrennt; Tuer zu, Deckel zu, Licht aus; nur Rotary, ca. 82mK.
COMMENT

my $duration=7200;

################################

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'qpc_noise',
    description     => $comment,

    live_plot       => 'QPC conductance live',
    live_refresh    => 30,
    
    constants       => [
        {
            'name'          => 'G0',
            'value'         => '7.748091733e-5',
        },
        {
            'name'          => 'UKontakt',
            'value'         => $U_Kontakt,
        },
        {
            'name'          => 'V_SD',
            'value'         => $v_sd,
        },
        {
            'name'          => 'AMP',
            'value'         => $amp,
        },
    ],
    columns         => [
        {
            'unit'          => 's',
            'label'         => 'Time',
            'description'   => 'Time elapsed since start of measurement',
        },
        {
            'unit'          => 'V',
            'label'         => 'Amplifier output',
            'description'   => "Voltage output by current amplifier set to $amp.",
        }
    ],
    axes            => [
        {
            'unit'          => 's',
            'expression'    => '$C0',
            'label'         => 'Time',
            'description'   => 'Time elapsed since start of measurement',
        },
        {
            'unit'          => 's',
            'expression'    => '$C0',
            'label'         => 'Time',
            'description'   => 'Time elapsed since start of measurement',
            'min'           => 0,
            'max'           => $duration
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(1/(1/abs(\$C1)-1/UKontakt)) * (AMP/(V_SD*G0))",
            'label'         => "QPC conductance",
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(1/(1/abs(\$C1)-1/UKontakt)) * (AMP/(V_SD*G0))",
            'label'         => "QPC conductance",
            'min'           => 0.96,
            'max'           => 1.04
        },
        
    ],
    plots           => {
        'QPC conductance live'=> {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 2,
            'grid'          => 'ytics',
        },
        'QPC conductance'=> {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 3,
            'grid'          => 'ytics',
        }
    },
);

$measurement->start_block();

print "Measurement running\nPress 's' to stop; 'm' to mark position.\n";

my $key;

ReadMode('cbreak');
my $count=10;
my $elapsed=0;
my $start_int=[gettimeofday];
while (($key ne "s") && ($elapsed < $duration)) {
    my $read_volt=$hp->read_voltage_dc(1,0.00001);
    $elapsed=tv_interval ( $start_int, [gettimeofday()]);
    $measurement->log_line($elapsed,$read_volt);
    if ($key eq "m") {
        #print "Marking position $timestamp (not really yet)\n";
        #my $mark=qq(set arrow from "$timestamp", graph 0 to "$timestamp", graph 1 nohead lt 2 lw 2\n);
    }
    $key=ReadKey(-1);
}
ReadMode('normal');

my $meta=$measurement->finish_measurement();

