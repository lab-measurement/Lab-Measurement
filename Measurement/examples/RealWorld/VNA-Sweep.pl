#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use Lab::Moose;
use PDL::Lite;
use PDL::Ops 'log10';

my $output_folder_name = 'VNA_Sweep';
my $vna_type           = 'RS_ZVA';
my $connection_type    = 'LinuxGPIB';
my $gpib_address       = 20;
my $timeout            = 30;            # Seconds

# Create VNA instrument
my $vna = instrument(
    type               => $vna_type,
    connection_type    => $connection_type,
    connection_options => {
        pad => $gpib_address,
    }
);

# Create output folder, datafile, live plot

my $folder = datafolder( path => $output_folder_name );
my $datafile = datafile(
    type     => 'Gnuplot::2D',
    folder   => $folder,
    filename => 'data.dat',
    columns  => [qw/freq Real Imag Amplitude/],
);

$datafile->add_plot(
    x             => 'freq',
    y             => 'Amplitude',
    curve_options => { with => 'line' },
    plot_options  => {
        grid   => 1,
        xlabel => 'freq',
        ylabel => 'Amplitude (dB)',
    }
);

# Log details of VNA configuration into META.yml.

my $meta_file = $folder->meta_file();
$meta_file->log(
    meta => {
        vna_sparams                => $vna->sparam_catalog(),
        vna_freq_start             => $vna->sense_frequency_start_query(),
        vna_freq_stop              => $vna->sense_frequency_stop_query(),
        vna_sweep_number_of_points => $vna->sense_sweep_points_query(),
        vna_reference_power =>
            $vna->source_power_level_immediate_amplitude_query(),
        vna_bandwidth_resolution => $vna->sense_bandwidth_resolution_query(),
        vna_bandwidth_resolution_select =>
            $vna->sense_bandwidth_resolution_select_query(),
    }
);

# Perform Sweep, get data
my $pdl = $vna->sparam_sweep( timeout => $timeout );

# Calculate amplitude values (dB) out of sparams
my $real      = $pdl->slice(":,1");
my $imag      = $pdl->slice(":,2");
my $amplitude = 10 * log10( $real**2 + $imag**2 );

# Append amplitude as last column
$pdl->glue( 1, $amplitude );

$datafile->log_block( block => $pdl );

