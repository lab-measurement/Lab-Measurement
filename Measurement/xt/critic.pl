#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
use Test::More tests => 36;
use Test::Perl::Critic;
use File::Spec::Functions qw/catfile/;
use File::Find;

my @tests = map qr/$_/i, (qw/
moose
connection.*(log|mock)
sr830::aux
/);

my @files;

# Add library files.
find({
    wanted => sub {
	my $file = $_;
	for my $test (@tests) {
	    if ($file !~ /\.pm$/) {
		return;
	    }
	    
	    if ($file =~ $test) {
		push @files, $file;
		return;
	    }
	}
    },
    no_chdir => 1,
     }, 'lib');

# Add test files
find({
    wanted => sub {
	my $file = $_;
	$file =~ /\.(t|pm)$/ and push @files, $_;
    },
    no_chdir => 1,
     }, 't');

# Add self.

push @files, __FILE__;     

for my $file (@files) {
    critic_ok($file);
}

