#!perl
use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test tests => 316, import => [qw/is_float is_absolute_error/];
use Test::More;
use Moose::Instrument::MockTest 'mock_instrument';
use File::Spec::Functions 'catfile';

my $log_file = catfile(qw/t Moose Instrument RS_FSV.yml/);

my $fsv = mock_instrument(
    type     => 'RS_FSV',
    log_file => $log_file
);

isa_ok( $fsv, 'Lab::Moose::Instrument::RS_FSV' );

$fsv->rst( timeout => 10 );

$fsv->sense_sweep_points( value => 101 );

for my $i ( 1 .. 3 ) {
    my $data = $fsv->get_spectrum( timeout => 10 );

    my $num_cols = $data->columns();
    is( $num_cols, 2, "matrix has 2 columns" );

    my $num_rows = $data->rows();
    is( $num_rows, 101, "matrix has 3 rows" );

    my $freqs = $data->column(0);
    is_float( $freqs->[0],  0,   "sweep starts at 0 Hz" );
    is_float( $freqs->[-1], 7e9, "sweep stops at 7GHZ" );
    $data = $data->column(1);
    for my $num ( @{$data} ) {
        is_absolute_error(
            $num, -50, 50,
            "real or imaginary part of s-param is in [-100, 0]"
        );
    }
}

