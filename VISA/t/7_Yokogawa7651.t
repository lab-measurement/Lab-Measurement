#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 6;

BEGIN { use_ok('VISA::Instrument::Yokogawa7651') };
ok(my $yoko=new VISA::Instrument::Yokogawa7651(0,10),'Open Yoko');

ok(my $status=$yoko->{vi}->Write('H1'),'Write H1');

ok(my $voltage=$yoko->get_voltage(),'get_voltage()');
diag "voltage: $voltage";

ok(my $range=$yoko->get_range(),'get_range()');
diag "range: $range";

ok($yoko->set_voltage(0.1),'set_voltage(0.1)');
