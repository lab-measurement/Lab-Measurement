#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 3;

BEGIN { use_ok('VISA::Instrument') };

ok(my $vi=find VISA::Instrument(""),'Open any instrument');
ok(my $idn=$vi->Query('*IDN?'),'Query identification');
diag "Instrument $idn";
