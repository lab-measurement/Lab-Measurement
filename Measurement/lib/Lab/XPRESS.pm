package Lab::XPRESS;
our $VERSION = '3.30';

use Exporter 'import';
use Lab::XPRESS::hub qw(DataFile Sweep Frame Instrument Connection);
use strict;

our @EXPORT = qw(DataFile Sweep Frame Instrument Connection);
