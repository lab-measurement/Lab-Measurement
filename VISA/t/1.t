#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 10;

BEGIN { use_ok('Lab::VISA') };

my ($status,$def_rm)=Lab::VISA::viOpenDefaultRM();
ok($status == $Lab::VISA::VI_SUCCESS,'Open default resource manager');

($status,my $listhandle,my $count,my $description)=Lab::VISA::viFindRsrc($def_rm,'?*INSTR');
ok($status == $Lab::VISA::VI_SUCCESS,'Find all instruments');
diag "$count instruments found";

SKIP: {
	skip("No instruments found", 5) unless ($count > 0);
	
	($status,my $instrument)=Lab::VISA::viOpen($def_rm,$description,$Lab::VISA::VI_NULL,$Lab::VISA::VI_NULL);
	ok($status == $Lab::VISA::VI_SUCCESS,'Open first instrument');
	
	my $cmd='*IDN?';
	($status,my $write_cnt)=Lab::VISA::viWrite($instrument,$cmd,length($cmd));
	ok($status == $Lab::VISA::VI_SUCCESS,'Write to instrument');

	($status,my $result,my $read_cnt)=Lab::VISA::viRead($instrument,300);
	ok($status == $Lab::VISA::VI_SUCCESS,'Read from instrument');
	diag "First instrument read: $result";

	$status=Lab::VISA::viClose($instrument);
	ok($status == $Lab::VISA::VI_SUCCESS,'Close first instrument');
	
	SKIP: {
		skip("Only one instrument", 1) unless ($count > 1);
		
		($status, $description)=Lab::VISA::viFindNext($listhandle);
		ok($status == $Lab::VISA::VI_SUCCESS,'Find next instrument');
		diag "Second instrument: $description";
	}
};

$status=Lab::VISA::viClose($listhandle);
ok($status == $Lab::VISA::VI_SUCCESS,'Close findList');

$status=Lab::VISA::viClose($def_rm);
ok($status == $Lab::VISA::VI_SUCCESS,'Close resource manager');
