#!perl

# Do not connect anything to the input ports when running this!!!

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import =>
    [qw/is_float is_absolute_error is_relative_error set_get_test/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use Moose::Instrument::SpectrumAnalyzerTest qw/test_spectrum_analyzer/;

use File::Spec::Functions 'catfile';
my $log_file = catfile(qw/t Moose Instrument HP8596E.yml/);

my $inst = mock_instrument(
    type     => 'HP8596E',
    log_file => $log_file,
);

isa_ok( $inst, 'Lab::Moose::Instrument::HP8596E' );

is_absolute_error( $inst->get_Xpoints_number(), 401, .01, "built-in number of points in a trace");

# generic tests for any Spectrum analyzer.
test_spectrum_analyzer( SpectrumAnalyzer => $inst );

done_testing();

