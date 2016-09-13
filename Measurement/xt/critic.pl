#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
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
                if ( $file !~ /\.pm$/ ) {
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

for my $file (@files) {
    critic_ok($file);
}

all_critic_ok(qw(t xt/critic.pl xt/critic-progressive.pl));
