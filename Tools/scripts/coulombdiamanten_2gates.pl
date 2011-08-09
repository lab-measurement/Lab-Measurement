#!/usr/bin/perl

# Coulombdiamanten entlang Trace schräg durchs Ladediagramm messen

#$Id$

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Instrument::Yokogawa7651;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $divider_dc    =  1000;
my $ithaco_amp    =  1e-9;    # Ithaco amplification
my $lock_in_sensitivity = 100e-3;

my $v_sd_ac       = 20e-6;

my $gate_1_gpib   =  9;
my $gate_1_type   = 'Yokogawa7651';
my $gate_1_name   = 'Gate hf3';
my $gate_1_start  = -0.254905;
my $gate_1_end    = -0.199938;

my $gate_2_gpib   =  4;
my $gate_2_type   = 'Yokogawa7651';
my $gate_2_name   = 'Gate hf4';
my $gate_2_start  = -0.260901;
my $gate_2_end    = -0.217927;

my $start         = -0.3;   # 0 => ($gate_1_start, $gate_2_start)
my $end           =  1.3;   # 1 => ($gate_1_end, $gate_2_end)
my $steps         =  200;

my $sd_gpib       =  15;
my $sd_type       = 'KnickS252';
my $sd_name       = 'Bias';
my $sd_start      = -1.2;
my $sd_end        =  1.2;
my $sd_step       =  0.01;

my $hp_gpib       =  24;
my $hp_range      =  10;
my $hp_resolution =  0.001;

my $hp2_gpib      =  22;
my $hp2_range     =  10;
my $hp2_resolution=  0.00001;

my $R_Kontakt     =  1773;

my $filename_base = 'diamanten_012-224';

my $sample        = "S5c (81059)";
my $title         = "Tripeldot, gemessen mit QPC links unten";
my $comment       = <<COMMENT;
Coulombdiamanten von 0,1,2 über 1,1,3 und 1,2,3 nach 2,2,4.
Differentielle Leitfähigkeit von 12 nach 10; V_{SD,AC}=$v_sd_ac V bei 33Hz. Ca. 30mK.
Lock-In: Sensitivity $lock_in_sensitivity V, 0.3s, Normal, Bandpaß Q=50, Phase 25.4°.
Ithaco: Amplification $ithaco_amp, Supression 10e-10 off, Rise Time 0.3ms.
G11=-0.385 (Manus1); G15=-0.410 (Manus2); G06=-0.455 (Manus3); Ghf1=-0.125 (Manus04); Ghf2=-0.125 (Manus05);
G01=-0.394 (Yoko01); G03=-0.450 (Yoko02); G13=-0.615 (Knick14); G09=-0.615 (Yoko10); 14 offen; 02,04 auf GND
Fahre aussen V_{SD} (Knick15); innen Gates (Yoko9 und Yoko04);
COMMENT

################################

unless (($sd_end-$sd_start)/$sd_step > 0) {
    warn "Loop on V_SD will not work: start=$sd_start, end=$sd_end, step=$sd_step.\n";
    exit;
}

my $g1type="Lab::Instrument::$gate_1_type";
my $g2type="Lab::Instrument::$gate_2_type";
my $sdtype="Lab::Instrument::$sd_type";

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

my $sd=new $sdtype({
    'GPIB_board'    => 0,
    'GPIB_address'  => $sd_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.1,
    'gp_max_step_per_second' => 5,
    'gp_max_step_per_step'   => 0.1,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);
my $hp2=new Lab::Instrument::HP34401A(0,$hp2_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => $filename_base,
    description     => $comment,

    live_plot       => 'Differential Conductance',
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
            'description'   => "Set voltage on source $gate_1_type$gate_1_gpib connected to $gate_1_name.",
        },
        {
            'unit'          => 'V',
            'label'         => "Voltage $gate_2_name",
            'description'   => "Set voltage on source $gate_2_type$gate_2_gpib connected to $gate_2_name.",
        },
        {
            'unit'          => 'V',
            'label'         => "Voltage $sd_name",
            'description'   => "Set voltage on source $sd_type$sd_gpib connected to $gate_2_name.",
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
            'description'   => "Voltage applied to $gate_1_name.",
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => "V_{$gate_2_name}",
            'description'   => "Voltage applied to $gate_2_name.",
        },
        {
            'unit'          => 'V',
            'expression'    => '$C2/divider',
            'label'         => "V_{$sd_name}",
            'min'           => ($sd_start < $sd_end) ? $sd_start/$divider_dc : $sd_end/$divider_dc,
            'max'           => ($sd_start < $sd_end) ? $sd_end/$divider_dc : $sd_start/$divider_dc,
            'description'   => "Voltage applied to $sd_name.",
        },
        {
            'unit'          => 'A',
            'expression'    => "((\$C3/10)*SENS*AMP)",
            'label'         => 'dI',
            'description'   => 'Differential current',
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(\$A3/V_AC)/G0",
            'label'         => 'Differential conductance',
            'description'   => 'Differential conductance',
        },
        {
            'unit'          => 'A',
            'expression'    => '$C4*AMP',
            'label'         => 'I_{Drain}',
            'description'   => 'Current',
        },
    ],
    plots           => {
        'Differential Conductance'    => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 3,
            'grid'          => 'xtics ytics',
        },
        'Diamanten'=> {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 2,
            'cbaxis'        => 4,
            'grid'          => 'xtics ytics',
        },
        'Stromdiamanten'=> {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 2,
            'cbaxis'        => 5,
            'grid'          => 'xtics ytics',
        },
    },
);

my $sd_stepsign=$sd_step/abs($sd_step);

for (my $bias=$sd_start;$sd_stepsign*$bias<=$sd_stepsign*$sd_end;$bias+=$sd_step) {
    $sd->set_voltage($bias);
    $measurement->start_block("Bias = $bias V");
    print "Started block Bias = $bias V\n";
    my $g1=($gate_1_end-$gate_1_start)*$start+$gate_1_start;
    my $g2=($gate_2_end-$gate_2_start)*$start+$gate_2_start;
    $gate1->set_voltage($g1);
    $gate2->set_voltage($g2);
    sleep(20);
    for my $s (0..$steps-1) {
        my $t=$start+(($end-$start)/$steps)*$s;
        my $g1=($gate_1_end-$gate_1_start)*$t+$gate_1_start;
        my $g2=($gate_2_end-$gate_2_start)*$t+$gate_2_start;
        $gate1->set_voltage($g1);
        $gate2->set_voltage($g2);
        my $meas=$hp->read_voltage_dc($hp_range,$hp_resolution);
        my $meas2=$hp2->read_voltage_dc($hp2_range,$hp2_resolution);
        $measurement->log_line($g1,$g2,$bias,$meas,$meas2);
    }
}

$gate1->set_voltage($gate_1_start);
$gate2->set_voltage($gate_2_start);
$sd->set_voltage(0);

my $meta=$measurement->finish_measurement();
