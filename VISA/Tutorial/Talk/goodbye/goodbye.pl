#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;

my $gpib=21;            # we want to open the instrument
my $board=0;            # with GPIB address 21
                        # connected to GPIB board 0 in our computer

# Create an instrument object
my $hp=new Lab::Instrument::HP34401A($board,$gpib);

$hp->scroll_message(uc'           Thank you for your attention'x10);
