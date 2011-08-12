#!/usr/bin/perl -w
# POD

package Lab::Instrument::SCPI::Agilent33220A;

use strict;

use Lab::Instrument::SCPI;

our @ISA = qw( Lab::Instrument::SCPI );
our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

# new inherited from SCPI package


sub loadWaveform {
        my $self = shift;
        my @waveform = @_;
        my $i;
        
        $self->Write(":DATA VOLATILE, ".join(', ',@waveform));
        $self->WriteConfig(  'FUNCtion:USER' => 'VOLATILE',
                             'FUNCtion:SHAPe'=> 'USER'
                          );
                       
}


sub enableOutput {
	my $self = shift;
	$self->WriteConfig( 'OUTPut' => 'ON' );
}




sub disableOutput {
	my $self = shift;
	$self->WriteConfig('OUTPut' => 'OFF' );
}

sub setLoad {
	my $self = shift;
	my $value = shift;
	$self->WriteConfig('OUTPut:LOAD' => $value);
}



sub setFrequency {
	my $self = shift;
	my $freq = shift;
        # add Hz if missing
	$freq .= 'Hz' unless ($freq =~ /[Hh]z$/);
	# send it
	$self->WriteConfig('FREQuency' => $freq );

}



sub setAmplitude {
	my $self = shift;
	my $freq = shift;
	$self->WriteConfig('Voltage' => $freq );

}


sub busTrigger {
        my $self = shift;
        my $wait = 0;
        $wait = shift if (@_ > 0);

        $self->Write("*TRG");
        $self->Write("*WAI") if ($wait);
}

1;

=pod

=head1 NAME

Lab::Instrument::SCPI::Agilent33220A

=head1 SYNOPSIS

 my $hp22 =  Lab::Instrument::SCPI::Agilent33220A( Interface => 'TCPIP',
                                                   PeerAddr  => 'cs025' ); # SICL interface via LAN to port 5025
 print $hp22->Query('*IDN?');
 $hp22->WriteConfig( 'VOLTAGE' => { 'HIGH' => 1.5,
                                    'LOW'  => 0.5 },
                      'BURST'        => { 'MODE' => 'TRIG',
                                          'NCYCLES' => 1,
                                          'INTERNAL:PERIOD' => '100ms',
                                          'STATE'  => 'ON',
                                          'SOURCE' => 'INT',
                                          'PHASE'  => 0 },
                     'TRIGGER:SOURCE' => 'IMM'
                         );

=head1 DESCRIPTION

C<Lab::Instrument::SCPI::Agilent33220A> is a control package for the Agilent 33220A arbitary waveform generator. 

=head1 CONSTRUCTOR

=head2 new

The same as for C<Lab::Instrument::SCPI>

=head1 METHODS

Inherited from C<Lab::Instrument::SCPI>.

=head2 loadWaveform

Load wavefrom data to the AWG. 

Call: $obj->loadWavefrom(@ARRAY)

@ARRAY is an array of values between -1 and +1

=head2 enableOutput

Enable output

=head2 disableOutput

Disable output

=head2 setLoad

Sets the output resistance. The parameter is a resistance value in Ohm or [INFinity|MINimum|MAXimum]

=head2 setFrequeny

Sets the output frequency

=head2 setAmplitude

Sets the output amplitude

=head2 busTrigger

Sends a trigger pulse via GPIB/LAN. Used to send only single pulses.

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=item L<Lab::Instrument::SCPI>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2010      Matthias Voelker <mvoelker@cpan.org>     

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut


