#!/usr/bin/perl

# QPC-Messung mit Lock-In

#$Id: ladediagramm_qpc.pl 516 2006-09-28 14:59:28Z schroeer $

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Instrument::Yokogawa7651;
use Lab::Measurement;
use Time::HiRes qw/usleep/;

################################

my $divider_dc    = 1000;
my $ithaco_amp    = 1e-9;    # Ithaco amplification
my $lock_in_sensitivity = 5e-3;

my $v_gate_ac     = 0.66e-3;
my $v_sd_dc       = -300e-3/$divider_dc;

my $gate_1_gpib   = 1;
my $gate_1_type   = 'Yokogawa7651';
my $gate_1_name   = 'Gate 01';
my $gate_1_start  = -0.540;
my $gate_1_end    = -0.390;
my $gate_1_step   = +1e-3;

my $gate_2_gpib   = 9;
my $gate_2_type   = 'Yokogawa7651';
my $gate_2_name   = 'Gate hf3';
my $gate_2_start  = -0.420;
my $gate_2_end    = -0.250;
my $gate_2_step   = +1e-3;

my $hp_gpib       = 24;
my $hp_range      = 10;
my $hp_resolution = 0.001;

my $hp2_gpib      = 22;
my $hp2_range     = 10;
my $hp2_resolution= 0.00001;

my $R_Kontakt     = 1773;

my $filename_base = 'doppeldot_rechts';

my $sample        = "S5c (81059)";
my $title         = "rechter Doppeldot, gemessen mit QPC links unten";
my $comment       = <<COMMENT;
Transconductance von 14 nach 12; Auf Gate hf3 gelockt mit ca. $v_gate_ac V bei 33Hz. V_{SD,DC}=$v_sd_dc V; Ca. 30mK.
Lock-In: Sensitivity $lock_in_sensitivity V, 0.3s, Normal, Bandpaß Q=50, Phase 0°
Ithaco: Amplification $ithaco_amp, Supression 10e-10 off, Rise Time 0.3ms.
G11=-0.385 (Manus1); G15=-0.300 (Manus2); G06=-0.460 (Manus3); Ghf1=0 (Manus04); Ghf2=-0.130 (Manus05);
Ghf4=0 (Yoko04); G03=-0.450 (Yoko02); G13=-0.930 (Knick14); G09=-0.630 (Yoko10); 10,02,04 auf GND
Fahre aussen G01 (Yoko01); innen Ghf3 (Yoko09);
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
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);
my $hp2=new Lab::Instrument::HP34401A(0,$hp2_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => $filename_base,
    description     => $comment,

    live_plot       => 'Transconductance',
    live_refresh    => 120,
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
            'label'         => "Lock-In output",
            'description'   => 'Differential current (Lock-In output)',
        },
        {
            'unit'          => 'V',
            'label'         => 'Amplifier output',
            'description'   => "Voltage output by current amplifier set to $ithaco_amp.",
        }
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => "V_{$gate_1_name}",
            'min'           => ($gate_1_start < $gate_1_end) ? $gate_1_start : $gate_1_end,
            'max'           => ($gate_1_start < $gate_1_end) ? $gate_1_end : $gate_1_start,
            'description'   => "Voltage applied to $gate_1_name.",
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => "V_{$gate_2_name}",
            'min'           => ($gate_2_start < $gate_2_end) ? $gate_2_start : $gate_2_end,
            'max'           => ($gate_2_start < $gate_2_end) ? $gate_2_end : $gate_2_start,
            'description'   => "Voltage applied to $gate_2_name.",
        },
        {
            'unit'          => 'A',
            'expression'    => "((\$C2/10)*SENS*AMP)",
            'label'         => 'dI',
            'description'   => 'Differential current',
            'min'           => -6e-12,
            'max'           => 6e-12,
        },
        {
            'unit'          => 'A',
            'expression'    => "abs(\$C3)*AMP",
            'label'         => 'I_{QPC}',
            'description'   => 'QPC current',
        },
        {
            'unit'          => '%',
            'expression'    => "(100*((\$C2/10)*SENS*AMP)/(\$C3*AMP))",
            'label'         => 'dI_{QPC}/I_{QPC}',
            'description'   => 'Relative QPC current change',
            'min'           => -0.5,
            'max'           => 0.5,
        },
    ],
    plots           => {
        'Transconductance'    => {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 2,
            'grid'          => 'xtics ytics',
        },
        'Stromtraces'    => {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 3,
            'grid'          => 'xtics ytics',
        },
        'Ladediagramm'=> {
            'type'          => 'pm3d',
            'xaxis'         => 1,
            'yaxis'         => 0,
            'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
        'Ladediagramm-Strom'=> {
            'type'          => 'pm3d',
            'xaxis'         => 1,
            'yaxis'         => 0,
            'cbaxis'        => 3,
            'grid'          => 'xtics ytics',
        },
        'Ladediagramm-dI-I'=> {
            'type'          => 'pm3d',
            'xaxis'         => 1,
            'yaxis'         => 0,
            'cbaxis'        => 4,
            'grid'          => 'xtics ytics',
        },
    },
);

my $gate_1_stepsign=$gate_1_step/abs($gate_1_step);
my $gate_2_stepsign=$gate_2_step/abs($gate_2_step);

for (my $g1=$gate_1_start;$gate_1_stepsign*$g1<=$gate_1_stepsign*$gate_1_end;$g1+=$gate_1_step) {
    $measurement->start_block("$gate_1_name = $g1 V");
    $gate1->set_voltage($g1);
    print "Started block $gate_1_name = $g1 V\n";
    sleep(20);
    for (my $g2=$gate_2_start;$gate_2_stepsign*$g2<=$gate_2_stepsign*$gate_2_end;$g2+=$gate_2_step) {
        $gate2->set_voltage($g2);
        my $meas=$hp->read_voltage_dc($hp_range,$hp_resolution);
        my $meas2=$hp2->read_voltage_dc($hp2_range,$hp2_resolution);
        $measurement->log_line($g1,$g2,$meas,$meas2);
    }
}

$gate1->set_voltage($gate_1_start);
$gate2->set_voltage($gate_2_start);

my $meta=$measurement->finish_measurement();
