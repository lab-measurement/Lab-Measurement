#!/usr/bin/perl -w
# POD

package Lab::Instrument::SCPI::AgilentMSO;

use strict;
use Lab::Instrument::SCPI;
use Time::HiRes qw (usleep sleep);

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);
our @ISA = qw( Lab::Instrument::SCPI );

sub new {
	my $object = shift;
    my $self = $object->SUPER::new(@_);
    $self->{'query_cnt'} = 'all' if (defined $self);
   	return $self;
}

# readout waveform
sub getWaveform {
        my $self = shift;
        my %args;
        %args = @_ if (@_ > 0);

        # default config
        my %confData = ( 'SOURCE' => 'CHANNEL1',
                         'POINTS' => 'RAW',
                         'POINTS:MODE' => 'RAW',
                         'FORMAT' => 'ASCII' );

        # copy from args if exists but don't create new entries
        foreach (keys %args) {
            $confData{uc($_)} = $args{$_} if (exists($confData{uc($_)}));
        }

        # stay compatible with old format
        $confData{'POINTS:MODE'} = $args{'pointsMode'} if (exists $args{'pointsMode'});  
        
        # send config to scope
        $self->WriteConfig(  'WAVEFORM' => \%confData );

        if (exists $args{'timeout'}) {

            my $timeout = $args{'timeout'};
            my $status = $self->Query(':OPERegister:CONDition?');
            # wait until ready
            while (($timeout > 0) and not(($status & 0x08) == 0)) {
                $status = $self->Query(':OPERegister:CONDition?');
                $timeout -= 0.1;
                sleep(0.1);
            }
            if($timeout <= 0) {
                # stop trigger
                $self->Write(':STOP');
                # go back without result
                return undef;
            }
        } 
        # request data
        $self->Write(":WAVEFORM:DATA?");
        
        if ($confData{'FORMAT'} eq 'ASCII') {
            my @data = split(/,/,$self->Read('all'));
        
            # separate info block        
            my $digits = substr($data[0],1,1);
            my $validBlock=substr($data[0],2,$digits);
            $data[0]=substr($data[0],2+$digits);

            # give back
            return \@data;
        }
        # if not ascii -> give all back
        return $self->Read('all');
}

sub saveData {
	my $self = shift;
    return $self->Write(":SINGLE");
}

sub getData {
	my $self = shift;
	$self->saveData;
	return $self->getWaveform(@_);
}

sub autoScale {
	my $self = shift;
	return $self->Write(":AUTOSCALE");
}


# everything  fine

return 1;

=pod

=head1 NAME

Lab::Instrument::SCPI::AgilentMSO

=head1 SYNOPSIS

 my $hp22 =  Lab::Instrument::SCPI::AgilentMSO( Interface => 'TCPIP',
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

 my $data=$hp22->getWaveform( SOURCE => 'CHANNEL1', 
                              timeout => 0.1 ); # 100 ms

=head1 DESCRIPTION

C<Lab::Instrument::SCPI::AgilentMSO> is a control package for the Agilent Mixed Signal Scopes. Tested with
6000 series.

=head1 CONSTRUCTOR

=head2 new

The same as for C<Lab::Instrument::SCPI>

=head1 METHODS

Inherited from C<Lab::Instrument::SCPI>.

=head2 autoScale

Same as the autoscale button

=head2 getWaveform

Read waveform for instrument. 
Possible options: 
        FORMAT => ASCII|BYTE|WORD     (default: ASCII)
        POINTS => <number>|MAX|RAW    (default: RAW)
        SOURCE => e.g. CHANNEL1       (default: CHANNEL1)
        POINTS:MODE => MAX|RAW|NORMAL (default: RAW)
        timeout => <seconds to wait for timeout> (default: undef)

=head2 saveData

Same as single shot

=head2 getData

Same as single shot followed by a getWaveform.

=head1 CAVEATS/BUGS

Older HP scopes does not support the waveform format ASCII. Use the wrapper a package around this one if needed.

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





