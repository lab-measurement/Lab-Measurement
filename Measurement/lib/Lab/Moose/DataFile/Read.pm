package Lab::Moose::DataFile::Read;
use 5.010;
use Moose::Role;
use MooseX::Params::Validate;
use PDL::IO::Misc 'rcols';
use Fcntl 'SEEK_SET';
use Carp;

our $VERSION = '3.520';

sub read_2d_gnuplot_format {
    my $self = shift;
    my ($fh) = validated_list(
        \@_,
        fh => { isa => 'FileHandle' },
    );

    # Rewind filehandle.
    seek $fh, 0, SEEK_SET
        or croak "cannot seek";

    # Read data into array of PDLs
    my @columns = rcols( $fh, { EXCLUDE => '/^(#|\s*$)/' } );
    if ( not @columns ) {
        croak "cannot read: $!";
    }

    return \@columns;
}

1;
