#!perl

# Run this test after presetting the VNA.
use warnings;
use strict;
use 5.010;

use lib 't';

use PDL::Ufunc qw/any all/;

use Lab::Test import => [qw/is_absolute_error is_pdl/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
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

done_testing();
