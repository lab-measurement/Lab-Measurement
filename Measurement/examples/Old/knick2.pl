#!/usr/bin/perl

use strict;
use Lab::Instrument::KnickS252;
use Time::HiRes qw/usleep/;

my $knick=new Lab::Instrument::KnickS252({GPIB_board=>0,GPIB_address=>15});

for (0..1000) {
    $knick->set_voltage($_/1000);
#    usleep(100);
}
