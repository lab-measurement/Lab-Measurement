#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use lib '../lib';
use Lab::Measurement;

use Lab::MooseInstrument::RS_ZVA;

my $zva = Lab::MooseInstrument::RS_ZVA->new(
    connection => Connection(
        'LinuxGPIB::Log',
        {
            gpib_address => 20,
            logfile      => '/tmp/zva-sweep.yml'
        }
    )
);

my $source = Instrument(
    'DummySource',
    {
        connection_type => 'DEBUG',
        gate_protect    => 0
    }
);

my $sweep = Sweep(
    'Voltage',
    {
        instrument => $source,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 1 ],
        stepwidth  => [0.01],
        rate       => [0.1]
    }
);

my $DataFile = DataFile('zva-sweep');

$DataFile->add_column('source_voltage');
$DataFile->add_column('freq');

my @sparams = @{ $zva->complex_catalog() };

for my $sparam (@sparams) {
    $DataFile->add_column($sparam);
}

my $measurement = sub {
    my $sweep   = shift;
    my $voltage = $sweep->get_value();
    my $data    = $zva->sweep();

    $sweep->LogBlock(
        prefix => [$voltage],
        block  => $data->matrix(),
    );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);

$sweep->start();

