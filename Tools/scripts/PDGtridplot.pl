#!/usr/bin/perl

use strict;
use PDL;
use PDL::Graphics::TriD;

my $size = 50;
my $x = (xvals zeroes $size+1,$size+1) / $size;
my $y = (yvals zeroes $size+1,$size+1) / $size;
my $z = 0.5 + 0.5 * (sin($x*6.3) * sin($y*6.3)) ** 3;   # Bumps

my $piddle= pdl [$x,$y,$z];
#print $x,$y,$z;
imag3d [$x,$y,$z],{Lines=>0}; # Draw a shaded surface
