#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use Lab::Moose;

my $output_folder_name = 'VNA_Sweep';
my $vna_type           = 'RS_ZVA';
my $connection_type    = 'VXI11';
my $host               = '192.168.3.27';
my $timeout            = 30;               # Seconds

# Create VNA instrument
my $vna = instrument(
    type               => $vna_type,
    connection_type    => $connection_type,
    connection_options => { host => $host }
);

# Create output folder, datafile, live plot

my $folder = datafolder( path => $output_folder_name );
my $datafile = datafile(
    type     => 'Gnuplot',
    folder   => $folder,
    filename => 'data.dat',
    columns  => [qw/freq Real Imag Amplitude Phase/],
);

$datafile->add_plot(
    x             => 'freq',
    y             => 'Amplitude',
    curve_options => { with => 'line' },
    hard_copy     => 'data.png',
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

        # vna_bandwidth_resolution_select =>
        #     $vna->sense_bandwidth_resolution_select_query(),
    }
);

# Perform Sweep, get data
warn "Starting sweep...\n";
my $pdl = $vna->sparam_sweep( timeout => $timeout );
warn "Finished sweep\n";

$datafile->log_block( block => $pdl );

