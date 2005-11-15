#!/usr/bin/perl

use strict;
use Pod::Find qw(pod_find);

my %pods=pod_find({},"Instrument/blib/lib","VISA/blib/lib","Tools/blib/lib");
for (keys %pods) {
    print "$_ - $pods{$_}\n";
}
