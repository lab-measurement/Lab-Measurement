#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use lib '../lib';
use aliased 'Lab::Moose::Instrument::RS_ZVA';

use aliased 'Lab::Connection::LinuxGPIB' => 'GPIB';

#use Lab::Moose::Connection::Debug;
use Data::Dumper;

my $zvm = RS_ZVA->new( connection => GPIB->new( gpib_address => 20 ) );

# $zvm->cached_calculate_data_call_catalog( ['s11'] );
# $zvm->cached_sense_frequency_start(10);
# $zvm->cached_sense_frequency_stop(10);
# $zvm->cached_sense_sweep_points(10);
# $zvm->cached_format_data( [ 'REAL', 32 ] );
# $zvm->cached_format_border('SWAP');
# $zvm->cached_initiate_continuous(0);

for my $i ( 0 .. 100 ) {
    say $i;
    my $data = $zvm->sparam_sweep( timeout => 10 );
}

#$data->print_to_file( file => '/tmp/rs-zva.dat', overwrite => 1 );

