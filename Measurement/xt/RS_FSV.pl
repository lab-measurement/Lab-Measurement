#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib '../lib';

use Lab::Measurement;

use aliased 'Lab::Connection::LinuxGPIB' => 'GPIB';

use aliased 'Lab::Moose::Instrument::RS_FSV' => 'FSV';

my $fsv = FSV->new( connection => GPIB->new( gpib_address => 20 ) );

say $fsv->idn();

my $data = $fsv->get_spectrum( timeout => 10 );

$data->print_to_file( file => '/tmp/spectrum_avg=10', overwrite => 1 );
