#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Getopt::Long qw/:config gnu_getopt/;

my $start_id = 0;
my $diff;

GetOptions(
    "start|s=i" => \$start_id,
    "diff|d=i"  => \$diff,
) or die "GetOptions";

my $filename = $ARGV[0] // die "Need filename arg";
if ( not defined $diff ) {
    die "Need diff arg";
}

open my $fh, '<', $filename
    or die "Cannot open $filename: $!";

while ( my $line = <$fh> ) {
    if ( $line =~ /id: ([0-9]+)/ ) {
        my $id = $1;
        if ( $id >= $start_id ) {
            $id += $diff;
            $line =~ s/id: [0-9]+/id: $id/;
        }
    }
    print $line;
}

