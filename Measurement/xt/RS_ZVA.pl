#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use lib '../lib';
use aliased 'Lab::Moose::Instrument::RS_ZVA';

use aliased 'Lab::Connection::LinuxGPIB' => 'GPIB';

#use Lab::Moose::Connection::Debug;
use Data::Dumper;

my $zvm = RS_ZVA->new(
    connection => GPIB->new( gpib_address => 20 ),
    log_file   => '/tmp/zva.yml'
);

for my $i ( 0 .. 100 ) {
    say $i;
    my $data = $zvm->sparam_sweep( timeout => 30, average => 100 );
}

#$data->print_to_file( file => '/tmp/rs-zva.dat', overwrite => 1 );

