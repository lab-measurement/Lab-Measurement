#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 9;

BEGIN { use_ok('VISA') };

my ($status,$def_rm)=VISA::viOpenDefaultRM();
ok($status == $VISA::VI_SUCCESS,'Open default resource manager');

($status,my $listhandle,my $count,my $description)=VISA::viFindRsrc($def_rm,'?*INSTR');
ok($status == $VISA::VI_SUCCESS,'Find all instruments');
diag "$count instruments found";

SKIP: {
	skip("No instruments found", 5) unless ($count > 0);
	
	($status,my $instrument)=VISA::viOpen($def_rm,$description,$VISA::VI_NULL,$VISA::VI_NULL);
	ok($status == $VISA::VI_SUCCESS,'Open first instrument');
	
	my $cmd='*IDN?';
	($status,my $write_cnt)=VISA::viWrite($instrument,$cmd,length($cmd));
	ok($status == $VISA::VI_SUCCESS,'Write to instrument');

	($status,my $result,my $read_cnt)=VISA::viRead($instrument,300);
	ok($status == $VISA::VI_SUCCESS,'Read from instrument');
	diag "First instrument read: $result";

	$status=VISA::viClose($instrument);
	ok($status == $VISA::VI_SUCCESS,'Close first instrument');
	
	SKIP: {
		skip("Only one instrument", 1) unless ($count > 1);
		
		($status, $description)=VISA::viFindNext($listhandle);
		ok($status == $VISA::VI_SUCCESS,'Find next instrument');
		diag "Second instrument: $description";
};

$status=VISA::viClose($def_rm);
ok($status == $VISA::VI_SUCCESS,'Close resource manager');
