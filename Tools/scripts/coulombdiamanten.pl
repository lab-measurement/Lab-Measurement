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

my $divider_dc    = 1000;
my $ithaco_amp    = 1e-7;    # Ithaco amplification
my $lock_in_sensitivity = 5e-3;

my $v_sd_ac       = 20e-6;


my $gate_gpib     = 14;
my $gate_type     = 'KnickS252';
my $gate_name     = 'Gate hf3';
my $gate_start    = +0.1;
my $gate_end      = -0.13;
my $gate_step     = -1e-3;

my $bias_gpib     = 15;
my $bias_type     = 'KnickS252';
my $bias_start    = +1.2;
my $bias_end      = -1.2;
my $bias_step     = -2e-2;

my $hp_gpib       = 24;
my $hp_range      = 10;
my $hp_resolution = 0.00001;

my $R_Kontakt     = 1773;

my $filename_base = 'coulombdiamant';

my $sample        = "S5c (81059)";
my $title         = "rechter Quantenpunkt";
my $comment       = <<COMMENT;
Differentielle Leitfähigkeit von 12 nach 10. Ca. 20mK.
Lock-In: Sensitivity $lock_in_sensitivity V, V_{SD,AC}=$v_sd_ac V bei 13Hz, 300ms, Normal, Flat.
Ithaco: Amplification $ithaco_amp, Supression 10e-10, Rise Time 0.3ms.
G01=0 (Yoko04;Kabel5); G11=-0.385 (Yoko02;Kabel4); G06=-0.460 (Yoko10;Kabel1); Ghf2=-0.140 (Yoko01;Kabel11); andere GND
Fahre aussen Bias an 12 (Knick15;Kabel3), innen Ghf3 (Knick14;Kabel6); 
COMMENT

################################

unless (($gate_end-$gate_start)/$gate_step > 0) {
    warn "This will not work: start=$gate_start, end=$gate_end, step=$gate_step.\n";
    exit;
}

unless (($bias_end-$bias_start)/$bias_step > 0) {
    warn "This will not work: start=$bias_start, end=$bias_end, step=$bias_step.\n";
    exit;
}

my $gate_source=new Lab::Instrument::KnickS252({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_gpib,
    'gate_protect'  => 1,
    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});

my $bias_source=new Lab::Instrument::KnickS252({
    'GPIB_address'    => $bias_gpib,
    'gate_protect'    => 1,
    'gp_max_volt_per_second' => 0.010,
    'gp_max_volt_per_step'   => 0.005,
    'gp_max_step_per_second' => 2,
});
    
my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => $filename_base,
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
        {   'unit'          => 'V',
            'label'         => 'Bias voltage',
            'description'   => 'Voltage applied to divider/mixing box, then source contact',
        },
        {
            'unit'          => 'V',
            'label'         => "Voltage $gate_name",
            'description'   => "Set voltage on source $gate_type$gate_gpib connected to $gate_name",
        },
        {
            'unit'          => 'V',
            'label'         => 'Lock-In output',
            'description'   => "Differential current (Lock-In output)",
        }
    ],
    axes            => [
        {   'unit'          => 'mV',
            'expression'    => '($C0/divider)*1000',
            'label'         => 'Bias voltage',
            'description'   => 'Applied to source contact',
            'min'           => ($bias_start < $bias_end) ? ($bias_start/$divider_dc)*1000: ($bias_end/$divider_dc)*1000,
            'max'           => ($bias_start < $bias_end) ? ($bias_end/$divider_dc)*1000 : ($bias_start/$divider_dc)*1000,
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => "Voltage $gate_name",
            'min'           => ($gate_start < $gate_end) ? $gate_start : $gate_end,
            'max'           => ($gate_start < $gate_end) ? $gate_end : $gate_start,
            'description'   => "Voltage applied to $gate_name",
        },
        {
            'unit'          => 'A',
            'expression'    => "((\$C2/10)*SENS*AMP)",
            'label'         => 'Differential current',
            'description'   => 'Differential current',
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(\$A2/V_AC)/G0",
            'label'         => 'Differential conductance',
            'description'   => 'Differential conductance',
        },
       
    ],
    plots           => {
        'Differential Conductance'    => {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 3,
            'grid'          => 'xtics ytics',
        },
        'Diamanten'=> {
            'type'          => 'pm3d',
            'xaxis'         => 1,
            'yaxis'         => 0,
            'cbaxis'        => 3,
            'grid'          => 'xtics ytics',
        },
    },
);

my $gate_stepsign=$gate_step/abs($gate_step);
my $bias_stepsign=$bias_step/abs($bias_step);

for (my $sd=$bias_start;$bias_stepsign*$sd<=$bias_stepsign*$bias_end;$sd+=$bias_step) {
    $measurement->start_block("Bias $sd V");
    $bias_source->set_voltage($sd);
    for (my $volt=$gate_start;$gate_stepsign*$volt<=$gate_stepsign*$gate_end;$volt+=$gate_step) {
        $gate_source->set_voltage($volt);
#        usleep(300000);
        my $meas=$hp->read_voltage_dc($hp_range,$hp_resolution);
        $measurement->log_line($sd,$volt,$meas);
    }
}

my $meta=$measurement->finish_measurement();
