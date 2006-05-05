#!/usr/bin/perl

use strict;

use Lab::Instrument::SR780;
use Time::HiRes qw(usleep);

my $sr=new Lab::Instrument::SR780(0,10);

print $sr->id();

#$sr->play(2);

#print join "\n",$sr->read_display_data('A');

#$sr->play(3);

$sr->play_song();
