package Lab::Moose::Instrument::OI_Triton::Temperature;
#ABSTRACT: Oxford Instruments Triton temperature control

use 5.010;
use Moose;
use Carp;
use Lab::Moose::Instrument qw/validated_channel_getter validated_channel_setter
                              validated_getter validated_setter/;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $socket_opts = { port => 33576 };
    $options->{Socket} = $socket_opts;
    return $options;
};

sub get_default_channel {
    my $self = shift;
    return 5;
}

sub get_temperature {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_
    );
    my $temp = $self->query(command => "READ:DEV:T$channel:TEMP:SIG:TEMP");
    # typical response: STAT:DEV:T1:TEMP:SIG:TEMP:1.47628K
    $temp =~ s/^.*:SIG:TEMP://;
    $temp =~ s/K.*$//;
    return $temp;
}

sub enable_control {
    my $self = shift;
    my $temp = $self->query(command => "SET:SYS:USER:NORM");
    # typical response: STAT:SET:SYS:USER:NORM:VALID
    return $temp;
}

sub disable_control {
    my $self = shift;
    my $temp = $self->query(command => "SET:SYS:USER:GUEST");
    # typical response: STAT:SET:S$x = YS:USER:GUEST:VALID
    return $temp;
}

sub enable_temp_pid {
    my $self = shift;
    my $temp = $self->query(command => "SET:DEV:T5:TEMP:LOOP:MODE:ON");
    # typical response: STAT:SET:DEV:T5:TEMP:LOOP:MODE:ON:VALID
    return $temp;
}

sub disable_temp_pid {
    my $self = shift;
    my $temp = $self->query(command => "SET:DEV:T5:TEMP:LOOP:MODE:OFF");
    # typical response: STAT:SET:DEV:T5:TEMP:LOOP:MODE:OFF:VALID
    return $temp;
}

sub set_temperature {
    my ( $self, $temp, %args ) = validated_setter(
        \@_, 
        value => { isa => 'Num' },
    );
    
    if ( $temp > 0.7 ) { croak "OI_Triton::set_T: setting temperatures above 0.7K is forbidden\n"; };
    
    if ( $temp < 0.035 ) {
      $self->set_Imax( value => 0.000316);
    } elsif ( $temp < 0.07 ) {
      $self->set_Imax( value => 0.001);
    } elsif ( $temp < 0.35 ) {
      $self->set_Imax( value => 0.00316); 
    } else {
      $self->set_Imax(value => 0.01);
    };
    
    $self->query(command => "SET:DEV:T5:TEMP:LOOP:TSET:$temp");
    # typical reply: STAT:SET:DEV:T5:TEMP:LOOP:TSET:0.1:VALID    
    $self->enable_temp_pid();
    $self->query(command => "SET:DEV:T5:TEMP:LOOP:TSET:$temp");
    # typical reply: STAT:SET:DEV:T5:TEMP:LOOP:TSET:0.1:VALID
}

sub sweep_to_temperature {
    my ( $self, $temp, %args ) = validated_setter(
        \@_, 
        value => { isa => 'Num' }
    );
    $self->set_temperature(value => $temp);

    my $now = 10000;
    while ( abs( $now - $temp ) / $temp > 0.05 ) {
        sleep(10);
        $now = $self->get_temperature();
        say "Waiting for T=$temp ; current temperature is T=$now";
    };
}

sub set_Imax {
    my ( $self, $imax, %args ) = validated_setter(
        \@_, 
        value => { isa => 'Num' },
    );
    if ($imax > 0.0101) { croak "OI_Triton::set_Imax: Setting too large heater current limit\n"; };
    $imax=$imax*1000; # in mA
    return $self->query(command => "SET:DEV:T5:TEMP:LOOP:RANGE:$imax");
};

sub get_power {
    my ( $self, %args ) = validated_getter(
        \@_, 
    );
    my $power = $self->query(command => "READ:DEV:H1:HTR:SIG:POWR");
    $power =~ s/^.*SIG:POWR://;
    $power =~ s/uW$//;
    return $power;
}

sub set_power {
    my ( $self, $power, %args ) = validated_setter(
        \@_, 
        value => { isa => 'Num' },
    );    
    return $self->query(command => "SET:DEV:H1:HTR:SIG:POWR:$power");
}

1;
