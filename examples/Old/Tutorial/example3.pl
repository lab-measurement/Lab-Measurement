#!/usr/bin/perl

# example3.pl

use strict;
use Lab::Instrument;

# Open instrument
my $instr=new Lab::Instrument({
    GPIB_board      => 0,
    GPIB_address    => 10
});

# Send a bunch of commands to configure instrument
for ((
# Protect the DUT
    ':OUTP:CENT OFF',       #disconnect channels

# Set up the Instrument
    ':FUNC PATT',           #set mode to Pulse/Pattern
    ':PER 20 ns',           #set period to 20 ns

# Set up Channel 1
    ':FUNC:MODE1 PULSE',    #set pattern mode to Pulse
    ':WIDT1 5 ns',          #set width to 5 ns
    ':VOLT1:AMPL 2.000 V',  #set ampl to 2 V
    ':VOLT1:OFFSET 1.5 V',  #set offset to 1.5 V
    ':OUTP1:POS ON',        #enable output channel 1

# Generate the Signals
    ':OUTP:CENT ON',        #reconnect the channels
    ':OUTP0:SOUR PER',      #use trigger mode Pulse
    ':OUTP0 ON',            #enable trigger output
)) {
    $self->{vi}->Write($_);
}

__END__
