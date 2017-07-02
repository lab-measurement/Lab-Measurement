package Lab::Measurement;
#Dist::Zilla: +PodWeaver
#ABSTRACT: Log, describe and plot data on the fly

use strict;
use warnings;
use Lab::Generic;

use Exporter 'import';
use Lab::XPRESS::hub qw(DataFile Sweep Frame Instrument Connection);
our @EXPORT = qw(DataFile Sweep Frame Instrument Connection);

1;

__END__

=encoding utf8

=head1 SYNOPSIS

  use Lab::Measurement;
  

=head1 DESCRIPTION

This module distribution simplifies the task of running a measurement, writing 
the data to disk and keeping track of necessary meta information that usually 
later you don't find in your lab book anymore.

If your measurements don't come out nice, it's not because you were using the 
wrong software. 

The entire stack can be loaded by a simple 

  use Lab::Measurement;

command; further required modules will be imported on demand.

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS>

=item L<http://www.labmeasurement.de>

=back

=cut
