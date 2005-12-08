#!/usr/bin/perl

use strict;
use PDL;
use PDL::Graphics::TriD;

my @cols=rcols $ARGV[0];

my $piddle=pdl [@cols];
#print $piddle;
print $piddle->getndims();
points3d [@cols];
