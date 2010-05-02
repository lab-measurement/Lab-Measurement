#!/usr/bin/perl

use strict;
use YAML;
use Documentation::LaTeX;
use Documentation::HTML;
use Documentation::Web;
use Data::Dumper;
$Data::Dumper::Indent = 1;

open YAML, "<", 'dokutoc.yml' || die "Can't open toc: $!\n";
my $yml = join "", <YAML>;
close YAML;
my $dokudef = Load($yml);
#print Dumper($dokudef);

my $docdir = "Homepage/docs";
my $tempdir = "Homepage/temp";
my $processor;

# the autoupdater calls with parameter "web"

for ($ARGV[0]) {
	if	(/html/)	{ $processor = new Documentation::HTML($docdir, $tempdir); }
	elsif	(/web/)		{ $processor = new Documentation::Web($docdir, $tempdir); }
	else			{ $processor = new Documentation::LaTeX($docdir, $tempdir); }
}

$processor->process($dokudef);
