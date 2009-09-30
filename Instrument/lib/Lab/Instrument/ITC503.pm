#$Id: ITC503.pm 571 2009-06-27 16:12:00Z Kalok $

package Lab::Instrument::ITC503;

use strict;
use Lab::VISA;
use Lab::Instrument;
#use Lab::Instrument::MagnetSupply;

our $VERSION = sprintf("0.%04d", q$Revision: 571 $ =~ / (\d+) /);


my $RuO2_Cernox=1.45; #K Sensor 3

#
#my $default_config={
#    #use_persistentmode          => 0,
#    #can_reverse                 => 1,
#    #can_use_negative_current    => 1,
#};

sub new {
    my $proto = shift;
    my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    printf "new ITC\n \n";
    printf "Defining ITC...";    
    $self->{vi}=new Lab::Instrument(@args);
    
    my $xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR, 0xD);
    if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while setting read termination character: $xstatus";}

    $xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_TRUE);
    if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while enabling read termination character: $xstatus";}
    
    printf "done\n";    
    return $self
}

##
##
##sub new {
##    my $proto = shift;
##    my @args=@_;
##    my $class = ref($proto) || $proto;
##    #my $self = $class->SUPER::new($default_config,@args);
##    #bless ($self, $class);
##
##    $self->{vi}=new Lab::Instrument(@args);
##    
##    my $xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR, 0xD);
##    if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while setting read termination character: $xstatus";}
##
##    $xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_TRUE);
##    if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while enabling read termination character: $xstatus";}
##
##    $self->{vi}->Clear();
##   
##    $self->ips_set_communications_protocol(4);
## 
##    $self->ips_set_control(3);
##
##    return $self
##}
#
#
sub itc_set_control { # don't use it if you get an error message during reading out sensors:"Cading Sensor";
# 0 Local & Locked
# 1 Remote & Locked
# 2 Local & Unlocked
# 3 Remote & Unlocked
    my $self=shift;
    my $mode=shift;
    my $cmd=sprintf("C%d\r",$mode);
    $self->{vi}->Write($cmd);
    sleep(1);
}
#
sub itc_set_communications_protocol {
# 0 "Normal" (default)
# 2 Sends <LF> after each <CR>
    my $self=shift;
    my $mode=shift;
    $self->{vi}->Write("Q$mode\r");
}

sub itc_read_parameter {
# 0 Demand SET TEMPERATURE     K
# 1 Sensor 1 Temperature     K
# 2 Sensor 2 Temperature     K
# 3 Sensor 3 Temperature     K
# 4 Temperature Error (+ve when SET>Measured)
# 5 Heater O/P (as % of current limit)
# 6 Heater O/P (as Volts, approx)
# 7 Gas Flow O/P (arbitratry units)
# 8 Proportional Band
# 9 Integral Action Time
#10 Derivative Actionb Time
#11 Channel 1 Freq/4
#12 Channel 2 Freq/4
#13 Channel 3 Freq/4

    my $self=shift;
    my $parameter=shift;
    my $cmd=sprintf("R%d\r",$parameter);
    #$self->{vi}->Clear();
    my $result=$self->{vi}->Query($cmd);
    chomp $result;
    #printf "Result of $cmd=$result\n";
    $result =~ s/^R//;
    return sprintf("%e",$result);
}


sub itc_get_T_sample {
# 
my $self=shift;
my $s2=$self->itc_read_parameter(3); #T of Sensor 2
#$s2=$self->itc_read_parameter(3); #T of Sensor 2
#printf "s2=$s2\n";
my $s3=$self->itc_read_parameter(4); #T of Sensor 3
 #$s3=$self->itc_read_parameter(4); #T of Sensor 3
#printf "s3=$s3\n";
my $T=$s2;
if ($s3>$RuO2_Cernox and $s2>$RuO2_Cernox){$T=$s3}
return $T
}



sub itc_set_wait {
# delay before each character is sent
# in millisecond
    my $self=shift;
    my $wait=shift;
    $wait=sprintf("%d",$wait);
    $self->{vi}->Query("W$wait\r");
}   

sub itc_examine {
# Examine Status
    my $self=shift;
    $self->{vi}->Query("X\r");
}   

sub itc_set_heater_auto {
# 0 Heater Manual, Gas Manual;
# 1 Heater Auto, Gas Manual
# 2 Heater Manual, Gas Auto
# 3 Heater Auto, Gas Auto
    my $self=shift;
    my $mode=shift;
    $mode=sprintf("%d",$mode);
    $self->{vi}->Query("A$mode\r");
}



sub itc_set_proportional_value {
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->{vi}->Query("P$value\r");
}


sub itc_set_integral_value {
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->{vi}->Query("I$value\r");
}
sub itc_set_derivative_value {
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->{vi}->Query("D$value\r");
}

sub itc_set_heater_sensor {
# 1 Sensor 1
# 2 Sensor 2
# 3 Sensor 3
    my $self=shift;
    my $value=shift;
    #$self->itc_set_heater_auto(0);
    $value=sprintf("%d",$value);
    $self->{vi}->Query("H$value\r");
}

sub itc_set_PID_auto {
# 0 PID Auto Off
# 1 PID on
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->{vi}->Query("L$value\r");
}

sub itc_set_max_heater_voltage {
# in 0.1 V
# 0 dynamical varying limit
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->{vi}->Query("M$value\r");
}

sub itc_set_heater_output {
# from 0 to 0.999 
# 0 dynamical varying limit
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",1000*$value);
    $self->{vi}->Query("O$value\r");
}

sub itc_T_set_point {
#  Setpoint 
    my $self=shift;
    my $value=shift;
    $value=sprintf("%.3f",$value);
    $self->{vi}->Query("T$value\r");
}
sub itc_sweep {
# 0 Stop Sweep 
# 1 Start Sweep
#nn=2P-1 Sweeping to step P
#nn=2P Sweeping to step P
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->{vi}->Query("S$value\r");
}



sub itc_set_pointer{
# Sets Pointer in internal ITC memory
    my $self=shift;
    my $x=shift;
    my $y=shift;
    if ($x<0 or $x>128){ printf "x=$x no valid ITC Pointer value\n";die };
    if ($y<0 or $y>128){ printf "y=$y no valid ITC Pointer value\n";die };
    my $cmd=sprintf("x%d\r",$x);
    $self->{vi}->Query($cmd);
    $cmd=sprintf("y%d\r",$y);
    $self->{vi}->Query($cmd);
}

sub itc_program_sweep_table{
    my $self=shift;
    my $setpoint=shift; #K Sweep Stop Point
    my $sweeptime=shift; #Min. Total Sweep Time
    my $holdtime=shift; #sec. Hold Time
    
    if ($setpoint<0. or $setpoint >9.9){printf "Cannot reach setpoint: $setpoint\n";die};
    
    $self->itc_set_pointer(1,1);
    $setpoint=sprintf("%1.4f",$setpoint);
    $self->{vi}->Query("s$setpoint\r");

    $self->itc_set_pointer(1,2);
    $sweeptime=sprintf("%.4f",$sweeptime);
    $self->{vi}->Query("s$sweeptime\r");    
    
    $self->itc_set_pointer(1,3);
    $holdtime=sprintf("%.4f",$holdtime);
    $self->{vi}->Query("s$holdtime\r");
    
    $self->itc_set_pointer(0,0);
}

sub itc_read_sweep_table {
# Clears Sweep Program Table
    my $self=shift;
    $self->{vi}->Query("r\r");
}

sub itc_clear_sweep_table {
# Clears Sweep Program Table
    my $self=shift;
    $self->{vi}->Query("w\r");
}





# now comes the interface



1;

