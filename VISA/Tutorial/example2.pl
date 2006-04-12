#!/usr/bin/perl

# example2.pl

use strict;
use Lab::Instrument;

my $gpib=24;            # we want to open the instrument
my $board=0;            # with GPIB address 24
                        # connected to GPIB board 0 in our computer

# Create an instrument object
my $instr=new Lab::Instrument($board,$gpib);

my $cmd="*IDN?";

# Query the instrument
# Query is a combined Write and Read
my $result=$instr->Query($cmd);

print $result;

__END__
