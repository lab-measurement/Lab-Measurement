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

=head1 SYNOPSIS

 use Lab::Moose;

 my $folder = datafolder();

 my $file = datafile(
     type => 'Gnuplot::Compressed',
     folder => $folder,
     filename => 'gnuplot-file.dat',
     columns => [qw/time voltage temp/]
     );

 $file->log(time => 1, voltage => 2, temp => 3);

=head1 METHODS

=head2 new

Supports the following attributes in addition to the 
L<Lab::Moose::DataFile::Gnuplot> requirements:

=over

=item * compression

Compression type; defaults to 'Bzip2' (which is also the only supported value 
right now).

=back

Note: this datafile type does not (yet) support any plots.

=cut

sub _modify_file_path {
    my $self = shift;
    my $path = shift;
    return "$path." . lc $self->compression();
}

sub _open_filehandle {
    my $self = shift;
    my $path = shift;
    my $fh   = new IO::Compress::Bzip2 $path
        or croak "cannot open '$path': $!";
    return $fh;
}

sub add_plot {
    croak("Compressed data files do not (yet) support plots.");
}

sub refresh_plots {
}

1;
