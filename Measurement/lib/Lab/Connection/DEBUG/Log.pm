package Lab::Connection::DEBUG::Log;
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::DEBUG';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    log_file => undef,
    );

with 'Lab::Connection::Log';

1;
    
