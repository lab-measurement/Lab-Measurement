#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use lib '../lib';
use Lab::Moose::Instrument::RS_ZVM;
use Lab::Connection::LinuxGPIB;
use Data::Dumper;

my $connection = Lab::Connection::LinuxGPIB->new( gpib_address => 20 );

my $zvm = Lab::Moose::Instrument::RS_ZVM->new( connection => $connection );

say $zvm->idn( timeout => 3 );

my $catalog = $zvm->sparam_catalog();
say "catalog: @{$catalog}";

for my $i ( 1 .. 60 ) {
    say $i;
    my $data = $zvm->sparam_sweep( timeout => 10 );
    $data->print_to_file( file => '/tmp/data.dat', overwrite => 1 );
}

