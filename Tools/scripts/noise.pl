#!/usr/bin/perl

#$Id: QPC_noise.pl 450 2006-06-30 12:00:57Z schroeer $

use strict;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep gettimeofday tv_interval/;
use Term::ReadKey;
use Lab::Measurement;

################################

my $hp_gpib=24;

my $v_sd=-300e-6;
my $amp=1e-9;    # Ithaco amplification
my $lock_in_sensitivity = 5e-3;

my $v_gate_ac     = 0.66e-3;

my $hp_gpib       = 24;
my $hp_range      = 10;
my $hp_resolution = 0.001;

my $hp2_gpib      = 22;
my $hp2_range     = 10;
my $hp2_resolution= 0.001;

my $sample="S5c (81059)";
my $title="Triple - QPC";
my $comment=<<COMMENT;
Strom und Transconductance von 14 nach 12; Auf Gate hf3 gelockt mit ca. $v_gate_ac V bei 33Hz. V_{SD,DC}=$v_sd V; Ca. 30mK.
Lock-In: Sensitivity $lock_in_sensitivity V, 0.3s, Normal, Bandpaß Q=50.
Ithaco amp $amp, supr 10e-10 off, rise 0.3ms; ca. 25mK.
G11=-0.385 (Manus1); G15=-0.430 (Manus2); G06=-0.455 (Manus3); Ghf1=-0.145 (Manus04); Ghf2=-0.155 (Manus05); 02,04,10 auf GND
G01=-0.380 (Yoko01); Ghf4=-0.180 (Yoko04); Ghf3=-0.300 (Yoko09); G03=-0.450 (Yoko02); G13=-0.584 (Knick14); G09=-0.584 (Yoko10);
COMMENT

my $duration=600;

################################

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);
my $hp2=new Lab::Instrument::HP34401A(0,$hp2_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'rausch2',
    description     => $comment,

    live_plot       => 'Current live',
    live_refresh    => 10,
    
    constants       => [
        {
            'name'          => 'G0',
            'value'         => '7.748091733e-5',
        },
        {
            'name'          => 'V_SD',
            'value'         => $v_sd,
        },
        {
            'name'          => 'AMP',
            'value'         => $amp,
        },
        {
            'name'          => 'V_GATE_AC',
            'value'         => $v_gate_ac,
        },
        {
            'name'          => 'SENS',
            'value'         => $lock_in_sensitivity,
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
            'label'         => "Lock-In output",
            'description'   => 'Differential current (Lock-In output)',
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
            'unit'          => 'A',
            'expression'    => "((\$C1/10)*SENS*AMP)",
            'label'         => 'dI',
            'description'   => 'Differential current',
            'min'           => -4e-12,
            'max'           => 4e-12,
        },
        {
            'unit'          => 'A',
            'expression'    => "abs(\$C2)*AMP",
            'label'         => 'I_{QPC}',
            'min'           => '2.5e-9',
            'max'           => '3.5e-9',
            'description'   => 'QPC current',
        },
        {
            'unit'          => '%',
            'expression'    => "(100*((\$C1/10)*SENS*AMP)/(\$C2*AMP))",
            'label'         => 'dI_{QPC}/I_{QPC}',
            'description'   => 'Relative QPC current change',
            'min'           => -0.2,
            'max'           => 0.2,
        },
    ],
    plots           => {
        'Transconductance live'=> {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 2,
            'grid'          => 'ytics',
        },
        'Transconductance'=> {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 2,
            'grid'          => 'ytics',
        },
        'Current'=> {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 3,
            'grid'          => 'ytics',
        },
        'Current live'=> {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 3,
            'grid'          => 'ytics',
        },
        'Relative current'=> {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 4,
            'grid'          => 'ytics',
        },
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
    my $read_volt=$hp->read_voltage_dc($hp_range,$hp_resolution);
    my $read_volt2=$hp2->read_voltage_dc($hp2_range,$hp2_resolution);
    $elapsed=tv_interval ( $start_int, [gettimeofday()]);
    $measurement->log_line($elapsed,$read_volt,$read_volt2);
    if ($key eq "m") {
        #print "Marking position $timestamp (not really yet)\n";
        #my $mark=qq(set arrow from "$timestamp", graph 0 to "$timestamp", graph 1 nohead lt 2 lw 2\n);
    }
    $key=ReadKey(-1);
}
ReadMode('normal');

my $meta=$measurement->finish_measurement();

