#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/scpi_set_get_test/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use File::Spec::Functions 'catfile';
use Data::Dumper;

my $log_file = catfile(qw/t Moose Instrument HP34410A.yml/);

my $dmm = mock_instrument(
    type     => 'HP34410A',
    log_file => $log_file,
);

# Test getters and setters

scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_function',
    values => [qw/VOLT CURR/],
);

scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_range',
    values => [ 0.1, 1, 10, 100, 1000 ]
);

scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_nplc',
    values => [ 0.006, 0.02, 0.06, 0.2, 1, 2, 10, 100 ],
);

$dmm->rst();
done_testing();
