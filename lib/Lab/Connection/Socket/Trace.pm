package Lab::Connection::Socket::Trace;
#ABSTRACT: ???

use v5.20;

use warnings;
use strict;

use parent 'Lab::Connection::Socket';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Trace';

1;

