#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib 'lib';

use Lab::Moose;

use File::Temp 'tempfile';

my ( undef, $filename ) = tempfile();

sub dummysource {
    return instrument(
        type                 => 'DummySource',
        connection_type      => 'Debug',
        connection_options   => { verbose => 0 },
        verbose              => 0,
        max_units            => 10,
        min_units            => -10,
        max_units_per_step   => 100,
        max_units_per_second => 1000000,
    );
}

my $source = dummysource();

warn "output folder: $filename";

my $sweep = sweep(
    type => 'Step::Voltage', instrument => $source, from => -1,
    to   => 1,               step       => 0.01
);

my $datafile_2d = sweep_datafile( columns => [qw/x y/] );
$datafile_2d->add_plot( x => 'x', y => 'y' );

my $meas = sub {
    my $sweep = shift;
    my $x     = $source->cached_level();
    $sweep->log( x => $x, y => $x**2 );
};

$sweep->start(
    datafiles   => [$datafile_2d],
    measurement => $meas,
    folder      => $filename,

);

