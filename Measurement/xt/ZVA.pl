#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use lib '../lib';

use Lab::Measurement;

use Lab::MooseInstrument::ZVA;

use Data::Dumper;

my $connection = Connection( 'LinuxGPIB::Log',
    { gpib_address => 20, logfile => '/tmp/zva.yml' } );

my $zva = Lab::MooseInstrument::ZVA->new( connection => $connection );

say $zva->idn();

$zva->sense_frequency_start( value => 1e9 );

$zva->sense_frequency_stop( value => 2e9 );

$zva->sense_sweep_points( value => 1000 );

for my $i ( 1 .. 20 ) {
    say "sweep no $i";
    my $data = $zva->sweep( timeout => 10, read_length => 1000000 );
    $data->print_to_file( file => "/tmp/data$i", overwrite => 1 );
}

