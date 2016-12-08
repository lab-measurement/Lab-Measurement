#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/is_float is_absolute_error is_relative_error/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;

use File::Spec::Functions 'catfile';
my $log_file = catfile(qw/t Moose Instrument SR830.yml/);

my $lia = mock_instrument(
    type     => 'SR830',
    log_file => $log_file,
);

isa_ok( $lia, 'Lab::Moose::Instrument::SR830' );

$lia->rst( timeout => 10 );

my @values;

# Get X, Y, R, phi
my $xy = $lia->get_xy( timeout => 3 );
is_absolute_error( $xy->{x}, 0, 0.001, "X is almost zero" );
is_absolute_error( $xy->{y}, 0, 0.001, "Y is almost zero" );

my $rphi = $lia->get_rphi();
is_absolute_error( $rphi->{r},   0, 0.001, "R is almost zero" );
is_absolute_error( $rphi->{phi}, 0, 180,   "phi is in [-180,180]" );

sub set_get_test {
    my ( $func, $value ) = validated_list(
        \@_,
        func  => { isa => 'Str' },
        value => { isa => 'Num' },
    );
    my $setter = "set_$func";
    my $getter = "get_$func";
    my $cached = "cached_$func";

    $lia->$setter( value => $value );
    is_float( $lia->$cached(), $value, "cached $func is $value" );
    is_float( $lia->$getter(), $value, "$getter returns $value" );
}

# Set/Get reference frequency
for my $freq (qw/1 10 1000 100000/) {
    set_get_test( func => "freq", value => $freq );
}

# Amplitude

for my $ampl (qw/0.004 1 2 3 5/) {
    set_get_test( func => "amplitude", value => $ampl );
}

# Phase

for my $phase (qw/-179 90 0 45 90 179/) {
    set_get_test( func => "phase", value => $phase );
}

# Set/Get time constant.
for my $tc (qw/1e-5 3e-5 1e-4 1 10 30/) {
    set_get_test( func => "tc", value => $tc );
}

# Set/Get sensitivity.
for my $sens (qw/1 0.5 0.2 0.1 0.05 1e-5 2e-5 5e-5/) {
    set_get_test( func => "sens", value => $sens );
}

$lia->rst();
done_testing();
