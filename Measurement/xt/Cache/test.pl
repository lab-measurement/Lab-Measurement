#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib qw(. ../../lib);

use TestConnection;
use Device;
my $connection = TestConnection->new();

my $instr = Device->new( connection => $connection );

say $instr->cache_get( key => 'id' );
say $instr->cache_get( key => 'id' );
