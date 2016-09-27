#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
use File::Spec::Functions qw/catfile abs2rel/;

# Do nothing during rebase.
my $branch = qx/git rev-parse --abbrev-ref HEAD/;
if ( $branch eq '(no branch)' ) {
    exit 0;
}

chdir catfile(qw/. Measurement/)
    or die "cannot chdir";

delete $ENV{GIT_DIR};

#
# Perltidy
#

my @files = split '\n', qx/git diff --cached --name-only/;

@files = grep {/\.(pm|pl|t)$/} @files;

@files = map { abs2rel( $_, 'Measurement' ) } @files;

# Run this after abs2rel.
@files = grep {-f} @files;

my $tidy_script = catfile(qw/xt perltidy.pl/);

if (@files) {
    say "running perltidy on the following files:";
    say "    $_" for @files;
    safe_system( $tidy_script, @files );
}

for my $file (@files) {
    safe_system( 'git', 'add', $file );
}

#
# Run tests.
#

safe_system(qw/prove -lrv t/);

#
# Run Perl::Critic tests.
#

safe_system( 'prove', '-j4', catfile(qw/xt critic/) );

sub safe_system {
    my @command = @_;
    warn "running command: @command\n";
    system(@command);
    if ( $? == -1 ) {
        die "failed to execute: $!\n";
    }
    if ( $? & 127 ) {
        die sprintf( 'child died with signal %d', ( $? & 127 ) );
    }

    my $status = $? >> 8;
    if ($status) {
        die "command '@command' exited with status $status";
    }
}

