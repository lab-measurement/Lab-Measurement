#!perl
use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test tests => 5;
use Test::More;
use Moose::Instrument::MockTest qw/mock_options/;
use aliased 'Lab::Moose::Instrument::RS_ZVM';
use File::Spec::Functions 'catfile';

my $logfile = catfile(qw/t Moose Instrument RS_ZVM.yml/);

my $zvm = RS_ZVM->new( mock_options($logfile) );

isa_ok( $zvm, RS_ZVM );

$zvm->rst( timeout => 10 );
my $catalog = $zvm->sparam_catalog();
is_deeply(
    $catalog, [ 'Re(S11)', 'Im(S11)' ],
    "reflection param in catalog"
);

$zvm->sense_sweep_points( value => 3 );

for my $i ( 1 .. 3 ) {
    my $data = $zvm->sparam_sweep( timeout => 10 );
    my @freqs = $data->column(0);
    is_deeply( \@freqs, [ 10000000, 10005000000, 20000000000 ] );
}

