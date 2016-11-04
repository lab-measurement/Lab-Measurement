# Handle to replace STDERR (routes messages on STDERR to ERROR channel):
package Lab::GenericIO::STDerrHandle;

our $VERSION = '3.531';

use Symbol qw<geniosym>;

use parent 'Tie::Handle';

sub TIEHANDLE { return bless geniosym, __PACKAGE__ }

sub PRINT {
    $DB::single = 1;

    shift;
    my $string = join( "", @_ );

    Lab::GenericIO::channel_write( "ERROR", undef, $string );
}

sub PRINTF {

    shift;
    my $format = shift;

    my $string = sprintf "$format", @_;

    Lab::GenericIO::channel_write( "ERROR", undef, $string );
}

1;
