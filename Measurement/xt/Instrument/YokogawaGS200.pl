#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;


use lib qw(../ ../../lib);
use Test::More tests => 8;

use Lab::SCPI;

use Lab::Instrument::YokogawaGS200;

use Scalar::Util qw(looks_like_number);
use TestLib;

my $query;
my $yoko = Lab::Instrument::YokogawaGS200->new(
    connection_type => get_gpib_connection_type(),
    log_file => 'YokogawaGS200.yml',
    gpib_address => 2,
    gate_protect => 0,
    );

for my $function (qw/current voltage/) {
	$yoko->set_function($function);
	my $query = $yoko->get_function();
	ok(scpi_match($query, $function), "function set to $function");
}

# range
my @ranges = qw/10e-3 100e-3 1 10 30/;
my @return_ranges = @ranges;
    
for (my $i = 0; $i < @ranges; ++$i) {
	$yoko->set_range($ranges[$i]);
	my $query = $yoko->get_range();
	ok($query == $return_ranges[$i], "range: expected: " . $ranges[$i] . ", got: $query");
}

# level

my $level = 0.1234;

$yoko->set_range(1);
$yoko->set_level($level);
$query = $yoko->get_level();
ok($level == $query, "level set to $level");
