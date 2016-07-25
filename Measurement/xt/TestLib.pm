package TestLib;

use 5.010;
use warnings;
use strict;

use Getopt::Long;
use Exporter 'import';

our @EXPORT = qw/get_gpib_connection_type relative_error float_equal/;

my $use_mock;
my $print_help;

GetOptions(
    'mock|m' => \$use_mock,
    'help|h' => \$print_help,
    )
    or die "Error in GetOptions";


sub get_gpib_connection_type {
    if ($use_mock) {
	return 'Mock';
    }
    
    my $connection;
    if ( $^O eq 'MSWin32' ) {
        $connection = 'VISA_GPIB';
    }
    else {
        $connection = 'LinuxGPIB';
    }

    return $connection . '::Log';
}

sub relative_error {
    my $a = shift;
    my $b = shift;
    return abs( ( $b - $a ) / $b );
}

sub float_equal {
    my $a = shift;
    my $b = shift;

    # 1e-14 is about 100 times bigger than the machine epsilon.
    return ( relative_error( $a, $b ) < 1e-14 );
}
