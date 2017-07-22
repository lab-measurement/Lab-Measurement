package Lab::Connection::USBtmc::Trace;
#Dist::Zilla: +PodWeaver
#ABSTRACT: ???

use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::USBtmc';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Trace';

1;

