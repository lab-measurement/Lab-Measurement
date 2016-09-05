#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use DeviceKid;
use Data::Dumper;

my $instr = DeviceKid->new();


say $instr->cache_get(key => 'lala');

$instr->cache_set(key => 'lala', value => 'abc');


say $instr->cache_get(key => 'lala');

say $instr->cache_get(key => 'lala_kid');
