#!/usr/bin/perl

use strict;
use Test::More tests => 2;

BEGIN { use_ok('VISA') };

my ($status,$def_rm)=VISA::viOpenDefaultRM();
ok($status == $VISA::VI_SUCCESS,'Open Default Resource Manager');
($status,my $listhandle,my $count,my $description)=VISA::viFindRsrc($def_rm,"?*INSTR");
ok($status == $VISA::VI_SUCCESS,'Find all Instruments');