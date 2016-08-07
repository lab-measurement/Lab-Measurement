#!perl
use 5.010;
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 2;

use Lab::Measurement;

my $source = Instrument('DummySource', {
    connection_type => 'DEBUG',
    gate_protect => 0
			});


# set/get level

my $expected = 1.11;

$source->set_level($expected);

my $level = $source->get_level();

ok($expected == $level, "level set to $expected");

# set/get range

$expected = 100;

$source->set_range($expected);

my $range = $source->get_range();

ok($expected == $range, "range set to $expected");
