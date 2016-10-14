#!/usr/bin/env perl
use 5.020;

use warnings;
use strict;

use experimental 'signatures';
use experimental 'postderef';

use Lab::Measurement;

# Use short aliases for those loooong module names.
use aliased 'Lab::Moose::Instrument::RS_ZVA' => 'VNA';
use aliased 'Lab::Instrument::YokogawaGS200' => 'Source';
use aliased 'Lab::Connection::LinuxGPIB'     => 'GPIB';

# Construct instruments and connections.
my $vna = VNA->new( connection => GPIB->new( gpib_address => 20 ) );

my $source = Source->new(
    connection   => GPIB->new( gpib_address => 1 ),
    gate_protect => 0
);

# Define the 'outer' gate sweep.
my $sweep = Sweep(
    'Voltage', {
        instrument => $source,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 1 ],
        stepwidth  => [0.002],
        rate       => [0.1]
    }
);

my $DataFile = DataFile('vna-sweep');

# If we just measure one S-parameter, we will have 4 columns.
$DataFile->add_column('source_voltage');
$DataFile->add_column('freq');

# Get names of the configured S-parameter real/imag parts.
my @sparams = $vna->sparam_catalog()->@*;

for my $sparam (@sparams) {
    $DataFile->add_column($sparam);
}

my $measurement = sub ($sweep) {
    my $voltage = $sweep->get_value();
    my $data    = $vna->sparam_sweep();

    $sweep->LogBlock(
        prefix => [$voltage],
        block  => $data->matrix(),
    );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);

$sweep->start();

