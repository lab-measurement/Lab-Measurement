package Moose::Instrument::MockTest;
use 5.010;
use warnings;
use strict;

use Exporter 'import';

use Getopt::Long qw/:config gnu_compat/;
use YAML::XS;
use Carp;
use Module::Load;
use MooseX::Params::Validate;
use Lab::Moose;
use Data::Dumper;

our @EXPORT_OK = qw/mock_instrument/;

my $connection_module;
my $connection_options = '{}';

use Lab::Moose::Connection::Mock;

GetOptions(
    'connection|c=s'         => \$connection_module,
    'connection-options|o=s' => \$connection_options,
);

sub mock_instrument {
    my ( $type, $logfile ) = validated_list(
        \@_,
        type     => { isa => 'Str' },
        log_file => { isa => 'Str' }
    );

    if ( not defined $connection_module ) {
        return instrument(
            type               => $type,
            connection_type    => 'Mock',
            connection_options => { log_file => $logfile },
        );
    }

    load($connection_module);

    my $hash = Load($connection_options);
    if ( ref $hash ne 'HASH' ) {
        croak "argument of --connection-options not a hash";
    }

    return instrument(
        type               => $type,
        connection_type    => $connection_module,
        connection_options => $connection_options,
        instrument_options => { log_file => $logfile }
    );
}

1;
