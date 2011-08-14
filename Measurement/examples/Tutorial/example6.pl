#!/usr/bin/perl

# example6.pl

# Eine Spannungsquelle fahren, Leitfähigkeit (ohne Lock-In) messen

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $start_voltage   =-0.05;
my $end_voltage     =-0.25;
my $step            =-1e-3;

my $knick_gpib      =4;
my $hp_gpib         =24;

my $v_sd            =-300e-3/1000;
my $amp             =1e-9;    # Ithaco amplification

my $R_Kontakt       =1089;

my $sample          ="S5c (81059)";
my $title           ="QPC links unten";
my $comment         =<<COMMENT;
Strom von 12 nach 14; V_{SD,DC}=$v_sd V; Lüftung an; Ca. 25mK.
Ithaco: Amplification $amp, Supression 10e-10 off, Rise Time 0.3ms.
Fahre Ghf4 (Yoko04)
COMMENT

################################

my $knick=new Lab::Instrument::KnickS252({
    'GPIB_board'    => 0,
    'GPIB_address'  => $knick_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'qpctest',
    description     => $comment,

    live_plot       => 'QPC current',
    
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
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => 'V_{Gate}',
            'min'           => ($start_voltage < $end_voltage)
                               ? $start_voltage
                               : $end_voltage,
            'max'           => ($start_voltage < $end_voltage)
                               ? $end_voltage
                               : $start_voltage,
            'description'   => 'Gate voltage',
        },
        {
            'unit'          => 'A',
            'expression'    => "abs(\$C1)*AMP",
            'label'         => 'I_{QPC}',
            'description'   => 'QPC current',
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(1/(V_SD/(-\$C2*AMP)-RKontakt))/G0",
            'label'         => "G_{QPC}",
            'description'   => "QPC conductance",
            'min'           => -0.1,
            'max'           => 7
        },
        
    ],
    plots           => {
        'QPC current'    => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'grid'          => 'xtics ytics',
        },
        'QPC conductance'=> {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 3,
            'grid'          => 'ytics',
        }
    },
);

$measurement->start_block();

my $stepsign=$step/abs($step);
for (my $volt=$start_voltage;
     $stepsign*$volt<=$stepsign*$end_voltage;
     $volt+=$step) {
    $knick->set_voltage($volt);
    usleep(500000);
    my $meas=$hp->read_voltage_dc(10,0.0001);
    $measurement->log_line($volt,$meas);
}

my $meta=$measurement->finish_measurement();

