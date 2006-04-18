#!/usr/bin/perl
#$Id: pinch-off-qpc2.pl 351 2006-04-17 19:51:09Z schroeer $

use strict;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

my $measurement=new Lab::Measurement(
    sample          => "N00",
    title           => "This ain't no real data",
    filename_base   => 'dummy_measurement',
    description     => <<DESCRIPTION,
Das ist keine echte Messung.
Daten werden erfunden.
DESCRIPTION

    live_plot       => 'QPC lines',
    
    constants       => [
        {
            'name'          => 'G0',
            'value'         => '7.748091733e-5',
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
            'label'         => 'Source drain Knick',
            'description'   => "blabla",
        },
        {
            'unit'          => 'V',
            'label'         => 'Amplifier output',
            'description'   => "blabla",
        },
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gates via low path filter.',
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1/1563',
            'label'         => 'Bias voltage',
            'description'   => 'Bias voltage (via divider).',
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "\$C2/1000",
            'label'         => "QPC conductance",
        },
        
    ],
    plots           => {
        'QPC lines'=> {
            'type'          => 'line',
            'xaxis'         => 1,
            'yaxis'         => 2,
        },
        'QPC conductance'=> {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'        => 2,
        }
    },
);

for my $outer (-20..0) {
    $measurement->start_block();
    for my $inner (-100..-40) {
        my $val=sin($outer/5)+cos($inner/10);
        $measurement->log_line($outer/1000,$inner/1000,$val);
#       printf "%f - %f - %f\n",$outer/1000,$inner/1000,$val;
    }
}

my $meta=$measurement->finish_measurement();

my $plotter=new Lab::Data::Plotter($meta);

$plotter->plot('QPC lines');

my $a=<stdin>;

