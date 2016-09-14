#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use Perl::Tidy;
use File::Find;

my @files;

if (@ARGV) {
    @files = @ARGV;
}
else {
    find(
        {
            wanted => sub {
                my $file = $_;
                if ( $file =~ /\.(pm|t|pl)$/ ) {
                    push @files, $file;
                }
            },
            no_chdir => 1,
        },
        'lib',
        't',
        'xt'
    );
}

perltidy( perltidyrc => 'perltidyrc', argv => [ '-b', '-bext=/', @files ], );

