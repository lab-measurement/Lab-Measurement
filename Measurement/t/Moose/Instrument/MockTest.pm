package Moose::Instrument::MockTest;
use 5.010;
use warnings;
use strict;

use Exporter 'import';

use Getopt::Long qw/:config gnu_compat/;
use YAML::XS;
use Carp;
use Module::Load;
use Data::Dumper;

our @EXPORT_OK = qw/mock_options/;

my $connection_module;
my $connection_options = '{}';

GetOptions(
    'connection|c=s'         => \$connection_module,
    'connection-options|o=s' => \$connection_options,
);

sub mock_options {
    my $logfile = shift;

    if ( not defined $connection_module ) {
        $connection_module = 'Lab::Moose::Connection::Mock';
        load $connection_module;
        return (
            connection => $connection_module->new( log_file => $logfile ) );
    }

    load($connection_module);

    my $hash = Load($connection_options);
    if ( ref $hash ne 'HASH' ) {
        croak "argument of --connection-options not a hash";
    }

    my $connection = $connection_module->new( %{$hash} );
    return ( connection => $connection, log_file => $logfile );
}

1;
