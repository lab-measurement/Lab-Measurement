package Lab::Connection::VICP::Trace;
#ABSTRACT: ???

use v5.20;

use warnings;
use strict;

use parent 'Lab::Connection::VICP';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Trace';

1;

