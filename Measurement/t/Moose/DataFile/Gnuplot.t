#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => ['file_ok'];
use File::Temp qw/tempdir/;
use Test::File;
use File::Spec::Functions qw/catfile/;
use Lab::Moose;
use aliased 'Lab::Moose::BlockData';

my $dir = tempdir( CLEANUP => 1 );
my $folder = datafolder( path => catfile( $dir, 'gnuplot' ) );
my $file = datafile(
    type     => 'Gnuplot',
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
$block
    = BlockData->new( matrix => [ [ 1, 2, 3 ], [ 4, 5, 6 ], [ 7, 8, 9 ] ] );

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

done_testing();
