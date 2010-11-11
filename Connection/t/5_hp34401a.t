#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 11;

BEGIN { use_ok('Lab::Instrument::HP34401A') };

ok(my $hp=new Lab::Instrument::HP34401A(0,24),'Open HP 24');
ok(my $voltage=$hp->read_voltage_dc(10,0.00001),'read_voltage_dc(10,0.00001)');
diag "read $voltage";
ok($hp->display_text("japh"),'display_text($text)');
ok("japh" eq $hp->display_text(),'display_text()');
ok($hp->display_off(),'display_off');
ok($hp->display_on(),'display_on');
ok($hp->display_clear(),'display_clear');
ok(my ($err_num,$err_msg)=$hp->get_error(),'get_error');
diag "error $err_num: $err_msg";
ok($hp->scroll_message(),'scroll_message');
ok($hp->beep(),"beep");

