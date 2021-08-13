package Lab::Moose::Instrument::ABB_TRMC2;
#ABSTRACT: ABB TRMC2 temperature controller

use v5.20;

use Moose;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;

extends 'Lab::Moose::Instrument';

has max_setpoint => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosNum',
    default => 1
);

has min_setpoint => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosNum',
    default => 0.02
);

#my $TRMC2_LSP = 0.02;                           #Lower Setpoint Limit
#my $TRMC2_HSP = 1;                              #Upper Setpoint Limit

has read_delay => (
    is      => 'ro', 
    isa     => 'Num', 
    default => 0.3
);
# my $WAIT    = 0.3;    #sec. waiting time for each reading;

my $mounted = 0;      # Ist sie schon mal angemeldet

my $buffin
    = "C:\\Program Files\\Trmc2\\buffin.txt";    # Hierhin gehen die Befehle
my $buffout
    = "C:\\Program Files\\Trmc2\\buffout.txt";  # Hierher kommen die Antworten

=head1 SYNOPSIS

 use Lab::Moose;
 
 my $trmc = instrument(
      type => 'ABB_TRMC2'
 );
 
 my $temp = $trmc->get_T();

Warning: Due to the rather unique (and silly) way of device communication, the 
TRMC2 driver does not use the connection layer.
 
=cut
    

sub TRMC2init {

    # Checks input and output buffer for TRMC2 commands
    my $self = shift;
    if ( $mounted == 1 ) { die "TRMC already Initialized\n" }

    # Test file communication
    if ( !open FHIN, "<", $buffin ) {
        die "could not open command file $buffin: $!\n";
    }
    close(FHIN);
    if ( !open FHOUT, "<", $buffout ) {
        die "could not open reply file $buffout: $!\n";
    }
    close(FHOUT);

    #sleep($WAIT);
    $mounted = 1;
}

sub TRMC2off {

    # "Unmounts" the TRMC
    $mounted = 0;
}

sub TRMC2_Heater_Control_On {

    # Switch the Heater Control (The coupling heater and set point NOT the heater switch in the main menu)
    # 1 On
    # 0 Off
    my $self  = shift;
    my $state = shift;
    if ( $state != 0 && $state != 1 ) {
        die
            "TRMC heater control can be turned off or on by 0 and 1 not by $state\n";
    }
    my $cmd = sprintf( "MAIN:ON=%d\0", $state );
    TRMC2_Write( $cmd, 0.3 );
}

sub TRMC2_Prog_On {
    my $self  = shift;
    my $state = shift;
    if ( $state != 0 && $state != 1 ) {
        die "TRMC Program can be turned off or on by 0 and 1 not by $state\n";
    }
    my $cmd = sprintf( "MAIN:PROG=%d\0", $state );
    TRMC2_Write( $cmd, 1.0 );
}

sub TRMC2_get_SetPoint {
    my $cmd = sprintf("MAIN:SP?");
    my @value = TRMC2_Query( $cmd, 0.1 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return $value[0];
}

=head2 set_T

 $trmc->set_T(value => 0.1);

Program the TRMC to regulate the temperature towards a specific value (in K).
The function returns immediately; this means that the target temperature most
likely has not been reached yet.

Possible values are in the range [min_setpoint, max_setpoint], by default
[0.02, 1.0].

=cut

sub set_T {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    $self->TRMC2_set_SetPoint($value);

    # what do we need to return here?
    #return TRMC2_set_SetPoint(@_);
}

sub TRMC2_set_SetPoint {
    my $self = shift;
    my $Setpoint = shift;

    if ( $value > $self->max_setpoint ) {
        croak "setting temperatures above $self->max_setpoint K is forbidden\n";
    }
    if ( $value < $self->min_setpoint ) {
        croak "setting temperatures below $self->max_setpoint K is forbidden\n";
    }

    my $FrSetpoint = MakeFrenchComma( sprintf( "%.6E", $Setpoint ) );

    my $cmd = "MAIN:SP=$FrSetpoint";
    $self->TRMC2_Write( $cmd, 0.2 );
}

=head2 TRMC2_get_PV

What does this do?

=cut

sub TRMC2_get_PV {
    my $self = shift;

    my $cmd = "MAIN:PV?";
    my @value = $self->TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return $value[0];
}

=head2 TRMC2_AllMeas

Read out all sensor channels.

=cut

sub TRMC2_AllMeas {
    my $self = shift;

    my $cmd = "ALLMEAS?";
    my @value = $self->TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }

    return @value;
}

=head2 TRMC2_get_T

 my $t = $trmc->TRMC2_get_T($channel);

Reads out temperature of a sensor channel.

Sensor number:
 1 Heater
 2 Output
 3 Sample
 4 Still
 5 Mixing Chamber
 6 Cernox

=cut

sub TRMC2_get_T {
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }
    my $cmd = "ALLMEAS?";
    my @value = TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }

    my @sensorval = split( /;/, $value[$sensor] );
    my $T = $sensorval[1];
    return $T;
}

=head2 TRMC2_get_R

  my $r = $trmc->TRMC2_get_R($channel);

Reads out resistance of a sensor channel.

Sensor number:
 1 Heater
 2 Output
 3 Sample
 4 Still
 5 Mixing Chamber
 6 Cernox

=cut

sub TRMC2_get_R {
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }

    my $cmd = "ALLMEAS?";
    my @value = $self->TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    my @sensorval = split( /;/, $value[$sensor] );
    my $R = $sensorval[0];
    return $R;
}

=head2 TRMC2_get_RT

  my ($r, $t) = $trmc->TRMC2_get_RT();

Reads out resistance and temperature simultaneously. 

Sensor number: 
 1 Heater
 2 Output
 3 Sample
 4 Still
 5 Mixing Chamber
 6 Cernox

=cut

sub TRMC2_get_RT
{
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }
    my $cmd = sprintf("ALLMEAS?");
    my @value = $self->TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    my @sensorval = split( /;/, $value[$sensor] );
    my $R         = $sensorval[0];
    my $T         = $sensorval[1];
    return ( $R, $T );
}


=head2 TRMC2_Read_Prog

Reads Heater Batch Job

=cut 

sub TRMC2_Read_Prog {
    my $self  = shift;

    my $cmd   = "MAIN:PROG_Table?\0";
    my @value = $self->TRMC2_Query( $cmd, 0.2 );
    
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;
}

=head2 TRMC2_Set_T_Sweep

 $trmc->TRMC2_Set_T_Sweep(SetPoint, Sweeprate, Holdtime)
 
Programs the built in temperature sweep. After Activation it will sweep from the 
current temperature to the set temperature with the given sweeprate. The Sweep 
can be started with TRMC2_Start_Sweep(1).

Variables: SetPoint in K, Sweeprate in K/Min, Holdtime in s (defaults to 0)

=cut

sub TRMC2_Set_T_Sweep {
    my $arg_cnt = @_;

    my $self      = shift;
    my $Setpoint  = shift;    #K
    my $Sweeprate = shift;    #K/min
    my $Holdtime  = 0.;       #sec.
    if ( $arg_cnt == 4 ) { $Holdtime = shift }
    my $FrSetpoint  = MakeFrenchComma( sprintf( "%.6E", $Setpoint ) );
    my $FrSweeprate = MakeFrenchComma( sprintf( "%.6E", $Sweeprate ) );
    my $FrHoldtime  = MakeFrenchComma( sprintf( "%.6E", $Holdtime ) );

    my $cmd = "MAIN:PROG_Table=1\0";
    $self->TRMC2_Write( $cmd, 0.5 );
    
    $cmd = sprintf(
        "PROG_TABLE(%d)=%s;%s;%s\n",
        0, $FrSetpoint, $FrSweeprate, $FrHoldtime
    );
    $self->TRMC2_Write( $cmd, 0.5 );
}

=head2 TRMC2_Start_Sweep

 $trmc->TRMC2_Start_Sweep(1);

Starts (1) / stops (0) the sweep --- provided the heater in TRMC2 window is 
turned ON. At a sweep stop the power is left on.

=cut

sub TRMC2_Start_Sweep
    my $self  = shift;
    my $state = shift;

    if ( $state != 0 && $state != 1 ) {
        die "Sweep can be turned off or on by 0 and 1 not by $state\n";
    }
    if ( $state == 1 ) { $self->TRMC2_Heater_Control_On($state); }
    $self->TRMC2_Prog_On($state);
}

=head2 TRMC2_All_Channels

Reads out all channels and values and returns an array

=cut

sub TRMC2_All_Channels {
    my $self = shift;

    my $cmd = "*CHANNEL";
    my @value = $self->TRMC2_Query( $cmd, 0.1 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;
}

=head2 TRMC2_Active_Channel

Reads out the active channel (?)

=cut

sub TRMC2_Active_Channel {
    my $self = shift;

    my $cmd = "CHANNEL?";
    my @value = $self->TRMC2_Query( $cmd, $WAIT );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;
}

=head2 TRMC2_Shut_Down

Stops the sweep and the heater control

=cut 

sub TRMC2_Shut_Down {
    my $self = shift;

    $self->TRMC2_Start_Sweep(0);
    $self->TRMC2_Heater_Control_On(0);
}

=head2 TRMC2_Write

 TRMC2_Write($cmd, $wait_write=$WAIT)

Sends a command to the TRMC and will wait $wait_write.

=cut 

sub TRMC2_Write {
    my $self = shift;

    my $arg_cnt    = @_;
    my $cmd        = shift;
    my $wait_write = $WAIT;
    if ( $arg_cnt == 2 ) { $wait_write = shift }
    if ( !open FHIN, ">$buffin" ) {
        die "could not open command file $buffin: $!\n";
    }

    printf FHIN $cmd;
    close(FHIN);

    sleep($wait_write);
}

=head2 TRMC2_Query

 TRMC2_Query($cmd, $wait_query=$WAIT)

Sends a command to the TRMC and will wait $wait_query sec long and returns the 
result.

=cut

sub TRMC2_Query {
    my $self = shift;

    my $arg_cnt = @_;

    my $cmd        = shift;
    my $wait_query = $WAIT;
    if ( $arg_cnt == 2 ) { $wait_query = shift }

    #----Open Command File---------
    if ( !open FHIN, ">$buffin" ) {
        die "could not open command file $buffin: $!\n";
    }

    printf FHIN $cmd;
    close(FHIN);
    #-----------End Of Setting Command-----------
    sleep($wait_query);

    #--------Reading Value----------------------
    if ( !open FHOUT, "<$buffout" ) {
        die "could not open reply file $buffout: $!\n";
    }
    my @line = <FHOUT>;
    close(FHOUT);

    return @line;
}

=head2 RemoveFrenchComma

Replace "," in a number with "." (yay for French hardware!)

=cut 

sub RemoveFrenchComma {
    my $value = shift;
    $value =~ s/,/./g;
    return $value;
}

=head2 MakeFrenchComma

Replace "." in a number with "," (yay for French hardware!)

=cut 

sub MakeFrenchComma {
    my $value = shift;
    $value =~ s/\./,/g;
    return $value;
}

