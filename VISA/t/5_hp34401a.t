#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 2;

BEGIN { use_ok('VISA::Instrument::HP34401A') };

ok(my $vi=new VISA::Instrument::HP34401A(0,24),'Open HP @ 22');
