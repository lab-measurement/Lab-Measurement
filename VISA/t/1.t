#!/usr/bin/perl

use strict;
use Test::More tests => 2;

BEGIN { use_ok('VISA') };

my ($status)=VISA::viOpenDefaultRM();
ok($status == $VISA::VI_SUCCESS,'Open Default Resource Manager');
