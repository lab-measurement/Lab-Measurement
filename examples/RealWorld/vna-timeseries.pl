#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

# make time() return floating seconds (Unix time)
use Time::HiRes 'time';

use Lab::Moose;

my $zva = instrument(
    type               => 'RS_ZVA',
    connection_type    => 'VXI11',
    connection_options => { host => '192.168.3.27' },
);

say "set up zva";

my $sparams = $zva->sparam_catalog();
say "sparams: @{$sparams}";

# Setup IF bandwidth
$zva->sense_bandwidth_resolution( value => 1 );
$zva->sense_bandwidth_resolution_select( value => 'HIGH' );

# Set power to -20 dBm
$zva->source_power_level_immediate_amplitude( value => -20 );

# Setup sweep parameters
$zva->sense_frequency_start( value => 4e9 );
$zva->sense_frequency_stop( value => 4e9 );

# Single point sweep
$zva->sense_sweep_points( value => 1 );

# Datafile and plots
my $folder = datafolder( path => 'vna-vs-heterodyne' );

my $datafile = datafile(
    type     => 'Gnuplot',
    folder   => $folder,
    filename => 'data.dat',
    columns  => [
        'time',
        'freq', 's21_re', 's21_im', 'amplitude', 'phase'
    ]
);

# VNA plot for complex phase
$datafile->add_plot(
    x         => 'time',
    y         => 'phase',
    hard_copy => 'phi_vna.png',
);

while (1) {
    my $pdl = $zva->sparam_sweep(
        timeout => 10,
    );

    my $time = time();
    say $time;

    $datafile->log_block(
        prefix => { time => $time },
        data   => $pdl
    );
}

