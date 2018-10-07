package Lab::Moose::DataFile::Gnuplot::Compressed;

#ABSTRACT: Text based data file ('Gnuplot style'), auto-compressed

use 5.010;
use warnings;
use strict;

use Moose;
use IO::Compress::Bzip2;
use File::Basename qw/dirname basename/;
use Lab::Moose::Catfile 'our_catfile';
use Carp;

extends 'Lab::Moose::DataFile::Gnuplot';

has compression => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Bzip2',
);

sub _open_file {
    my $self = shift;

    my $folder   = $self->folder->path();
    my $filename = $self->filename();

    my $dirname = dirname($filename);
    my $dirpath = our_catfile( $folder, $dirname );

    if ( not -e $dirpath ) {
        make_path($dirpath)
            or croak "cannot make directory '$dirname'";
    }

    my $path = our_catfile( $folder, $filename );

    $self->_path($path);

    if ( -e $path ) {
        croak "path '$path' does already exist";
    }

    my $fh = new IO::Compress::Bzip2 $path
        or croak "cannot open '$path': $!";

    binmode $fh
        or croak "cannot set binmode for '$path'";

    if ( $self->autoflush() ) {
        $fh->autoflush();
    }

    $self->_filehandle($fh);
}

sub add_plot {
   croak("Compressed data files do not (yet) support plots.");
}

sub refresh_plots {
}

1;
