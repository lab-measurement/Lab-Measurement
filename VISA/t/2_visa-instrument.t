#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 2;

BEGIN { use_ok('VISA::Instrument') };

ok(my $vi=new VISA::Instrument(24,0),'Open default resource manager');
