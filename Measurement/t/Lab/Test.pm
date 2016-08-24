=head1 NAME

Lab::Test -- Shared test routines for Lab::Measurement.

=head1 SYNOPSIS

 use Lab::Test;
 use Test::More tests => 4;

 is_relative_error(10, 11, 0.2, "relative error of 10 and 11 is smaller than 20 percent");
 
 is_num(0.7, 0.7, "numbers are equal");
 
 is_float(1, 1.000000000000001, "floating point numbers are almost equal");
 
 is_absolute_error(10, 11, 2, "absolute error of 10 and 11 is smaller than 2");

=head1 DESCRIPTION

Collection of testing routines. This module can be used together with other
L<Test::Builder> based modules like L<Test::More>.

=cut

package Lab::Test;
use 5.010;
use warnings;
use strict;

use parent 'Test::Builder::Module';

our @EXPORT = qw/
is_relative_error
is_float
is_absolute_error
/;

my $class = __PACKAGE__;


sub relative_error {
    my $a = shift;
    my $b = shift;
    return abs(($b - $a) / $b);
}

=head1 Functions

All of the following functions are exported by default.

=head2 is_relative_error($got, $expect, $error, $name)

Succeed if the relative error between C<$got> and C<$expect> is smaller or
equal than C<$error>.

=cut

sub is_relative_error {
    my ($got, $expect, $error, $name) = @_;
    my $tb = $class->builder;
    my $test = relative_error($got, $expect) <= $error;
    return $tb->ok($test, $name) ||
	$tb->diag("relative error of $got and $expect is greater than $error");
}



=head2 is_num($got, $expect, $name)

Check for C<$got == $expect>. This is unlike C<Test::More::is>, which tests for C<$got eq $expect>.

=cut

sub is_num {
    my ($got, $expect, $name) = @_;
    my $tb = $class->builder;
    return $tb->is_num($got, $expect, $name);
}

=head2 is_float($got, $expect, $name)

Equivalent to C<is_relative_error($got, $expect, 1e-14, $name)>.

C<1e-14> is about 100 times bigger than the double-precision machine epsilon.

This way, you can use this function to compare floating point numbers, which
are tainted by multiple rounding operations.

=cut

sub is_float {
    my ($got, $expect, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_relative_error($got, $expect, 1e-14, $name);
}

=head2 abs_error_is($got, $expect, $error, $name)

Similar to C<relative_error_is>, but uses the absolute error.

=cut

sub is_absolute_error {
    my ($got, $expect, $error, $name) = @_;
    my $tb = $class->builder;
    my $test = abs($got - $expect) <= $error;
    return $tb->ok($test, $name) ||
	$tb->diag("absolute error of $got and $expect is greater than $error");
}

1;
    
