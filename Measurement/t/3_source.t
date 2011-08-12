#!/usr/bin/perl

use strict;
use Test::More tests => 6;

BEGIN { use_ok('Lab::Instrument::Source') };

my $default_config={
    config1 => 'value1',
    config2 => 'value2',
    config3 => 'value3',
};
my $config={
    config2 => '2',
};

ok(my $source=new Lab::Instrument::Source($default_config,$config),'Create source');
ok($source->configure('config1') eq 'value1','Default configuration');
ok($source->configure('config2') eq '2','Startup configuration');
ok($source->configure({ config3 => 'drei'}),'Set configuration');
ok($source->configure('config3') eq 'drei','Query new configuration');