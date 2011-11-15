package Lab::Instrument::ITC503;
our $VERSION = '2.93';

use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

my %fields = (
	supported_connections => [ 'IsoBus', 'LinuxGPIB' ],
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	$self->connection()->SetTermChar(chr(13));
	$self->connection()->EnableTermChar(1);

	printf "The ITC driver is work in progress. You have been warned.\n";
    
#     my $xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR, 0xD);
#     if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while setting read termination character: $xstatus";}
# 
#     $xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_TRUE);
#     if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while enabling read termination character: $xstatus";}
    
    return $self;
}

sub itc_set_control { # don't use it if you get an error message during reading out sensors:"Cading Sensor";
# 0 Local & Locked
# 1 Remote & Locked
# 2 Local & Unlocked
# 3 Remote & Unlocked
    my $self=shift;
    my $mode=shift;
    my $cmd=sprintf("C%d\r",$mode);
    $self->query($cmd);
    sleep(1);
}

sub itc_set_communications_protocol {
# 0 "Normal" (default)
# 2 Sends <LF> after each <CR>
    my $self=shift;
    my $mode=shift;
    $self->write("Q$mode\r");
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
    my $result=$self->query($cmd);
    chomp $result;
    $result =~ s/^\s*R//;
    return sprintf("%e",$result);
}

sub itc_set_wait {
# delay before each character is sent
# in millisecond
    my $self=shift;
    my $wait=shift;
    $wait=sprintf("%d",$wait);
    $self->query("W$wait\r");
}   

sub itc_examine {
# Examine Status
    my $self=shift;
    $self->query("X\r");
}   

sub itc_set_heater_auto {
# 0 Heater Manual, Gas Manual;
# 1 Heater Auto, Gas Manual
# 2 Heater Manual, Gas Auto
# 3 Heater Auto, Gas Auto
    my $self=shift;
    my $mode=shift;
    $mode=sprintf("%d",$mode);
    $self->query("A$mode\r");
}

sub itc_set_proportional_value {
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->query("P$value\r");
}

sub itc_set_integral_value {
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->query("I$value\r");
}

sub itc_set_derivative_value {
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->query("D$value\r");
}

sub itc_set_heater_sensor {
# 1 Sensor 1
# 2 Sensor 2
# 3 Sensor 3
    my $self=shift;
    my $value=shift;
    #$self->itc_set_heater_auto(0);
    $value=sprintf("%d",$value);
    $self->query("H$value\r");
}

sub itc_set_PID_auto {
# 0 PID Auto Off
# 1 PID on
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->query("L$value\r");
}

sub itc_set_max_heater_voltage {
# in 0.1 V
# 0 dynamical varying limit
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->query("M$value\r");
}

sub itc_set_heater_output {
# from 0 to 0.999 
# 0 dynamical varying limit
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",1000*$value);
    $self->query("O$value\r");
}

sub itc_T_set_point {
#  Setpoint 
    my $self=shift;
    my $value=shift;
    $value=sprintf("%.3f",$value);
    $self->query("T$value\r");
}
sub itc_sweep {
# 0 Stop Sweep 
# 1 Start Sweep
#nn=2P-1 Sweeping to step P
#nn=2P Sweeping to step P
    my $self=shift;
    my $value=shift;
    $value=sprintf("%d",$value);
    $self->query("S$value\r");
}

sub itc_set_pointer{
# Sets Pointer in internal ITC memory
    my $self=shift;
    my $x=shift;
    my $y=shift;
    if ($x<0 or $x>128){ printf "x=$x no valid ITC Pointer value\n";die };
    if ($y<0 or $y>128){ printf "y=$y no valid ITC Pointer value\n";die };
    my $cmd=sprintf("x%d\r",$x);
    $self->query($cmd);
    $cmd=sprintf("y%d\r",$y);
    $self->query($cmd);
}

sub itc_program_sweep_table{
    my $self=shift;
    my $setpoint=shift; #K Sweep Stop Point
    my $sweeptime=shift; #Min. Total Sweep Time
    my $holdtime=shift; #sec. Hold Time
    
    if ($setpoint<0. or $setpoint >9.9){printf "Cannot reach setpoint: $setpoint\n";die};
    
    $self->itc_set_pointer(1,1);
    $setpoint=sprintf("%1.4f",$setpoint);
    $self->query("s$setpoint\r");

    $self->itc_set_pointer(1,2);
    $sweeptime=sprintf("%.4f",$sweeptime);
    $self->query("s$sweeptime\r");    
    
    $self->itc_set_pointer(1,3);
    $holdtime=sprintf("%.4f",$holdtime);
    $self->query("s$holdtime\r");
    
    $self->itc_set_pointer(0,0);
}

sub itc_read_sweep_table {
# Clears Sweep Program Table
    my $self=shift;
    $self->query("r\r");
}

sub itc_clear_sweep_table {
# Clears Sweep Program Table
    my $self=shift;
    $self->query("w\r");
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::ITC503 - Oxford Instruments ITC503 Intelligent Temperature Control

=head1 SYNOPSIS

    use Lab::Instrument::ITC503;
    
    my $itc=new Lab::Instrument::ITC503(
	isobus_address=>3,
    );
 
=head1 DESCRIPTION

The Lab::Instrument::ITC503 class implements an interface to the Oxford Instruments 
ITC intelligent temperature controller (tested with the ITC503). This driver is still
work in progress and also lacks documentation.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2010-2011 David Kalok and Andreas K. Hüttel (L<http://www.akhuettel.de/>)

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
