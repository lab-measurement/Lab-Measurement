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

$zva->format_data( format => 'ASC', length => 64 );
$zva->initiate_continuous( value => 0 );

for my $i ( 0 .. 100 ) {
    say $i;
    $zva->initiate_immediate();
    $zva->wai();
    my $string = $zva->calculate_data_call( format => 'SDATA' );
    say "response length: ", length $string;
}

