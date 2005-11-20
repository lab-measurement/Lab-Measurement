#!/usr/bin/perl

use strict;
use Test::More tests => 35;
use Time::HiRes qw(gettimeofday);

BEGIN { use_ok('Lab::Instrument::Dummysource') };

my $config={
    gp_max_step_per_second  => 3,
};

ok(my $source=new Lab::Instrument::Dummysource($config),'Create dummy source');
ok($source->configure('gate_protect') == 1,'Default configuration gate_protect');
ok($source->configure('gp_max_step_per_second') == 3,'Custom configuration');

ok($source->get_voltage() == 0,'Get start voltage');
ok($source->get_range() == 1,'Get start range');

ok($source->_set_voltage(0.105),'_set_voltage');
ok($source->get_voltage() == 0.105,'get_voltage');

ok($source->configure({
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
    gp_max_step_per_second  => 4,
}),'Set custom configuration (hashref)');
ok(abs($source->step_to_voltage(0.11)-0.106) < 0.00001,'step_to_voltage test 1a');
ok(abs($source->step_to_voltage(0.1065)-0.1065) < 0.00001,'step_to_voltage test 1b');
ok((abs($source->step_to_voltage(0.1075)-0.1075) < 0.00001),'step_to_voltage test 1c');
ok((abs($source->sweep_to_voltage(0.11)-0.11) < 0.00001),'sweep_to_voltage test 1');

my ($ns,$mus)=gettimeofday();
my $start=$ns*1e6+$mus;
ok(abs($source->set_voltage(0.14)-0.14) < 0.00001,'set_voltage test 1');
($ns,$mus)=gettimeofday();
my $now=$ns*1e6+$mus;
ok((abs(($now-$start)/1e6)-15) < 1,'timing test 1');


$source->configure({
    gp_max_volt_per_second  => 0.05,
    gp_max_volt_per_step    => 0.0002,
    gp_max_step_per_second  => 8,
});
ok(abs($source->step_to_voltage(0.13)-0.1398) < 0.00001,'step_to_voltage test 2');
ok(abs($source->sweep_to_voltage(0.135)-0.135) < 0.00001,'sweep_to_voltage test 2');

($ns,$mus)=gettimeofday();
$start=$ns*1e6+$mus;
ok(abs($source->set_voltage(0.115)-0.115) < 0.00001,'set_voltage test 2');
($ns,$mus)=gettimeofday();
$now=$ns*1e6+$mus;
ok((abs(($now-$start)/1e6)-12.5) < 1,'timing test 2');


ok($source->configure({
    gate_protect => 0}),'gate_protect off');

($ns,$mus)=gettimeofday();
$start=$ns*1e6+$mus;
ok(abs($source->set_voltage(-0.105)+0.105) < 0.00001,'gp off set_voltage');
($ns,$mus)=gettimeofday();
$now=$ns*1e6+$mus;
ok((($now-$start)/1e6) < 0.1,'gp off timing');

ok($source->configure({
    gate_protect => 1}),'gate_protect on');

ok($source->configure({
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
    gp_max_step_per_second  => 4,
}),'Set custom configuration (hashref)');
ok(abs($source->step_to_voltage(-0.11)+0.106) < 0.00001,'step_to_voltage test 3a');
ok(abs($source->step_to_voltage(-0.1065)+0.1065) < 0.00001,'step_to_voltage test 3b');
ok(abs($source->step_to_voltage(-0.1075)+0.1075) < 0.00001,'step_to_voltage test 3c');
ok(abs($source->sweep_to_voltage(-0.11)+0.11) < 0.00001,'sweep_to_voltage test 3');

($ns,$mus)=gettimeofday();
$start=$ns*1e6+$mus;
ok(abs($source->set_voltage(-0.14)+0.14) < 0.00001,'set_voltage test 3');
($ns,$mus)=gettimeofday();
$now=$ns*1e6+$mus;
ok((abs(($now-$start)/1e6)-15) < 1,'timing test 3');


$source->configure({
    gp_max_volt_per_second  => 0.05,
    gp_max_volt_per_step    => 0.0002,
    gp_max_step_per_second  => 8,
});
ok(abs($source->step_to_voltage(-0.13)+0.1398) < 0.00001,'step_to_voltage test 4');
my $t=$source->sweep_to_voltage(-0.135);
diag $t;
ok(abs($t+0.135) < 0.00001,'sweep_to_voltage test 4');
#ok(abs($source->sweep_to_voltage(-0.135)+0.135) < 0.00001,'sweep_to_voltage test 4');
ok(abs($source->get_voltage() + 0.135) < 0.00001,'get_voltage 2');

($ns,$mus)=gettimeofday();
$start=$ns*1e6+$mus;
ok(abs($source->set_voltage(-0.115)+0.115) < 0.00001,'set_voltage test 4');
($ns,$mus)=gettimeofday();
$now=$ns*1e6+$mus;
ok((abs(($now-$start)/1e6))-12.5 < 1,'timing test 4');

