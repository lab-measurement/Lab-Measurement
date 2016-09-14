#!/usr/bin/env perl

# before you run this, connect AUX OUT 1 with AUX IN 1 and AUX OUT 2 with AUX
# IN 2.

use 5.010;
use warnings;
use strict;

use lib qw(../lib);
use Data::Dumper;
use Test::More tests => 23;

use Lab::Measurement;
use Scalar::Util qw(looks_like_number);

use TestLib;

my $connection
    = Connection( get_gpib_connection_type(), { gpib_address => 8 } );

my $input1 = Instrument(
    'SR830::AuxIn',
    {
        connection => $connection,
        channel    => 1,
    }
);

my $input2 = Instrument(
    'SR830::AuxIn',
    {
        connection => $connection,
        channel    => 2,
    }
);

my $output1 = Instrument(
    'SR830::AuxOut',
    {
        connection   => $connection,
        gate_protect => 0,
        channel      => 1,
    }
);

my $output2 = Instrument(
    'SR830::AuxOut',
    {
        connection   => $connection,
        gate_protect => 0,
        channel      => 2,
    }
);

my $level;

# set output values:
$output1->set_level(1.111);
$output2->set_level(2.222);

# get output values:
$level = $output1->get_level();
is( $level, 1.111, 'output 1 is set' );

$level = $output2->get_level();
is( $level, 2.222, 'output 2 is set' );

# read inputs
$level = $input1->get_value();

ok( relative_error( $level, 1.111 ) < 1 / 50, 'voltage at input 1' );

$level = $input2->get_value();

ok( relative_error( $level, 2.222 ) < 1 / 50, 'voltage at input 2' );

# sweep with "mode => step"

my $sweep = Sweep(
    'Voltage',
    {
        instrument => $output1,
        mode       => 'step',
        jump       => 1,
        points     => [ 1, 1.01 ],
        stepwidth  => [0.001],
        rate       => [1],
    }
);

my $expected_value = 1;
my $DataFile       = DataFile('Somefile');

my $step_measurement = sub {
    my $sweep = shift;
    my $value = $output1->get_level();
    is( $value, $expected_value, "sweep is at $expected_value" );
    if ( $value != 1.01 ) {

        # we need this check, as this function seems to be called twice
        # for the final value.
        $expected_value += 0.001;
    }
};

$DataFile->add_measurement($step_measurement);
$sweep->add_DataFile($DataFile);
$sweep->start;

# sweep with "mode => list"
my @points = qw/0.125 0.25 0.5 1 2 4 8/;
$sweep = Sweep(
    'Voltage',
    {
        instrument => $output1,
        mode       => 'list',
        jump       => 1,
        points     => \@points,
        stepwidth  => [0.1],
        rate       => [1],
    }
);

$DataFile = DataFile('Somefile');

my $point_index = 0;

my $list_measurement = sub {
    my $sweep          = shift;
    my $value          = $output1->get_level();
    my $expected_value = $points[$point_index];
    is( $value, $expected_value, "sweep is at $expected_value" );
    if ( $value != 8 ) {

        # we need this check, as this function seems to be called twice
        # for the final value.
        ++$point_index;
    }
};

$DataFile->add_measurement($list_measurement);
$sweep->add_DataFile($DataFile);
$output1->_set_level(0);
$sweep->start;
