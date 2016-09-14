#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use lib '../lib';

use Lab::Measurement;

use Lab::MooseInstrument::RS_ZVA;

use Data::Dumper;

my $connection = Connection(
    'LinuxGPIB::Log',
    { gpib_address => 20, logfile => '/tmp/zva.yml' }
);

my $zva = Lab::MooseInstrument::RS_ZVA->new( connection => $connection );

for my $i ( 1 .. 200 ) {
    say "sweep no $i";
    my $data = $zva->sweep( timeout => 10, precision => 'double' );
    $data->print_to_file( file => "/tmp/data$i", overwrite => 1 );
}

