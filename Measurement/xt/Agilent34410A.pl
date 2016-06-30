#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
use utf8;
use lib qw(../lib);
use Data::Dumper;
use Test::More;

use Lab::Measurement;
use Scalar::Util qw(looks_like_number);

use TestLib;

my $function;

my $multimeter = Instrument('Agilent34410A', {
	connection_type => get_gpib_connection_type(),
	gpib_address => 17});

#reset
$multimeter->set_function('volt:ac');
$multimeter->reset();
$function = $multimeter->get_function();
is($function, 'VOLT', 'function is VOLT after reset');


# get_value

my $value = $multimeter->get_value();
ok(looks_like_number($value), "get_value");

# set_function / get_function

$multimeter->set_function('volt:ac');
$function = $multimeter->get_function();
is($function, 'VOLT:AC', 'function changed to volt:ac');
$multimeter->set_function('VOLT');
# get_function

# print Dumper $multimeter->device_cache();
# $multimeter->reset_device_cache();
# print Dumper $multimeter->device_cache();

$function = $multimeter->get_function();
is($function, 'VOLT', 'get_function returns VOLT');
$function = $multimeter->get_function({read_mode => 'cache'});
is($function, 'VOLT', 'cached get_function returns VOLT');

# in list context FIXME: list commit hash

my @function = $multimeter->get_function();
is($function[0], 'VOLT', 'get_function returns VOLT');
$function = $multimeter->get_function({read_mode => 'cache'});
is($function, 'VOLT', 'cached get_function returns VOLT');


# set_range / get_range
sub range_test {
	for my $array_ref (@_) {
		my $value = $array_ref->[0];
		my $expected = $array_ref->[1];
		
		$multimeter->set_range($value);
		my $result = $multimeter->get_range();
		ok($expected == $result,
		   "set_range($value) result: $result");
	}
}

#fixme: def min max are broken??
range_test([0.1, 0.1], [1, 1], [1000,1000], ['def', 10], ['min', 0.1],
	   ['max', 1000]);

# in current mode
$multimeter->set_function('current');
range_test([1, 1],[3, 3]);

# autoranging
$multimeter->set_range('auto');
my $autorange = $multimeter->get_autorange();
is($autorange, 1, "autorange");

# disable autoranging
$multimeter->set_range('1');
$autorange = $multimeter->get_autorange();
is($autorange, 0, "autorange off");


# set_nplc / get_nplc
$multimeter->set_function('volt');
$multimeter->set_nplc(2);
my $nplc = $multimeter->get_nplc();
ok ($nplc == 2, "nplc");

# # get_resolution / set_resolution

# $multimeter->set_resolution(2);
# my $resolution = $multimeter->get_resolution();
# ok ($resolution == 2, "resolution $resolution");

# get_tc / set_tc

$multimeter->set_tc(0.5);
my $tc = $multimeter->get_tc();
ok(relative_error($tc, 0.5) < 0.0001, "tc");


# get_bw / set_bw
$multimeter->set_function('volt:ac');
$multimeter->set_bw(200);
my $bw = $multimeter->get_bw();
ok($bw == 200, "$bw");


done_testing();
