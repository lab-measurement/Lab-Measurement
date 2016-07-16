package Lab::Connection::LinuxGPIB::Log;
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::LinuxGPIB';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    log_file => undef,
    log_index => 0,
    );

with 'Lab::Connection::Log';

1;
    
