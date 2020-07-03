package Lab::Connection::LinuxGPIB::Log;
#ABSTRACT: Add logging capability to the LinuxGPIB connection

use v5.20;

use warnings;
use strict;

use parent 'Lab::Connection::LinuxGPIB';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Log';

1;

