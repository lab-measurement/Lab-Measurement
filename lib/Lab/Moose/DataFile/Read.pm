package Lab::Moose::DataFile::Read;

#ABSTRACT: Read a gnuplot-style 2D data file

use 5.010;
use warnings;
use strict;
use MooseX::Params::Validate 'validated_list';
use PDL::Lite;
use PDL::Basic 'transpose';
use PDL::IO::Misc 'rcols';
use File::Slurper 'read_binary';
use List::Util qw/max any/;
use Fcntl 'SEEK_SET';
use Carp;
use Exporter 'import';

our @EXPORT = qw/read_2d_gnuplot_format read_3d_gnuplot_format/;

sub read_2d_gnuplot_format {
    my ( $fh, $file ) = validated_list(
        \@_,
        fh   => { isa => 'FileHandle', optional => 1 },
        file => { isa => 'Str',        optional => 1 }
    );

    if ( !( $fh || $file ) ) {
        croak "read_2d_gnuplot_format needs either 'fh' or 'file' argument";
    }

    if ( !$fh ) {
        open $fh, '<', $file
            or croak "cannot open file $file: $!";
    }

    # Rewind filehandle.
    seek $fh, 0, SEEK_SET
        or croak "cannot seek: $!";

    # Read data into array of PDLs
    my @columns = rcols( $fh, { EXCLUDE => '/^(#|\s*$)/' } );
    if ( not @columns ) {
        croak "cannot read: $!";
    }

    return \@columns;
}

# 3D gnuplot data file (two x values, three y value):
# x11 y11 z11
# x12 y12 z12
# x13 y13 z13
#
# x21 y21 z21
# x22 y22 z22
# x23 y23 z23
#
# x-cordinate changes with each block: x11, x12 and x13 will be equal in
# most cases (exception: sweep of B-field or temperature where they will be
# almost equal.
#
# Parse into three 2x3 piddles for x, y and z data
# (first piddle dim (x) goes to the right):

# x11 x21
# x12 x22
# x13 x23

# y11 y21
# y12 y22
# y13 y23

# and same for z

sub read_3d_gnuplot_format {
    my ($file) = validated_list(
        \@_,
        file => { isa => 'Str' }
    );

    my $data = read_binary($file);

    # Remove comment lines
    $data =~ s/^#.*\n//mg;

    # Split into blocks
    my @blocks = split /^\s*\n/m, $data;

    if ( !@blocks ) {
        croak "no blocks in datafile";
    }

    my @pdl_blocks;
    for my $block (@blocks) {
        open my $fh, '<', \$block
            or croak "cannot open data block: $!";
        my $pdl = rcols( $fh, [] );
        $pdl = transpose($pdl);
        push @pdl_blocks, $pdl;
        close $fh
            or croak "cannot close: $!";
    }

    if ( !@pdl_blocks ) {
        croak "no data blocks found";
    }

    my @dims     = $pdl_blocks[0]->dims();
    my $num_cols = $dims[0];
    my @num_rows = map { ( $_->dims() )[1] } @pdl_blocks;
    my @num_cols = map { ( $_->dims() )[0] } @pdl_blocks;
    if ( any { $_ != $num_cols } @num_cols ) {
        croak "unequal column numbers in datafile blocks";
    }

    my $max_rows = max(@num_rows);

    # We can only glue pdls with compatible shape.
    # Insert NaNs if a block contains fewer than $max_rows lines.

    for my $i ( 0 .. $#pdl_blocks ) {
        my $num_rows = $num_rows[$i];
        if ( $num_rows == $max_rows ) {
            next;
        }
        $pdl_blocks[$i]->reshape( $num_cols, $max_rows );
        my $row_range = "$num_rows:-1";
        $pdl_blocks[$i]->slice(":,$row_range") .= "NaN";
    }

    #say for @pdl_blocks;
    my @col_pdls;
    for my $col ( 0 .. $num_cols - 1 ) {
        my @cols = map { $_->slice("$col,:") } @pdl_blocks;
        $col_pdls[$col] = PDL::glue( 0, @cols );
    }

    return @col_pdls;
}
1;
