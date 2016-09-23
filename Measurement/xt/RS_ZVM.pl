#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use lib '../lib';
use aliased 'Lab::Moose::Instrument::RS_ZVM' => 'ZVM';
use aliased 'Lab::Connection::LinuxGPIB'     => 'GPIB';
use Data::Dumper;

my $zvm = ZVM->new(
    connection => GPIB->new( gpib_address => 20 ),
    log_file   => 'RS_ZVM.yml'
);

$zvm->rst( timeout => 10 );
my $catalog = $zvm->sparam_catalog();
say "catalog: @{$catalog}";

$zvm->sense_sweep_points( value => 3 );

for my $i ( 1 .. 3 ) {
    say $i;
    my $data = $zvm->sparam_sweep( timeout => 10 );
}
