#!/usr/bin/perl

# Transportmessung mit Lock-In

#$Id$

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Instrument::Yokogawa7651;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $amp=1e-7;    # Ithaco amplification
my $divider=1000;
my $v_sd_ac=20e-6;
my $lock_in_sensitivity=10e-3;

my $v_sd_dc=50e-3/1000;

my $gate_1_gpib=1;
my $gate_1_type='yoko';
my $gate_1_name='Gate 15';

my $gate_1_start =-0.1;
my $gate_1_end   =-0.4;
my $gate_1_step  =-10e-3;


my $gate_2_gpib=9;
my $gate_2_type='yoko';
my $gate_2_name='Gate 01';

my $gate_2_start =0;
my $gate_2_end   =-0.005;
my $gate_2_step  =-1e-3;

my $hp_gpib=24;

my $R_Kontakt=1773;

my $sample="S5c (81059)";
my $title="Oberer und linker Quantenpunkt";
my $comment=<<COMMENT;
Differentielle Leitfähigkeit von 12 nach 10. Ca. 20mK.
Lock-In: Sensitivity $lock_in_sensitivity V, V_{SD,AC}=$v_sd_ac V bei 13Hz, 300ms, Normal, Flat.
Ithaco: Amplification $amp, Supression 10e-10, Rise Time 0.3ms.
G11=-0.425 (yoko02); Ghf1=0 (Yoko10); Fahre G01 (yoko04); Ghf2=0 (knick14).
COMMENT

################################

unless (($gate_1_end-$gate_1_start)/$gate_1_step > 0) {
    warn "This will not work: start=$gate_1_start, end=$gate_1_end, step=$gate_1_step.\n";
    exit;
}

unless (($gate_2_end-$gate_2_start)/$gate_2_step > 0) {
    warn "This will not work: start=$gate_2_start, end=$gate_2_end, step=$gate_2_step.\n";
    exit;
}

my $gate1;
if ($gate_1_type eq 'knick') {
    $gate1=new Lab::Instrument::KnickS252({
        'GPIB_board'    => 0,
        'GPIB_address'  => $gate_1_gpib,
        'gate_protect'  => 1,

        'gp_max_volt_per_second' => 0.002,
        'gp_max_step_per_second' => 3,
        'gp_max_step_per_step'   => 0.001,
    })
} else {
    $gate1=new Lab::Instrument::Yokogawa7651({
        'GPIB_board'    => 0,
        'GPIB_address'  => $gate_1_gpib,
        'gate_protect'  => 1,

        'gp_max_volt_per_second' => 0.002,
        'gp_max_step_per_second' => 3,
        'gp_max_step_per_step'   => 0.001,
    })
};

    
my $gate2;
if ($gate_2_type eq 'knick') {
    $gate2=new Lab::Instrument::KnickS252({
        'GPIB_board'    => 0,
        'GPIB_address'  => $gate_2_gpib,
        'gate_protect'  => 1,

        'gp_max_volt_per_second' => 0.002,
        'gp_max_step_per_second' => 3,
        'gp_max_step_per_step'   => 0.001,
    })
} else {
    $gate2=new Lab::Instrument::Yokogawa7651({
        'GPIB_board'    => 0,
        'GPIB_address'  => $gate_2_gpib,
        'gate_protect'  => 1,

        'gp_max_volt_per_second' => 0.002,
        'gp_max_step_per_second' => 3,
        'gp_max_step_per_step'   => 0.001,
    })
};

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'ladediagramm',
    description     => $comment,

    live_plot       => 'Differential Conductance',
    live_refresh    => 20,
    
    constants       => [
        {
            'name'          => 'G0',
            'value'         => '7.748091733e-5',
        },
        {
            'name'          => 'RKontakt',
            'value'         => $R_Kontakt,
        },
        {
            'name'          => 'AMP',
            'value'         => $amp,
        },
        {
            'name'          => 'divider',
            'value'         => $divider,
        },
        {
            'name'          => 'V_AC',
            'value'         => $v_sd_ac,
        },
        {
            'name'          => 'SENS',
            'value'         => $lock_in_sensitivity,
        },
    ],
    columns         => [
        {
            'unit'          => 'V',
            'label'         => "Voltage $gate_1_name",
            'description'   => "Applied to $gate_1_name.",
        },
        {
            'unit'          => 'V',
            'label'         => "Voltage $gate_2_name",
            'description'   => "Applied to $gate_2_name.",
        },
        {
            'unit'          => 'V',
            'label'         => 'Lock-In output',
            'description'   => "Lock-In output",
        }
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => "Voltage $gate_1_name",
            'min'           => ($gate_1_start < $gate_1_end) ? $gate_1_start : $gate_1_end,
            'max'           => ($gate_1_start < $gate_1_end) ? $gate_1_end : $gate_1_start,
            'description'   => "Applied $gate_1_name.",
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => "Voltage $gate_2_name",
            'min'           => ($gate_2_start < $gate_2_end) ? $gate_2_start : $gate_2_end,
            'max'           => ($gate_2_start < $gate_2_end) ? $gate_2_end : $gate_2_start,
            'description'   => "Applied $gate_1_name.",
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(((\$C2/10)*SENS*AMP)/V_AC)/G0",
            'label'         => 'Differential Conductance',
            'description'   => 'Differential Conductance',
        },
       
    ],
    plots           => {
        'Differential Conductance'    => {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 2,
            'grid'          => 'xtics ytics',
        },
        'Ladediagramm'=> {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
    },
);

my $gate_1_stepsign=$gate_1_step/abs($gate_1_step);
my $gate_2_stepsign=$gate_2_step/abs($gate_2_step);

for (my $g1=$gate_1_start;$gate_1_stepsign*$g1<=$gate_1_stepsign*$gate_1_end;$g1+=$gate_1_step) {
    $measurement->start_block("$gate_1_name = $g1 V");
    $gate1->set_voltage($g1);
    for (my $g2=$gate_2_start;$gate_2_stepsign*$g2<=$gate_2_stepsign*$gate_2_end;$g2+=$gate_2_step) {
        $gate2->set_voltage($g2);
        usleep(300000);
        my $meas=$hp->read_voltage_dc(10,0.0001);
        $measurement->log_line($g1,$g2,$meas);
    }
}

my $meta=$measurement->finish_measurement();
