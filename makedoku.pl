#!/usr/bin/perl

use strict;
use YAML;
use Documentation::LaTeX;
use Documentation::HTML;
use Data::Dumper;
$Data::Dumper::Indent = 1;

open YAML, "<", 'dokutoc.yml' || die "Can't open toc: $!\n";
my $yml = join "", <YAML>;
close YAML;
my $dokudef = Load($yml);
#print Dumper($dokudef);

my $docdir = "Homepage/docs";
my $tempdir = "Homepage/temp";

my $processor = ($ARGV[0] =~ /html/) ? new Documentation::HTML($docdir, $tempdir) : new Documentation::LaTeX($docdir, $tempdir);   

$processor->process($dokudef);
