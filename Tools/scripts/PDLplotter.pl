#!/usr/bin/perl

use strict;
use TSKTools;
use PDL;
use PDL::Graphics::TriD;

my $a=TSKTools::TSKload('lade_rawdata/lade_');
imag3d[$a->slice("(0),:,:"),$a->slice("(1),:,:"),$a->slice("(2),:,:")],{Lines=>0};
