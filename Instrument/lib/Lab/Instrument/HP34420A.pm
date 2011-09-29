#$Id$

package Lab::Instrument::HP34420A;

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
    my ($digits, $range, $counts)=@_;
    print "HP34420A.pm: config_voltage is completely untested. You have been warned.\n";

    #set input resistance to >10 GOhm for the three highest resolution values 
    $self->{vi}->Write("INPut:IMPedance:AUTO ON");

    $digits = int($digits);
    $digits = 4 if $digits < 4;
    $digits = 6 if $digits > 6;
 
    if ($range < 0.1) {
      $range = 0.1;
    }
    elsif ($range < 1) {
      $range = 1;
    }
    elsif ($range < 10) {
      $range = 10;
    }
    elsif ($range < 100) {
      $range = 100;
    }
    else{
      $range = 1000;
    }

    my $resolution = (10**(-$digits))*$range;
    $self->{vi}->Write("CONF:VOLT:DC $range,$resolution");


    # calculate integration time, set it and prepare for output
 
    my $inttime = 0;

    if ($digits ==4) {
      $inttime = 0.4;
      $self->{vi}->Write("VOLT:NPLC 0.02");
    }
    elsif ($digits ==5) {
      $inttime = 4;
      $self->{vi}->Write("VOLT:NPLC 0.2");
    }
    elsif ($digits ==6) {
      $inttime = 200;
      $self->{vi}->Write("VOLT:NPLC 10");
      $self->{vi}->Write("ZERO:AUTO OFF");
    }

    my $retval = $inttime." ms";


    # triggering
    $self->{vi}->Write("TRIGger:SOURce BUS");
    $self->{vi}->Write("SAMPle:COUNt $counts");
    $self->{vi}->Write("TRIGger:DELay MIN");
    $self->{vi}->Write("TRIGger:DELay:AUTO OFF");

    return $retval;
}

sub read_with_trigger_voltage_dc {
    my $self=shift;

    $self->{vi}->Write("INIT");
    $self->{vi}->Write("*TRG");
    my $value = $self->{vi}->Query("FETCh?");

    chomp $value;

    my @valarray = split(",",$value);

    return @valarray;
}


sub scroll_message {
    use Time::HiRes (qw/usleep/);
    my $self=shift;
    my $message=shift || "            Lab::Instrument is a great measurement package!!!            ";
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

sub read_value {
    my $self=shift;
    my $value=$self->{vi}->Query('READ?');
    chomp $value;
    return $value;
}

1;

=head1 NAME

Lab::Instrument::HP34420A - HP/Agilent 34420A nanovolt/microohm meter

=cut
