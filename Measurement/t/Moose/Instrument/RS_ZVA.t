#!perl

# Run this test after presetting the VNA.
use warnings;
use strict;
use 5.010;

use lib 't';

use PDL::Ufunc qw/any all/;

use Lab::Test import => [qw/is_absolute_error is_float is_pdl/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use File::Spec::Functions 'catfile';
use Data::Dumper;

my $log_file = catfile(qw/t Moose Instrument RS_ZVA.yml/);

my $zva = mock_instrument(
    type     => 'RS_ZVA',
    log_file => $log_file,
);

isa_ok( $zva, 'Lab::Moose::Instrument::RS_ZVA' );

$zva->rst();

my $catalog = $zva->sparam_catalog();
is_deeply(
    $catalog, [ 'Re(S21)', 'Im(S21)' ],
    "reflection param in catalog"
);

$zva->sense_sweep_points( value => 3 );

for my $i ( 1 .. 3 ) {
    my $data = $zva->sparam_sweep( timeout => 10 );

    is_deeply( [ $data->dims() ], [ 3, 3 ], "data PDL has dims 3 x 3" );

    my $freqs = $data->slice(":,0");

    is_pdl(
        $freqs, [ [ 10000000, 12005000000, 24000000000 ] ],
        "first column holds frequencies"
    );

    my $re = $data->slice(":,1");
    my $im = $data->slice(":,2");
    for my $pdl ( $re, $im ) {
        ok(
            all( abs($pdl) < 0.01 ),
            "real or imaginary part of s-param is in [-0.01, 0.01]"
        ) || diag("pdl: $pdl");
    }
}

# Test getters and setters

sub set_get_test {
    my ( $func, $value, $numeric ) = validated_list(
        \@_,
        func    => { isa => 'Str' },
        value   => { isa => 'Str' },
        numeric => { isa => 'Bool', default => 1 },
    );
    my $setter = "$func";
    my $getter = "${func}_query";
    my $cached = "cached_$func";

    $zva->$setter( value => $value );

    my $test_func = $numeric ? \&is_float : \&is;

    $test_func->( $zva->$cached(), $value, "cached $func is $value" );
    $test_func->( $zva->$getter(), $value, "$getter returns $value" );
}

# start/stop
for my $start (qw/1e7 1e8 1e9/) {
    set_get_test( func => 'sense_frequency_start', value => $start );
}

for my $stop (qw/2e7 3e8 4e9/) {
    set_get_test( func => 'sense_frequency_stop', value => $stop );
}

# number of points
for my $num (qw/1 10 100 60000/) {
    set_get_test( func => 'sense_sweep_points', value => $num );
}

# power
for my $power (qw/0 -10 -20/) {
    set_get_test(
        func  => 'source_power_level_immediate_amplitude',
        value => $power
    );
}

# if bandwidth
for my $bw (qw/1 100 1000/) {
    set_get_test(
        func  => 'sense_bandwidth_resolution',
        value => $bw
    );
}

# if bandwidth selectivity
for my $s (qw/HIGH NORM HIGH/) {
    set_get_test(
        func    => 'sense_bandwidth_resolution_select',
        numeric => 0,
        value   => $s
    );
}

$zva->rst();
done_testing();
