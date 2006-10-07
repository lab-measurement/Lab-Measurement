#!/usr/bin/perl

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Measurement;
use Time::HiRes qw/usleep/;

################################

my $start_voltage   =  1.5;
my $end_voltage     = -3.5;
my $step            = -0.05;

my $knick_gpib      = 14;
my $hp_gpib         = 21;

my $sample          = "Zenerdiode";
my $title           = "Messung mit Lab::Measurement";
my $comment         = <<COMMENT;
Reihenschaltung aus Widerstand 1kOhm und Zenerdiode.
COMMENT

################################

my $knick=new Lab::Instrument::KnickS252({
    'GPIB_board'    => 0,
    'GPIB_address'  => $knick_gpib,
    'gate_protect'  => 0,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'zener_kennlinie',
    description     => $comment,

    live_plot       => 'diode current',

    constants       => [
        {
            'name'          => 'R',
            'value'         => '1000',
        },
    ],
    columns         => [
        {
            'unit'          => 'V',
            'label'         => 'V_{bias}',
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
            'label'         => 'V_{bias}',
            'description'   => 'Bias voltage',
            'min'           => ($start_voltage < $end_voltage)
                               ? $start_voltage
                               : $end_voltage,
            'max'           => ($start_voltage < $end_voltage)
                               ? $end_voltage
                               : $start_voltage,
        },
        {
            'unit'          => 'mA',
            'expression'    => '1000*($C1/R)',
            'label'         => 'I_{diode}',
            'description'   => 'Current through diode',
            'min'           => '-1.2',
            'max'           => '1.2',
        },
        {
            'unit'          => 'Ohm',
            'expression'    => 'R * ($C0/$C1 - 1)',
            'label'         => 'R_{diode}',
            'description'   => 'Diode resistance',
        },
    ],
    plots           => {
        'diode current'    => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'grid'          => 'xtics ytics',
        },
        'diode resistance' => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 2,
            'grid'          => 'xtics ytics',
            'logscale'      => 'y',
        },
    },
);

$measurement->start_block();

for (
    my $volt = $start_voltage;
    ($volt - $end_voltage) / $step < 0.5;
    $volt += $step
) {
    $knick->set_voltage($volt);
    usleep(500000);
    my $meas = $hp->read_voltage_dc(10,0.0001);
    $measurement->log_line($volt,$meas);
}

my $meta = $measurement->finish_measurement();

