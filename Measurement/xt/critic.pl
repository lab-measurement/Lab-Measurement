#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
use Test::More;
use Test::Perl::Critic;
use File::Spec::Functions qw/catfile/;
use File::Find;

my @tests = map qr/$_/i, (
    qw/
        moose
        connection.*(log|mock)
        sr830::aux
        /
);

my @files;

find(
    {
        wanted => sub {
            my $file = $_;
            for my $test (@tests) {
                if ( $file !~ /\.(pm|pl|t)$/ ) {
                    return;
                }

                if ( $file =~ $test ) {
                    push @files, $file;
                    return;
                }
            }
        },
        no_chdir => 1,
    },
    'lib'
);

find(
    {
        wanted => sub {
            my $file = $_;
            for my $test (@tests) {
                if ( $file =~ /\.(pm|pl|t)$/ ) {
                    push @files, $file;
                    return;
                }
            }
        },
        no_chdir => 1,
    },
    't'
);

push @files, catfile(qw/xt critic.pl/), catfile(qw/xt perltidy.pl/);
for my $file (@files) {
    critic_ok($file);
}

done_testing();
