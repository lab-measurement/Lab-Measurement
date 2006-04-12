#!/usr/bin/perl

# example4.pl

use strict;
use Lab::Instrument::HP34401A;

my $gpib=24;            # we want to open the instrument
my $board=0;            # with GPIB address 24
                        # connected to GPIB board 0 in our computer

# Create an instrument object
my $hp=new Lab::Instrument::HP34401A($board,$gpib);

# Use the id method to query the instruments ID string
my $result=$hp->id();

print $result;

__END__
