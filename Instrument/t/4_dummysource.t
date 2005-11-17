#!/usr/bin/perl

use strict;
use Test::More tests => 8;

BEGIN { use_ok('Lab::Instrument::Dummysource') };

my $config={
    gp_max_step_per_second  => 3,
};

ok(my $source=new Lab::Instrument::Dummysource($config),'Create dummy source');
ok($source->configure('gate_protect') == 1,'Default configuration gate_protect');
ok($source->configure('gp_max_step_per_second') == 3,'My configuration');

ok($source->get_voltage() == 0,'Get start voltage');
ok($source->get_range() == 1,'Get start range');

ok($source->_set_voltage(0.1),'_Set voltage');
ok($source->get_voltage() == 0.1,'Get voltage');

$source->sweep_to_voltage(0.11);