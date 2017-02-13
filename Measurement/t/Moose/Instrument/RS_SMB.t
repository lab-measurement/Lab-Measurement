#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/set_get_test/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use File::Spec::Functions 'catfile';
use Data::Dumper;

my $log_file = catfile(qw/t Moose Instrument RS_SMB.yml/);

my $smb = mock_instrument(
    type     => 'RS_SMB',
    log_file => $log_file,
);

# Test getters and setters
sub local_set_get_test {
    my ( $func, $values, $is_numeric ) = validated_list(
        \@_,
        func       => { isa => 'Str' },
        values     => { isa => 'ArrayRef[Str]' },
        is_numeric => { isa => 'Bool', default => 1 },
    );

    set_get_test(
        instr      => $smb,        getter => "${func}_query",
        setter     => "$func",     cache  => "cached_$func",
        is_numeric => $is_numeric, values => $values
    );
}

# Frequency

local_set_get_test(
    func   => 'sense_power_frequency',
    values => [qw/1e4 1e6 1.1e9/],
);

# Power (Dbm)
local_set_get_test(
    func   => 'source_power_level_immediate_amplitude',
    values => [qw/10 -10 -20/],
);

$smb->rst();
done_testing();
