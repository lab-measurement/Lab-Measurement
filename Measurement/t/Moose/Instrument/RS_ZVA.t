#!perl

# Run this test after presetting the VNA.
use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test tests => 29, import => [qw/is_float is_absolute_error/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use File::Spec::Functions 'catfile';

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

    my $num_cols = $data->columns();
    is( $num_cols, 3, "matrix has 3 columns" );

    my $num_rows = $data->rows();
    is( $num_rows, 3, "matrix has 3 rows" );

    my $freqs = $data->column(0);
    is_deeply(
        $freqs, [ 10000000, 12005000000, 24000000000 ],
        "first column holds frequencies"
    );
    my $re = $data->column(1);
    my $im = $data->column(2);
    for my $num ( @{$re}, @{$im} ) {
        is_absolute_error(
            $num, 0, 1,
            "real or imaginary part of s-param is in [-1,1]"
        );
    }
}

