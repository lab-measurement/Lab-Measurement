#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
use lib '../lib';
use Lab::Measurement;
use Data::Dumper;

my $instr = Instrument(
    'DummySource',
    {
        connection_type => 'DEBUG',
        gate_protect    => 0
    }
);

my $sweep = Sweep(
    'Voltage',
    {
        instrument => $instr,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 1 ],
        stepwidth  => [0.1],
        rate       => [0.1],
    }
);

my $DataFile = DataFile( 'somefile', 'blocklog' );

$DataFile->add_column('volt');
$DataFile->add_column('frequency');
$DataFile->add_column('s11');

say Dumper $DataFile->add_column();

my $measurement = sub {
    my $sweep = shift;

    my $voltage = $sweep->get_value();

    my $matrix =    # $vna->get_trace(...)
      [ [ 1 + $voltage, 2 + $voltage ], [ 2, 4 ], [ 3, 6 ], [ 4, 8 ], ];

    $sweep->LogBlock(
        prefix => [$voltage],
        block  => $matrix
    );
};

$DataFile->add_measurement($measurement);

$sweep->add_DataFile($DataFile);

$sweep->start();

