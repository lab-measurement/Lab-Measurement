#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use lib '../lib';
use Lab::Measurement;
use aliased 'Lab::Moose::Instrument::RS_ZVA';
use aliased 'Lab::Instrument::YokogawaGS200' => 'Yoko';
use aliased 'Lab::Connection::LinuxGPIB'     => 'GPIB';

my $zva = RS_ZVA->new( connection => GPIB->new( gpib_address => 20 ) );

my $source = Yoko->new(
    connection   => GPIB->new( gpib_address => 1 ),
    gate_protect => 0
);

my $sweep = Sweep(
    'Voltage',
    {
        instrument => $source,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 1 ],
        stepwidth  => [0.002],
        rate       => [0.1]
    }
);

my $DataFile = DataFile('zva-sweep');

$DataFile->add_column('source_voltage');
$DataFile->add_column('freq');

my @sparams = @{ $zva->sparam_catalog() };

for my $sparam (@sparams) {
    $DataFile->add_column($sparam);
}

my $measurement = sub {
    my $sweep   = shift;
    my $voltage = $sweep->get_value();
    my $data    = $zva->sparam_sweep();

    $sweep->LogBlock(
        prefix => [$voltage],
        block  => $data->matrix(),
    );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);

$sweep->start();

