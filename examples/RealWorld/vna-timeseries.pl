#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Math::Trig;
use Time::HiRes 'gettimeofday';
use lib '/home/simon/measurement/lib';

use Lab::Moose;

my $zva = instrument(
    type               => 'RS_ZVA',
    connection_type    => 'LinuxGPIB',
    connection_options => { pad => 20 },
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
    type     => 'Gnuplot::2D',
    folder   => $folder,
    filename => 'data.dat',
    columns  => [
        'time',
        's21_re', 's21_im', 'phi_vna'
    ]
);

# VNA plot
$datafile->add_plot(
    x            => 'time',
    y            => 'phi_vna',
    plot_options => {
        title => 'phi-t VNA', xlabel => 'time (s)', ylabel => 'phi (rad)',
        grid  => 1
    },
    curve_options => { with => 'points' },
    hard_copy     => 'phi_vna.png',
);

while (1) {
    my $pdl = $zva->sparam_sweep(
        timeout => 10,
    );
    my ( $freq, $s21_re, $s21_im )
        = ( $pdl->at( 0, 0 ), $pdl->at( 0, 1 ), $pdl->at( 0, 2 ) );

    my $phi = atan( $s21_im / $s21_re );

    my $time = get_seconds();
    say $time;

    $datafile->log(
        time      => $time,
        's21_re'  => $s21_re, 's21_im' => $s21_im,
        'phi_vna' => $phi,
    );
}

sub get_seconds {
    my $sec;
    my $usec;
    ( $sec, $usec ) = gettimeofday();
    return $sec + $usec / 1e6;
}

