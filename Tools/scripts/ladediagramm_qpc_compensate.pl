#!/usr/bin/perl

# Ladediagramm mit QPC messen
# QPC mit Lock-In auf ein Gate gelockt.
# Ein QPC-Gatter zur Kompensation variieren.

#$Id: ladediagramm.pl 438 2006-05-29 10:41:09Z schroeer $

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Instrument::Yokogawa7651;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $divider_dc    = 1000;
my $ithaco_amp    = 1e-9;    # Ithaco amplification
my $lock_in_sensitivity = 50e-3;

my $v_gate_ac     = 1e-3;
my $v_sd_dc       = 500e-3/$divider_dc;

my $gate_1_gpib   = 14;
my $gate_1_type   = 'KnickS252';
my $gate_1_name   = 'Gate hf4';
my $gate_1_start  = -0.100;
my $gate_1_end    = -0.300;
my $gate_1_step   = -2e-3;

my $gate_2_gpib   = 04;
my $gate_2_type   = 'Yokogawa7651';
my $gate_2_name   = 'Gate 01';
my $gate_2_start  = -0.340;
my $gate_2_end    = -0.460;
my $gate_2_step   = -1.5e-3;

# Dies ist das Gate zur Kompensation
my $gate_3_gpib   = 9;
my $gate_3_type   = 'Yokogawa7651';
my $gate_3_name   = 'Gate 13 (QPC)';
my $gate_3_start  = -0.641;
my $gate_3_end    = -0.607;
my $gate_3_step   = ($gate_3_end-$gate_3_start)/
                    (($gate_1_end-$gate_1_start)/$gate_1_step);

my $hp_gpib       = 24;
my $hp_range      = 10;
my $hp_resolution = 0.00001;

my $R_Kontakt     = 1773;

my $filename_base = 'qpc_ladediagramm';

my $sample        = "S5c (81059)";
my $title         = "Oberer und linker DQD, gemessen mit QPC lu (mit Kompensation)";
my $comment       = <<COMMENT;
Transconductance von 14 nach 12; Auf Gate 01 gelockt mit ca. $v_gate_ac V bei 13Hz. V_{SD,DC}=$v_sd_dc V; Ca. 20mK.
Lock-In: Sensitivity $lock_in_sensitivity V, 0.3s, Normal, Bandpass Q=50.
Ithaco: Amplification $ithaco_amp, Supression 10e-10, Rise Time 0.3ms.
G11=-0.385 (Yoko02;Kabel4); G15=-0.400 (Yoko10;Kabel1);
Ghf1=Ghf2=-0.130 (Yoko01;Kabel11); G13=-0.641 ... -0.607 (Yoko09;Kabel8); andere GND
Fahre aussen Ghf4 (Knick14;Kabel6); innen G01 (Yoko04;Kabel5); 
COMMENT

################################

unless (($gate_1_end-$gate_1_start)/$gate_1_step > 0) {
    warn "Loop on gate 1 will not work: start=$gate_1_start, end=$gate_1_end, step=$gate_1_step.\n";
    exit;
}

unless (($gate_2_end-$gate_2_start)/$gate_2_step > 0) {
    warn "Loop on gate 2 will not work: start=$gate_2_start, end=$gate_2_end, step=$gate_2_step.\n";
    exit;
}

my $g1type="Lab::Instrument::$gate_1_type";
my $g2type="Lab::Instrument::$gate_2_type";
my $g3type="Lab::Instrument::$gate_3_type";

my $gate1=new $g1type({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_1_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});
    
my $gate2=new $g2type({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_2_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 4,
    'gp_max_step_per_step'   => 0.002,
});

my $gate3=new $g3type({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_3_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => $filename_base,
    description     => $comment,

    live_plot       => 'Transconductance',
    live_refresh    => 60,
#    live_latest     => 8,
    
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
            'value'         => $ithaco_amp,
        },
        {
            'name'          => 'divider',
            'value'         => $divider_dc,
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
            'unit'          => 'V',
            'label'         => "Voltage $gate_1_name",
            'description'   => "Set voltage on source $gate_1_type$gate_1_gpib connected to $gate_1_name.",
        },
        {
            'unit'          => 'V',
            'label'         => "Voltage $gate_2_name",
            'description'   => "Set voltage on source $gate_2_type$gate_2_gpib connected to $gate_2_name.",
        },
        {
            'unit'          => 'V',
            'label'         => "Voltage $gate_3_name",
            'description'   => "Set voltage on source $gate_3_type$gate_3_gpib connected to $gate_3_name.",
        },
        {
            'unit'          => 'V',
            'label'         => "Lock-In output",
            'description'   => 'Differential current (Lock-In output)',
        }
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => "Voltage $gate_1_name",
            'min'           => ($gate_1_start < $gate_1_end) ? $gate_1_start : $gate_1_end,
            'max'           => ($gate_1_start < $gate_1_end) ? $gate_1_end : $gate_1_start,
            'description'   => "Voltage applied to $gate_1_name.",
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => "Voltage $gate_2_name",
            'min'           => ($gate_2_start < $gate_2_end) ? $gate_2_start : $gate_2_end,
            'max'           => ($gate_2_start < $gate_2_end) ? $gate_2_end : $gate_2_start,
            'description'   => "Voltage applied to $gate_2_name.",
        },
        {
            'unit'          => 'a.u.',
            'expression'    => "((\$C3/10)*SENS*AMP)",
            'label'         => 'Transconductance',
            'description'   => 'Transconductance',
        },
    ],
    plots           => {
        'Transconductance'    => {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 2,
            'grid'          => 'xtics ytics',
        },
        'Ladediagramm'=> {
            'type'          => 'pm3d',
            'xaxis'         => 1,
            'yaxis'         => 0,
            'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
    },
);

my $gate_1_stepsign=$gate_1_step/abs($gate_1_step);
my $gate_2_stepsign=$gate_2_step/abs($gate_2_step);

my $g3=$gate_3_start;
for (my $g1=$gate_1_start;$gate_1_stepsign*$g1<=$gate_1_stepsign*$gate_1_end;$g1+=$gate_1_step) {
    $measurement->start_block("$gate_1_name = $g1 V; $gate_3_name = $g3 V");
    $gate1->set_voltage($g1);
    $gate3->set_voltage($g3);
    for (my $g2=$gate_2_start;$gate_2_stepsign*$g2<=$gate_2_stepsign*$gate_2_end;$g2+=$gate_2_step) {
        $gate2->set_voltage($g2);
       # usleep(200000);
        my $meas=$hp->read_voltage_dc($hp_range,$hp_resolution);
        $measurement->log_line($g1,$g2,$g3,$meas);
    }
    $g3+=$gate_3_step;
}

my $meta=$measurement->finish_measurement();
