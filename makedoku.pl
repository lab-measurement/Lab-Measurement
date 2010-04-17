#!/usr/bin/perl

use strict;
use YAML qw(LoadFile);
use Documentation::LaTeX;
use Documentation::HTML;
use Data::Dumper;
$Data::Dumper::Indent = 1;

my $dokudef = LoadFile('dokutoc.yaml');
#print Dumper($dokudef);

my $docdir = "Homepage/docs";
my $tempdir = "Homepage/temp";

my $processor = ($ARGV[0] =~ /html/) ? new Documentation::HTML($docdir, $tempdir) : new Documentation::LaTeX($docdir, $tempdir);   

$processor->process($dokudef);
