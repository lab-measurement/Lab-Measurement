#$Id$

package Lab::Instrument::SR780;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{vi}=new Lab::Instrument(@_);
    return $self
}

sub start_measurement {
    my $self=shift;
    $self->{vi}->Write('STRT');
}

sub pause_measurement {
    my $self=shift;
    $self->{vi}->Write('PAUS');
}

sub continue_measurement {
    my $self=shift;
    $self->{vi}->Write('CONT');
}

sub send_commands {
    my ($self,@commands)=@_;
    for (@commands) {
        $self->{vi}->Write($_);
    }
}

sub read_display_data {
    my ($self,$display)=@_;
    my $display=(ord(uc $display)-65) & 1;
    $self->{vi}->Write("DSPY? $display");
    my @res=split ",",$self->{vi}->Read(30000);
    return @res;
}

sub read_data_pairs {
    my ($self,$display)=@_;
    my $display=(ord(uc $display)-65) & 1;
    my $length=$self->{vi}->Query("DSPN? $display");
    my @pairs;
    for (0..$length-1) {
        my $freq=$self->{vi}->Query("DBIN? $display,$_");
        my $datum=$self->{vi}->Query("DSPY? $display,$_");
        push(@pairs,[$freq,$datum]);
    }
    return @pairs;
}

sub average_status {
    my ($self,$display)=@_;
    my $display=(ord(uc $display)-65) & 1;
    my $num=$self->{vi}->Query("NAVG? $display");
    return $num;
}

sub id {
    my $self=shift;
    $self->{vi}->Query('*IDN?');
}

sub tone {
    my ($self,$tone,$duration)=@_;
    $self->{vi}->Write("TONE $duration,$tone");
}

sub play {
    my ($self,$sound)=@_;
    $self->{vi}->Write("PLAY $sound");
}

sub play_song {
    my $self=shift;
    for (([4,20],[5,20],[6,20],[7,20],[8,40],[ 8,40],
          [9,20],[9,20],[9,20],[9,20],[8,40],[-1,20],
          [9,20],[9,20],[9,20],[9,20],[8,40],[-1,20],
          [7,20],[7,20],[7,20],[7,20],[6,40],[ 6,40],
          [5,20],[5,20],[5,20],[5,20],[4,40])) {
        $self->tone(@$_) if ($_->[0] > 0);
        usleep($_->[1]*15000);
    }
}
              
1;

=head1 NAME

Lab::Instrument::SR780 - Stanford Research SR780 Network Signal Analyzer

=head1 SYNOPSIS

    use Lab::Instrument::SR780;
    
    my $sr780=new Lab::Instrument::SR780(0,10);

    $sr780->send_commands(
        #INPUT CH1
        'ISRC 0',#      Source          Analog
        'I1MD 1',#      Mode            A-B
        'I1GD 1',#      Ground          Ground
        'I1CP 1',#      Coupling        AC
        'I1RG 1',#      Range           Auto
        'I1AF 1',#      AA Filter       On
        'I1AW 0',#      A-Wt Filter     Off
        'I1AR 0',#      Auto Range      Normal
        'IAOM 1',#      Auto Offset     On
        'EU1M 0',#      EU              Off
        'EU1L 1',#      EU Label        m/s
        'EU1V 1',#      EU/Volt         1 EU/V
        'EU1U EU',#     User Label      EU
        
        #Measure Display A
        'DISP 0,1',#    Display         Live
        'DFMT 0',#      Display         Single
        'ACTD 0',#      Active Display  0
        'MGRP 0,0',#    Measurement     FFT ch1
        'MEAS 0,0',#    Measurement     FFT1
        'VIEW 0,0',#    View            Log Mag
        'UNIT 0,1',#    Units           Vrms
        'PSDU 0,1',#    PSD             On
        'FBAS 0,1',#    Base Freq       102.4 kHz
        'FSPN 0,102400',#Span            102.4 kHz
        'FSTR 0,0',#    Start Freq      0 Hz
        'FLIN 0,3',#    Lines           800
        'FWIN 0,0',#    Window          Uniform
        'FWFL 0,100',#  Force           100%
        'FWTC 0,50',#   Expo            50%
    
        #Average Display A
        'FAVG 0,1',#    Average         On
        'FAVM 0,1',#    Mode            RMS
        'FAVT 0,1',#    Type            Exponential
        'FAVN 0,1000',# Number          1000
        'FOVL 0,100',#  Time Incr       100.00%
        'FREJ 0,0',#    Reject          Off
        'PAVO 0,0',#    Preview         Off
        'PAVT 0,2',#    Prv Time        2 s
    
        #Display Display A
        'XAXS 0,1',#    X Axis          Log
        'GRID 0,1',#    Grid            On
        'GDIV 0,1',#    Grid Div        10
        'TRRC 0,0',#    Xdcr Convert    Acceleration
        'DBMR 50',#     dBm Ref         50
        'PHSL 0,0',#    Phase Suppress  0.0000e+000
        'DDXW 0,0.5',#  d/dx Window     0.5
    ));
    
    $sr780->start_measurement();
    
    while (1000 != $sr780->average_status('A')) { sleep(1) }
    
    $sr780->pause_measurement();
    
    my @data=$sr780->read_data_pairs('A');
    for (@data) {
        print (join "\t",@$_),"\n";
    }
    
    $sr780->play(3);

=head1 DESCRIPTION

The Lab::Instrument::SR780 class implements an interface to the
Stanford Research SR780 Network Signal Analyzer.

=head1 CONSTRUCTOR

  $sr780=new Lab::Instrument::SR780($board,$gpib)

=head1 METHODS

=head2 start_measurement

  $sr780->start_measurement()

Starts the measurement. Any average in progress is reset
and started over. If the measurement is paused, starts the measurement
over. This method is the same as pressing the [Start/Reset] key.

=head2 pause_measurement

  $sr780->pause_measurement()

If the measurement is already in progress, pauses the measurement. If the measurement
is paused, it has no effect. This method is similar to pressing the [Pause/Cont] key.

=head2 continue_measurement

  $sr780->continue_measurement()

If the measurement is paused, continues the measurement.
If the measurement is running, it has no effect.
This method is similar to pressing the [Pause/Cont] key.

=head2 read_display_data

  @data=$sr780->read_display_data($display)

Returns a list of data from the given display ($display is either 'A' or 'B').

=head2 read_data_pairs

  @pairs=$sr780->read_data_pairs($display)

Reads the data of display C<$display>. The data is returned as a list of references to arrays with
a frequency,data pair.

=head2 average_status

  $num_avg=$sr780->average_status($display)

Returns the number of already completed averages for display C<$display>.

=head2 send_commands

  $sr780->send_commands(@commands)

Sends a list of commands to the instrument. Useful for mass configuration.

=head2 id

  $id=$sr780->id()

Returns the instruments ID string.

=head2 play

  $sr780->play($sound)

Plays the predefinded sound C<$sound> (between 0 and 6). 

=head2 tone

  $sr780->tone($tone,$duration)

Plays the note C<$tone> (between 0 and 66) on the internal speaker. The tone is played
for the time C<$duration>, which is in units of 5ms.

=head2 play_song

  $sr780->play_song()

Plays the song I<Alle meine Entchen> on the internal speaker of the SR780. While this might
not be especially useful for your measurements, it will guaranty you I<ubergeek> status among
the colleagues in your lab.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
