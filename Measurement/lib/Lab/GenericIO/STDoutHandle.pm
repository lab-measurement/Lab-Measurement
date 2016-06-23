# Handle to replace STDOUT (routes messages on STDOUT to MESSAGE channel):
package Lab::GenericIO::STDoutHandle;

our $VERSION='3.510';

use Symbol qw<geniosym>;

use base qw<Tie::Handle>;

sub TIEHANDLE { return bless geniosym, __PACKAGE__ }

sub PRINT {

	shift;
	my $string = join("", @_);

	Lab::GenericIO::channel_write("MESSAGE", undef, $string);
}

sub PRINTF {

	shift;
	my $format = shift;

	my $string = sprintf "$format", @_;

	Lab::GenericIO::channel_write("MESSAGE", undef, $string);
}

1;
