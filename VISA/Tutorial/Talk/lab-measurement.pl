#!/usr/bin/perl

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

my $knick=new Lab::Instrument::KnickS252({
    'GPIB_board'    => 0,
    'GPIB_address'  => 14,
    'gate_protect'  => 0,
});

my $hp=new Lab::Instrument::HP34401A(0,23);

my $measurement=new Lab::Measurement(
    sample          => "Zenerdiode",
    title           => "Messung mit Lab::Measurement",
    filename_base   => 'zener_kennlinie',
    description     => "Reihenschaltung aus Widerstand 1kOhm und Zenerdiode."

    live_plot       => 'current',

    constants       => [
        {
            'name'          => 'R_Vorwiderstand',
            'value'         => '1000',
        },
    ],
    columns         => [
        {
            'unit'          => 'V',
            'label'         => 'V_{Bias}',
            'description'   => 'Bias Voltage',
        },
        {
            'unit'          => 'V',
            'label'         => 'Amplifier output',
            'description'   => 'Voltage drop on serial resistor',
        }
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => 'V_{Bias}',
            'min'           => -3.5,
            'max'           =>  1.5,
            'description'   => 'Bias voltage',
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => 'V_{Resistor}',
            'description'   => 'Voltage drop of serial resistor',
        },
        {
            'unit'          => 'mA',
            'expression'    => '1000*($C1/R_Vorwiderstand)',
            'label'         => 'I_{Resistor}',
            'description'   => 'Current through resistor',
        },
    ],
    plots           => {
        'voltage drop'    => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'grid'          => 'xtics ytics',
        },
        'current'    => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 2,
            'grid'          => 'xtics ytics',
        },
    },
);

$measurement->start_block();

my $stepsign=$step/abs($step);
for (my $volt=1.5 ; $volt>=-3.5 ; $volt+=-0.1) {
    $knick->set_voltage($volt);
    usleep(500000);
    my $meas=$hp->read_voltage_dc(10,0.0001);
    $measurement->log_line($volt,$meas);
}

my $meta=$measurement->finish_measurement();

