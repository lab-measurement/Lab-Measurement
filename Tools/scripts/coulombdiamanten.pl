#!/usr/bin/perl

# For Lock-In

#$Id$

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Instrument::Yokogawa7651;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $start_voltage=-0.39;
my $end_voltage=-0.52;
my $step=-1e-3;

my $start_sd=1;
my $end_sd=-1;
my $step_sd=-1e-1;

my $gate_knick_gpib=4;
my $sd_knick_gpib=15;
my $hp_gpib=24;

my $amp=1e-7;    # Ithaco amplification
my $divider=1000;
my $v_sd_ac=20e-6;
my $lock_in_sensitivity=10e-3;

my $R_Kontakt=1773;

my $sample="S5c (81059)";
my $title="oberer Quantenpunkt";
my $comment=<<COMMENT;
Differentielle Leitfähigkeit von 12 nach 10. Ca. 20mK.
Lock-In: Sensitivity $lock_in_sensitivity V, V_{SD,AC}=$v_sd_ac V bei 13Hz, 300ms, Normal, Flat.
Ithaco: Amplification $amp, Supression 10e-10, Rise Time 0.3ms.
G11=-0.425 (yoko02); Ghf1=0 (Yoko10); Fahre G01 (yoko04); Ghf2=0 (knick14).
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

#my $gate_knick=new Lab::Instrument::KnickS252({
my $gate_knick=new Lab::Instrument::Yokogawa7651({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_knick_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});
my $sd_knick=new Lab::Instrument::KnickS252({
    'GPIB_address'    => $sd_knick_gpib,
    'gate_protect'    => 1,
    'gp_max_volt_per_second' => 0.010,
    'gp_max_volt_per_step'   => 0.005,
    'gp_max_step_per_second' => 2,
});
    
my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'coulombdiamant',
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
        {   'unit'          => 'V',
            'label'         => 'Bias voltage',
            'description'   => 'Applied to divider/mixing box, then source contact',
        },
        {
            'unit'          => 'V',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gate.',
        },
        {
            'unit'          => 'V',
            'label'         => 'Lock-In output',
            'description'   => "Lock-In output",
        }
    ],
    axes            => [
        {   'unit'          => 'mV',
            'expression'    => '($C0/divider)*1000',
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
            'description'   => 'Applied to gate hf2 via low path filter.',
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
        'Diamanten'=> {
            'type'          => 'pm3d',
            'xaxis'         => 1,
            'yaxis'         => 0,
            'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
    },
);

my $stepsign=$step/abs($step);
my $sdstepsign=$step/abs($step);

for (my $sd=$start_sd;$sdstepsign*$sd<=$sdstepsign*$end_sd;$sd+=$step_sd) {
    $measurement->start_block("Bias $sd V");
    $sd_knick->set_voltage($sd);
    $gate_knick->sweep_to_voltage($start_voltage);
    for (my $volt=$start_voltage;$stepsign*$volt<=$stepsign*$end_voltage;$volt+=$step) {
        $gate_knick->set_voltage($volt);
        usleep(300000);
        my $meas=$hp->read_voltage_dc(10,0.0001);
        $measurement->log_line($sd,$volt,$meas);
    }
}

my $meta=$measurement->finish_measurement();
