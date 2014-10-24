# Process Command Line Options (i.e. flag -d | -debug):
package Lab::Generic::CLOptions;

our $VERSION='3.40';

use Getopt::Long;

our $DEBUG = 0;

GetOptions("debug|d" => \$DEBUG);
