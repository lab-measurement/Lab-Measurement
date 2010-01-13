#$Id$

package Lab::Instrument::Agilent81134A;

use strict;
use Lab::Instrument;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self
}

sub clock_example {
    my $self=shift;
    
    my @cmd=(
    #Protect the DUT
        ':OUTP:CENT OFF',       #disconnect channels

    #Set up the Instrument
        ':FUNC PATT',           #set mode to Pulse/Pattern
        ':FREQ 200 MHz',        #set freq to 200 MHz

    #Set up Channel 1
        ':FUNC:MODE1 SQU',      #set pattern mode to Square
        ':VOLT1:HIGH 1.000 V',  #set high-Level to 1 V
        ':VOLT1:LOW 0 V',       #set low-level to 0 V
        ':OUTP1:POS ON',        #enable output channel 1

    #Set up Channel 2
        ':FUNC:MODE2 SQU',      #set pattern mode to Square
        ':OUTP2:DIV 2',         #set freq div to 2
        ':VOLT2:HIGH 1.000 V',  #set the high-Level to 1 V
        ':VOLT2:LOW 0 V',       #set low-level to 0 V
        ':OUTP2:POS ON',        #enable output channel 2

    #Generate the Signals
        ':OUTP:CENT ON',        #reconnect the channels
        ':OUTP0 ON',            #enable trigger output
    );
    for (@cmd) {
        $self->{vi}->Write($_);
    }
}

sub pulse_example {
    my $self=shift;
    
    my @cmd=(
    #Protect the DUT
        ':OUTP:CENT OFF',       #disconnect channels

    #Set up the Instrument
        ':FUNC PATT',           #set mode to Pulse/Pattern
        ':PER 20 ns',           #set period to 20 ns

    #Set up Channel 1
        ':FUNC:MODE1 PULSE',    #set pattern mode to Pulse
        ':WIDT1 5 ns',          #set width to 5 ns
        ':VOLT1:AMPL 2.000 V',  #set ampl to 2 V
        ':VOLT1:OFFSET 1.5 V',  #set offset to 1.5 V
        ':OUTP1:POS ON',        #enable output channel 1

    #Generate the Signals
        ':OUTP:CENT ON',        #reconnect the channels
        ':OUTP0:SOUR PER',      #use trigger mode Pulse
        ':OUTP0 ON',            #enable trigger output
    );
    for (@cmd) {
        $self->{vi}->Write($_);
    }
}

1;

=head1 NAME

Lab::Instrument::Agilent81134A - Agilent 81134A pulse generator

=head1 SYNOPSIS

    use Lab::Instrument::Agilent81134A;

    my $a=new Lab::Instrument::Agilent81134A(0,22);

=head1 DESCRIPTION

The Lab::Instrument::Agilent81134A class will provide an interface to the Agilent 81134A pulse generator. 
Right now, only two small example methods are provided.

=head1 CONSTRUCTOR

    my $a=new(\%options);

=head1 METHODS

To be written.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2005 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
