#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use lib '../lib';

use Lab::Measurement;

use Lab::MooseInstrument::ZVA;

my $connection = Connection('LinuxGPIB', {gpib_address => 20});

my $zva = Lab::MooseInstrument::ZVA->new(connection => $connection);

say $zva->idn();

say $zva->calculate_data_call_catalog_query();
