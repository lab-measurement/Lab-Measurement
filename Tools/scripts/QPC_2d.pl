#!/usr/bin/perl

#$Id$

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $start_voltage=-1;
my $end_voltage=-1.75;
my $step=-1e-3;

my $start_sd=3.9075;
my $end_sd=-3.9075;
my $step_sd=-0.1563;

my $gate_knick_gpib=14;
my $sd_knick_gpib=15;
my $hp_gpib=24;

my $amp=1e-7;    # Ithaco amplification
my $divider=1563;
my $R_Kontakt=1089;

my $sample="S6c (D040123B)";
my $title="QPC rechts unten";
my $comment=<<COMMENT;
Strom von 8 nach 1, Ithaco amp $amp, supr 10e-10, rise 0.3ms.
Gates 7 und 9.
Hi und Lo der Kabel aufgetrennt; Tuer zu, Deckel zu, Licht aus; nur Rotary, ca. 85mK.
COMMENT

################################

unless (($end_voltage-$start_voltage)/$step > 0) {
    warn "This will not work: start=$start_voltage, end=$end_voltage, step=$step.\n";
    exit;
}

unless (($end_sd-$start_sd)/$step_sd > 0) {
    warn "This will not work: start=$start_sd, end=$end_sd, step=$step_sd.\n";
    exit;
}

my $gate_knick=new Lab::Instrument::KnickS252({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_knick_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
});
my $sd_knick=new Lab::Instrument::KnickS252({
    'GPIB_address'    => $sd_knick_gpib,
    'gate_protect'    => 1,
    'gp_max_volt_per_second' => 0.02,
    'gp_max_volt_per_step'   => 0.01,
});
    
my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'qpc_2d',
    description     => $comment,

    live_plot       => 'QPC current',
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
    ],
    columns         => [
        {   'unit'          => 'V',
            'label'         => 'Bias voltage',
            'description'   => 'Applied to divider, then source contact',
        },
        {
            'unit'          => 'V',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gates via low path filter.',
        },
        {
            'unit'          => 'V',
            'label'         => 'Amplifier output',
            'description'   => "Voltage output by current amplifier set to $amp.",
        }
    ],
    axes            => [
        {   'unit'          => 'V',
            'expression'    => '$C0/divider',
            'label'         => 'Bias voltage',
            'description'   => 'Applied to source contact',
            'min'           => ($start_sd < $end_sd) ? $start_sd/$divider: $end_sd/$divider,
            'max'           => ($start_sd < $end_sd) ? $end_sd/$divider : $start_sd/$divider,
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => 'Gate voltage',
            'min'           => ($start_voltage < $end_voltage) ? $start_voltage : $end_voltage,
            'max'           => ($start_voltage < $end_voltage) ? $end_voltage : $start_voltage,
            'description'   => 'Applied to gates via low path filter.',
        },
        {
            'unit'          => 'A',
            'expression'    => "abs(\$C2)*AMP",
            'label'         => 'QPC current',
            'description'   => 'Current through QPC',
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(\$A2/V_SD)/G0",
            'label'         => "Total conductance",
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(1/((\$A0)/(-\$C2*AMP)-RKontakt))/G0",
            'label'         => "QPC conductance",
            'min'           => -0.1,
            'max'           => 7
        },
        
    ],
    plots           => {
        'QPC current'    => {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 2,
            'grid'          => 'xtics ytics',
        },
        'QPC conductance'=> {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 4,
            'grid'          => 'ytics',
        },
        'QPC conductance color'=> {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'xformat'       => '%0.0e',
            'yaxis'         => 1,
            'cbaxis'        => 4,
            'grid'          => 'xtics ytics',
        },
    },
);

my $stepsign=$step/abs($step);
my $sdstepsign=$step/abs($step);

for (my $sd=$start_sd;$sdstepsign*$sd<=$sdstepsign*$end_sd;$sd+=$step_sd) {
    $measurement->start_block("Bias $sd V");
    $sd_knick->set_voltage($sd);
    for (my $volt=$start_voltage;$stepsign*$volt<=$stepsign*$end_voltage;$volt+=$step) {
        $gate_knick->set_voltage($volt);
        usleep(500000);
        my $meas=$hp->read_voltage_dc(10,0.0001);
        $measurement->log_line($sd,$volt,$meas);
    }
}

my $meta=$measurement->finish_measurement();
