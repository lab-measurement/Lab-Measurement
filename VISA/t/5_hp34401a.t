#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 2;

BEGIN { use_ok('VISA::Instrument::HP34401A') };

ok(my $vi=new VISA::Instrument::HP34401A(24,0),'Open HP @ 24');
