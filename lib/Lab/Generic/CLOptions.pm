package Lab::Generic::CLOptions;
#ABSTRACT: Global command line option processing

use Getopt::Long qw/:config pass_through/;

our $DEBUG        = 0;
our $IO_INTERFACE = undef;

GetOptions(
    "debug|d"      => \$DEBUG,
    "terminal|t=s" => \$IO_INTERFACE
) or die "error in CLOptions";

1;
