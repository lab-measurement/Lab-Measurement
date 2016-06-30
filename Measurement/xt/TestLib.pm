package TestLib;

use 5.010;
use warnings;
use strict;

use Exporter 'import';

our @EXPORT = qw/get_gpib_connection_type relative_error float_equal/;

sub get_gpib_connection_type {
	if ($^O eq 'MSWin32') {
		return 'VISA_GPIB';
	}
	else {
		return 'LinuxGPIB';
	}
}

sub relative_error {
	my $a = shift;
	my $b = shift;
	return abs(($b - $a) / $b);
}

sub float_equal {
	my $a = shift;
	my $b = shift;
	# 1e-15 is about 10 times bigger than the machine epsilon.
	return (relative_error($a, $b) < 1e-15);
}
