# Process Command Line Options (i.e. flag -d | -debug):
package Lab::Generic::CLOptions;

our $VERSION='3.515';

use Getopt::Long;

our $DEBUG = 0;
our $IO_INTERFACE = undef;

GetOptions( "debug|d" => \$DEBUG,
            "terminal|t=s" => \$IO_INTERFACE);
