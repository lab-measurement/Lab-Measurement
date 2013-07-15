package Lab::Instrument::Cryogenic;

use strict;
use Lab::Instrument;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self
}



sub ramp_to_mid {
    my $self=shift;
    $self->{vi}->Write("RAMP MID\n");
    my $status = $self-> status();
    while ($status =~ /HOLDING/) {	# takes care that command is finally executed
      $status = $self-> status();

      $status =~/MID SETTING: (.*) AMPS/;
      my $mid = $1;
      $status =~/OUTPUT: (.*) AMPS/;
      my $out = $1;
 
      last if $mid == $out;  # breaks if we have already reached target


      $self->{vi}->Write("RAMP MID\n");
      print "power supply not responding, send command again\n";
      sleep(1);
    }

    while ($status =~ /RAMPING/) {	
      $status = $self-> status();
      sleep(1);
    }

    $status =~/MID SETTING: (.*) AMPS/;
    my $mid = $1;
    $status =~/OUTPUT: (.*) AMPS/;
    my $out = $1;

    return 0 if $mid == $out;
    return 1;
}



sub ramp_to_zero {
    my $self=shift;
    $self->{vi}->Write("RAMP ZERO\n");
    my $status = $self-> status();
    while ($status =~ /HOLDING/) {	# takes care that command is finally executed
      $status = $self-> status();

      $status =~/OUTPUT: (.*) AMPS/;
      my $out = $1;
 
      last if $out == 0;  # breaks if we have already reached target

      $self->{vi}->Write("RAMP ZERO\n");
      print "power supply not responding, send command again\n";
      sleep(1);
    }

    while ($status =~ /RAMPING/) {	
      $status = $self-> status();
      sleep(1);
    }

    $status = $self-> status();
    $status =~/OUTPUT: (.*) AMPS/;
    my $out = $1;
    if ($out == 0) {
      return 0;
    }
    return 1;
}


sub ramp_to_max {
    my $self=shift;
    $self->{vi}->Write("RAMP MAX\n");
    my $status = $self-> status();
    while ($status =~ /HOLDING/) {	# takes care that command is finally executed
      $status = $self-> status();

      $status =~/MAX SETTING: (.*) AMPS/;
      my $max = $1;
      $status =~/OUTPUT: (.*) AMPS/;
      my $out = $1;
 
      last if $max == $out;  # breaks if we have already reached target


      $self->{vi}->Write("RAMP MID\n");
      print "power supply not responding, send command again\n";
      sleep(1);
    }

    while ($status =~ /RAMPING/) {	
      $status = $self-> status();
      sleep(1);
    }

    $status =~/MAX SETTING: (.*) AMPS/;
    my $max = $1;
    $status =~/OUTPUT: (.*) AMPS/;
    my $out = $1;

    return 0 if $max == $out;
    return 1;
}




sub heater_on{
    my $self=shift;
    $self->{vi}->Write("HEATER ON\n");

    my $status = $self-> status();
    while ($status =~ /HEATER STATUS: OFF/) {	# takes care that command is finally executed
      sleep(1);
      $self->{vi}->Write("HEATER ON\n");
      print "power supply not responding, send command again\n";
      sleep(1);
      $status = $self-> status();
    }
    sleep(10);
    return 0;
}

sub heater_off{
    my $self=shift;
    $self->{vi}->Write("HEATER OFF\n");

    my $status = $self-> status();
    while ($status =~ /HEATER STATUS: ON/) {	# takes care that command is finally executed
      sleep(1);
      print "power supply not responding, send command again\n";
      $self->{vi}->Write("HEATER OFF\n");
      sleep(1);
      $status = $self-> status();
    }
    sleep(10);
    return 0;
}

sub status {
    my $self=shift;
    my $result=$self->{vi}->long_Query("U\n",1000);
    for (my $i = 1; $i <= 20; $i++) {
      $result.=$self->{vi}->long_Query("U\n",1000);

    }
    return $result;
}

sub read_messages {
    my $self=shift;
    my $result=$self->{vi}->Read(1000);
}


1;

1;


=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::Cryogenic - Cryogenic SMS120 superconducting magnet supply

  Source: David Borowsky and Simon Mates

=cut

