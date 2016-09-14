
=head1 NAME

Lab::Test -- Shared test routines for Lab::Measurement.

=head1 SYNOPSIS

 use Lab::Test tests => 5;

 is_relative_error(10, 11, 0.2, "relative error of 10 and 11 is smaller than 20 percent");
 
 is_num(0.7, 0.7, "numbers are equal");
 
 is_float(1, 1.000000000000001, "floating point numbers are almost equal");
 
 is_absolute_error(10, 11, 2, "absolute error of 10 and 11 is smaller than 2");

 looks_like_number_ok("100e2", "'100e2' looks like a number");

=head1 DESCRIPTION

Collection of testing routines. This module can be used together with other
L<Test::Builder>-based modules like L<Test::More>.

=cut

package Lab::Test;
use 5.010;
use warnings;
use strict;
use Scalar::Util qw/looks_like_number/;

use parent 'Test::Builder::Module';

our @EXPORT = qw/
    is_relative_error
    is_num
    is_float
    is_absolute_error
    looks_like_number_ok
    /;

my $class = __PACKAGE__;

my $DBL_MIN = 2.2250738585072014e-308;

sub round_to_dbl_min {
    my $x = shift;
    return abs($x) < $DBL_MIN ? $DBL_MIN : $x;
}

sub relative_error {
    my $a = shift;
    my $b = shift;

    # Avoid division by zero.
    $a = round_to_dbl_min($a);
    $b = round_to_dbl_min($b);

    return abs( ( $b - $a ) / $b );
}

=head1 Functions

All of the following functions are exported by default.

=head2 is_relative_error($got, $expect, $error, $name)

Succeed if the relative error between C<$got> and C<$expect> is smaller or
equal than C<$error>. Relative error is defined as
C<abs(($got - $expect) / $expect)>.

If the absolute value of C<$got> or C<$expect> is smaller than DBL_MIN, that
number replaced with DBL_MIN before computing the relative error. This is done
to avoid division by zero. Two denormals will always compare equal.

=cut

sub is_relative_error {
    my ( $got, $expect, $error, $name ) = @_;
    my $tb = $class->builder;
    my $test = relative_error( $got, $expect ) <= $error;
    return $tb->ok( $test, $name )
        || $tb->diag(
        "relative error is greater than $error.\n",
        "Got: ", sprintf( "%.17g", $got ),
        "\n", "Expected: ", sprintf( "%.17g", $expect )
        );
}

=head2 is_num($got, $expect, $name)

Check for C<$got == $expect>. This is unlike C<Test::More::is>, which tests for C<$got eq $expect>.

=cut

sub is_num {
    my ( $got, $expect, $name ) = @_;
    my $tb = $class->builder;
    return $tb->ok( $got == $expect, $name )
        || $tb->diag(
        "Numbers not equal.\n",
        "Got: ", sprintf( "%.17g", $got ),
        "\n", "Expected: ", sprintf( "%.17g", $expect )
        );
}

=head2 is_float($got, $expect, $name)

Compare floating point numbers.

Equivalent to C<is_relative_error($got, $expect, 1e-14, $name)>.

C<1e-14> is about 100 times bigger than DBL_EPSILON. 
The test will succeed even if the numbers are tainted by multiple rounding
operations.  

=cut

sub is_float {
    my ( $got, $expect, $name ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_relative_error( $got, $expect, 1e-14, $name );
}

=head2 is_abs_error($got, $expect, $error, $name)

Similar to C<is_relative_error>, but uses the absolute error.

=cut

sub is_absolute_error {
    my ( $got, $expect, $error, $name ) = @_;
    my $tb   = $class->builder;
    my $test = abs( $got - $expect ) <= $error;
    return $tb->ok( $test, $name )
        || $tb->diag(
        "absolute error of $got and $expect is greater than $error");
}

=head2 looks_like_number_ok($number, $name)

Checks if Scalar::Util's C<looks_like_number> returns true for C<$number>.

=cut

sub looks_like_number_ok {
    my ( $number, $name ) = @_;
    my $tb = $class->builder;
    return $tb->ok( looks_like_number($number), $name )
        || $tb->diag("'$number' does not look like a number");
}

1;

