#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use Lab::Moose;

my $ips = instrument(
    type               => 'OI_Mercury::Magnet',
    connection_type    => 'Socket',
    connection_options => { host => '192.168.3.15' },
);

my $vna = instrument(
    type               => 'RS_ZVA',
    connection_type    => 'VXI11',
    connection_options => { host => '192.168.3.27' },
);

# IF bandwidth (Hz)
$vna->sense_bandwidth_resolution( value => 1 );

my $field_sweep = sweep(
    type       => 'Continuous::Magnet',
    instrument => $ips,
    from       => 2,                      # Tesla
    to         => 0,                      # Tesla
    rate       => 0.01,                   # Tesla/min
    start_rate => 1,    # Tesla/min (rate to approach start point)
    interval   => 0,    # run slave sweep as often as possible
);

# Measure transmission at 1GHz, 2GHz, ..., 10GHz
my $frq_sweep = sweep(
    type       => 'Step::Frequency',
    instrument => $vna,
    from       => 1e9,
    to         => 10e9,
    step       => 1e9
);

my $datafile = sweep_datafile(
    columns => [ 'field', 'frq', 'Re', 'Im', 'Amp', 'phi' ] );
$datafile->add_plot( x => 'field', y => 'Amp' );

my $meas = sub {
    my $sweep = shift;

    say "frq: ", $sweep->get_value();
    my $field = $ips->get_field();
    my $pdl = $vna->sparam_sweep( timeout => 10 );
    $sweep->log_block(
        prefix => { field => $field },
        block  => $pdl
    );
};

$field_sweep->start(
    slave       => $frq_sweep,
    datafile    => $datafile,
    measurement => $meas,
    folder      => 'Magnetic_Resonance',
);

