#!/usr/bin/perl

use strict;
use Lab::Instrument::SR780;

my $sr780=new Lab::Instrument::SR780(0,10);

$sr780->send_commands(configure(102400,1000));
$sr780->start_measurement();
while (1000 != $sr780->average_status('A')) {
    sleep(1);
}
$sr780->pause_measurement();
my @data=$sr780->read_data_pairs('A');
for (@data) {
    print (join "\t",@$_),"\n";
}
$sr780->play(3);

sub configure {
    my ($freq,$avg)=@_;
    
    return (
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
        "FSPN 0,$freq",#Span            102.4 kHz
        'FSTR 0,0',#    Start Freq      0 Hz
        'FLIN 0,3',#    Lines           800
        'FWIN 0,0',#    Window          Uniform
        'FWFL 0,100',#  Force           100%
        'FWTC 0,50',#   Expo            50%

        #Average Display A
        'FAVG 0,1',#    Average         On
        'FAVM 0,1',#    Mode            RMS
        'FAVT 0,1',#    Type            Exponential
        "FAVN 0,$avg",# Number          1000
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
    );
}

