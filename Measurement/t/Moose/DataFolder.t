#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => ['file_ok'];
use File::Temp qw/tempdir/;
use Test::File;
use File::Path 'remove_tree';
use File::Spec::Functions qw/catfile/;
use YAML::XS 'LoadFile';
use Lab::Moose;
use aliased 'Lab::Moose::BlockData';

my $dir = tempdir( CLEANUP => 1 );

# Check numbering
my $name = catfile( $dir, 'abc def' );
{
    for ( 1 .. 9 ) {
        datafolder( path => $name );
    }

    # Check transistion 999 => 1000

    mkdir( catfile( $dir, 'abc def_990' ) )
        or die "mkdir failed";

    for ( 1 .. 19 ) {
        datafolder( path => $name );
    }

    my @entries = get_dir_entries($dir);

    is( @entries, 29, "created 28 folders" );
    for my $entry (@entries) {
        like(
            $entry, qr/^abc def_(00[1-9]|99[0-9]|100[0-9])$/,
            "correct numbering"
        );
    }
}

# Check meta file and copy of script.
{
    my $folder = datafolder( path => $name );
    say "path: ", $folder->path();
    my $folder_name = 'abc def_1010';
    is( $folder->path(), catfile( $dir, $folder_name ) );
    isa_ok( $folder->meta_file, 'Lab::Moose::DataFile::Meta' );

    my $meta_file = $folder->meta_file();
    my $meta      = $meta_file->path();
    is( $meta, catfile( $dir, $folder_name, 'META.yml' ) );

    my $contents = LoadFile($meta);

    my @expected = qw/argv user host date timestamp version/;
    hashref_contains( $contents, @expected );

    # Log some more.
    $meta_file->log( meta => { abc => '123', def => '345' } );
    $contents = LoadFile($meta);
    hashref_contains( $contents, @expected, qw/abc def/ );

    file_exists_ok( catfile( $folder->path, 'DataFolder.t' ) );
}

# Create folder in working directory.
{
    # Set script_name, so that the copy does not end with '.t' and is confused
    # as a test.
    my $folder = datafolder( script_name => 'script' );
    isa_ok( $folder, 'Lab::Moose::DataFolder' );
    my $path = $folder->path();
    is( $path, 'MEAS_001', "default folder name" );
    file_exists_ok( catfile( $path, 'META.yml' ) );
    file_exists_ok( catfile( $path, 'script' ) );
    remove_tree($path);
}

# Gnuplot data file.
{
    my $folder = datafolder( path => catfile( $dir, 'gnuplot' ) );
    my $file = datafile(
        folder   => $folder,
        filename => 'file.dat',
        columns  => [qw/A B C/]
    );
    my $path = $file->path();
    $file->log( A => 1, B => 2, C => 3 );
    $file->log_newline();
    $file->log_comment( comment => 'YOLO' );
    $file->log( A => 2, B => 3, C => 4 );

    my $expected = <<"EOF";
# A\tB\tC
1\t2\t3

# YOLO
2\t3\t4
EOF
    file_ok( $path, $expected, "gnuplot file log method" );

    # log block

    my $block = BlockData->new( matrix => [ [ 10, 20 ], [ 30, 40 ] ] );

    $file->log_block(
        prefix => { A => 1 },
        block  => $block
    );
    $expected .= <<"EOF";
1\t10\t20
1\t30\t40

EOF
    file_ok( $path, $expected, "log_block method" );

    # log_block without prefix
    $block = BlockData->new(
        matrix => [ [ 1, 2, 3 ], [ 4, 5, 6 ], [ 7, 8, 9 ] ] );

    $file->log_block(
        block       => $block,
        add_newline => 0
    );

    $expected .= <<"EOF";
1\t2\t3
4\t5\t6
7\t8\t9
EOF
    file_ok( $path, $expected, "log_block without prefix" );

}

sub get_dir_entries {
    my $dir = shift;
    opendir my $dh, $dir
        or die "cannot open $dir: $!";

    my @entries = readdir $dh;
    @entries = grep { $_ ne '.' and $_ ne '..' } @entries;
    return @entries;
}

sub hashref_contains {
    my $hashref = shift;
    my @keys    = @_;
    for my $key (@keys) {
        ok( exists $hashref->{$key}, "hashref contains '$key'" );
    }
}

done_testing();
