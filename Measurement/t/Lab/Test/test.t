#!perl -T

use warnings;
use strict;
use 5.010;

use lib 't';
use Test::Tester tests => 64;
use Lab::Test;

# is_relative_error
check_test(
    sub {is_relative_error(10, 11, 0.1, "is_relative_error")},
    {
	ok => 1,
	name => "is_relative_error",
    });

check_test(
    sub {is_relative_error(10, 11, 0.09, "is_relative_error")},
    {
	ok => 0,
	name => "is_relative_error",
	diag => "relative error of 10 and 11 is greater than 0.09"
    });

# is_num
check_test(
    sub {is_num(0.01, 0.01, "is_num")},
    {
	ok => 1,
	name => "is_num",
    });

check_test(
    sub {is_num(10, 11, "is_num")},
    {
	ok => 0,
	name => "is_num",
    });


# is_float
check_test(
    sub {is_float(1, 1.000000000000001, "is_float")},
    {
	ok => 1,
	name => "is_float",
    });

check_test(
    sub {is_float(1, 1.00001, "is_float")},
    {
	ok => 0,
	name => "is_float",
	diag => "relative error of 1 and 1.00001 is greater than 1e-14"
    });


# is_absolute_error
check_test(
    sub {is_absolute_error(10, 11, 2, "is_absolute_error")},
    {
	ok => 1,
	name => "is_absolute_error",
    });

check_test(
    sub {is_absolute_error(10, 11, 0.99, "is_absolute_error")},
    {
	ok => 0,
	name => "is_absolute_error",
	diag => "absolute error of 10 and 11 is greater than 0.99"
    });

# looks_like_number_ok
check_test(
    sub {looks_like_number_ok("10", "looks_like_number_ok")},
    {
	ok => 1,
	name => "looks_like_number_ok",
    });

check_test(
    sub {looks_like_number_ok("e10", "looks_like_number_ok")},
    {
	ok => 0,
	name => "looks_like_number_ok",
	diag => "'e10' does not look like a number"
    });





