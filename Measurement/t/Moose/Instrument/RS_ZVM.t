#!perl
use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test tests => 29, import => [qw/is_absolute_error/];
use Test::More;
use Moose::Instrument::MockTest 'mock_instrument';
use aliased 'Lab::Moose::Instrument::RS_ZVM';
use File::Spec::Functions 'catfile';

my $log_file = catfile(qw/t Moose Instrument RS_ZVM.yml/);

my $zvm = mock_instrument(
    type     => 'RS_ZVM',
    log_file => $log_file
);

isa_ok( $zvm, 'Lab::Moose::Instrument::RS_ZVM' );

$zvm->rst( timeout => 10 );
my $catalog = $zvm->sparam_catalog();
is_deeply(
    $catalog, [ 'Re(S11)', 'Im(S11)' ],
    "reflection param in catalog"
);

$zvm->sense_sweep_points( value => 3 );

for my $i ( 1 .. 3 ) {
    my $data = $zvm->sparam_sweep( timeout => 10 );

    my $num_cols = $data->columns();
    is( $num_cols, 3, "matrix has 3 columns" );

    my $num_rows = $data->rows();
    is( $num_rows, 3, "matrix has 3 rows" );

    my $freqs = $data->column(0);
    is_deeply(
        $freqs, [ 10000000, 10005000000, 20000000000 ],
        "first column holds frequencies"
    );
    my $re = $data->column(1);
    my $im = $data->column(2);
    for my $num ( @{$re}, @{$im} ) {
        is_absolute_error(
            $num, 0, 1.1,
            "real or imaginary part of s-param is in [-1.1,1.1]"
        );
    }
}

