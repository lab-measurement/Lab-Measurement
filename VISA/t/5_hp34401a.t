#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 3;

BEGIN { use_ok('VISA::Instrument::HP34401A') };

ok(my $hp=new VISA::Instrument::HP34401A("34401A"),'Open any HP');
ok($hp->read_voltage_dc(10,0.00001),'read_voltage_dc(10,0.00001)');
