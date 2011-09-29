#$Id$

package Lab::Instrument::HP34411A;

use strict;
use Lab::Instrument;

our $VERSION="1.21";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self
}

sub read_voltage_dc {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:VOLTage:DC? %s,%s",$range,$resolution);
    my ($value)=split "\n",$self->{vi}->Query($cmd);
    return $value;
}

sub read_resistance {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:RESistance? %s,%s",$range,$resolution);
    my ($value)=split "\n",$self->{vi}->Query($cmd);
    return $value;
}

sub read_voltage_ac {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:VOLTage:AC? %u,%f",$range,$resolution);
    my ($value)=split "\n",$self->{vi}->Query($cmd);
    return $value;
}

sub read_current_dc {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:CURRent:DC? %u,%f",$range,$resolution);
    my ($value)=split "\n",$self->{vi}->Query($cmd);
    return $value;
}

sub read_current_ac {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:CURRent:AC? %u,%f",$range,$resolution);
    my ($value)=split "\n",$self->{vi}->Query($cmd);
    return $value;
}

sub display_text {
    my $self=shift;
    my $text=shift;
    
    if ($text) {
        $self->{vi}->Write(qq(DISPlay:TEXT "$text"));
    } else {
        chomp($text=$self->{vi}->Query(qq(DISPlay:TEXT?)));
        $text=~s/\"//g;
    }
    return $text;
}

sub display_on {
    my $self=shift;
    $self->{vi}->Write("DISPlay ON");
}

sub display_off {
    my $self=shift;
    $self->{vi}->Write("DISPlay OFF");
}

sub display_clear {
    my $self=shift;
    $self->{vi}->Write("DISPlay:TEXT:CLEar");
}

sub beep {
    my $self=shift;
    $self->{vi}->Write("SYSTem:BEEPer");
}

sub get_error {
    my $self=shift;
    chomp(my $err=$self->{vi}->Query("SYSTem:ERRor?"));
    my ($err_num,$err_msg)=split ",",$err;
    $err_msg=~s/\"//g;
    return ($err_num,$err_msg);
}

sub reset {
    my $self=shift;
    $self->{vi}->Write("*RST");
}

sub config_voltage {
    my $self=shift;
    my ($inttime, $range, $counts)=@_;

    #set input resistance to >10 GOhm for the three highest resolution values 
    $self->{vi}->Write("SENS:VOLTage:DC:IMPedance:AUTO ON");

    # set integration time
    $self->{vi}->Write("SENS:VOLT:DC:APERture $inttime");

    # disable autozero
    $self->{vi}->Write("SENS:VOLT:ZERO:AUTO ONCE");

    # set range
    $self->{vi}->Write("SENS:VOLT:RANGe $range");
   

    # triggering
    $self->{vi}->Write("TRIGger:SOURce BUS");
    $self->{vi}->Write("SAMPle:COUNt $counts");
    $self->{vi}->Write("TRIGger:DELay MIN");
    $self->{vi}->Write("TRIGger:DELay:AUTO OFF");
}

sub config_voltage_plc {
    my $self=shift;
    my ($plc, $range, $counts)=@_;

    #set input resistance to >10 GOhm for the three highest resolution values 
    $self->{vi}->Write("SENS:VOLTage:DC:IMPedance:AUTO ON");

    # set integration time
    $self->{vi}->Write("SENS:VOLT:DC:NPLC $plc");

    # disable autozero
    $self->{vi}->Write("SENS:VOLT:ZERO:AUTO ONCE");

    # set range
    $self->{vi}->Write("SENS:VOLT:RANGe $range");
   

    # triggering
    $self->{vi}->Write("TRIGger:SOURce BUS");
    $self->{vi}->Write("SAMPle:COUNt $counts");
    $self->{vi}->Write("TRIGger:DELay MIN");
    $self->{vi}->Write("TRIGger:DELay:AUTO OFF");

}




sub read_with_trigger_voltage_dc {
    my $self=shift;
    my $bytes=shift;

    $self->{vi}->Write("INIT");
    $self->{vi}->Write("*TRG");
    my $value = $self->{vi}->long_Query("FETCh?",$bytes);
    chomp $value;    

    my @valarray = split(",",$value);

    return @valarray;
}


sub scroll_message {
    use Time::HiRes (qw/usleep/);
    my $self=shift;
    my $message=shift || "            This perl instrument driver is copyright 2004/2005 by Daniel Schroeer.            ";
    for my $i (0..(length($message)-12)) {
        $self->display_text(sprintf "%12.12s",substr($message,$i));
        usleep(100000);
    }
    $self->display_clear();
}

sub id {
    my $self=shift;
    $self->{vi}->Query('*IDN?');
}

1;

=head1 NAME

Lab::Instrument::HP34411A - HP/Agilent 34410A or 34411A digital multimeter

=head1 SYNOPSIS

    use Lab::Instrument::HP34411A;
    
    my $hp=new Lab::Instrument::HP34411A(0,22);
    print $hp->read_voltage_dc(10,0.00001);

=head1 DESCRIPTION

The Lab::Instrument::HP34411A class implements an interface to the 34410A and 34411A digital multimeters by
Agilent (formerly HP). Note that the module Lab::Instrument::HP34401A still works for those newer multimeter 
models.

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head2 read_voltage_dc

    $datum=$hp->read_voltage_dc($range,$resolution);

Preset and make a dc voltage measurement with the specified range
and resolution.

=over 4

=item $range

Range is given in terms of volts and can be C<[0.1|1|10|100|1000|MIN|MAX|DEF]>. C<DEF> is default.

=item $resolution

Resolution is given in terms of C<$range> or C<[MIN|MAX|DEF]>.
C<$resolution=0.0001> means 4 1/2 digits for example.
The best resolution is 100nV: C<$range=0.1>; C<$resolution=0.000001>.

=back

=head2 read_voltage_ac

    $datum=$hp->read_voltage_ac($range,$resolution);

Preset and make an ac voltage measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6½ digits. The resolution parameter only affects the front-panel display.

=head2 read_current_dc

    $datum=$hp->read_current_dc($range,$resolution);

Preset and make a dc current measurement with the specified range
and resolution.

=head2 read_current_ac

    $datum=$hp->read_current_ac($range,$resolution);

Preset and make an ac current measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6½ digits. The resolution parameter only affects the front-panel display.

=head2 read_resistance

    $datum=$hp->read_resistance($range,$resolution);

Preset and measure resistance with specified range and resolution.

=head2 config_voltage

    $hp->config_voltage($inttime,$range,$count);

Configures device for measurement with specified integration time, voltage range and number of data
points (up to 1 million). Afterwards, data can be taken by triggering the multimeter, resulting in faster 
measurements than using read_voltage_dc, especially when using $count >> 1.

=head2 config_voltage_plc

    $hp->config_voltage_plc($plc,$range,$count);

Same as config_voltage, but here the number of power line cycles ($plc) is given instead of an integration time.

=head2 read_with_trigger_voltage_dc

    @array = $hp->read_with_trigger_voltage_dc()

Take data points as configured with config_voltage(). Returns an array.

=head2 display_on

    $hp->display_on();

Turn the front-panel display on.

=head2 display_off

    $hp->display_off();

Turn the front-panel display off.

=head2 display_text

    $hp->display_text($text);
    print $hp->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 display_clear

    $hp->display_clear();

Clear the message displayed on the front panel.

=head2 scroll_message

    $hp->scroll_message($message);

Scrolls the message C<$message> on the display of the HP.

=head2 beep

    $hp->beep();

Issue a single beep immediately.

=head2 get_error

    ($err_num,$err_msg)=$hp->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 reset

    $hp->reset();

Reset the multimeter to its power-on configuration.

=head2 id

    $id=$hp->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004-2009 Daniel Schröer (<schroeer@cpan.org>), 2009-2010 Daniel Schröer, Daniela Taubert

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
