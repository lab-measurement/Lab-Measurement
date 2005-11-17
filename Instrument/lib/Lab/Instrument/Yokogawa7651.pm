#$Id$

package Lab::Instrument::Yokogawa7651;
use strict;
use Lab::Instrument;
use Lab::Instrument::Source;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

our @ISA=('Lab::Instrument::Source');

my $default_config={
    gate_protect            => 0,
    gp_max_volt_per_step    => 0.0004,
    gp_max_volt_per_second  => 0.0015,
    gp_max_step_per_second  => 2,   # already implemented?
    
    check_range             => 1,
    auto_range              => 0,
    ranges                  => {
        2       =>  10e-3,
        3       =>  100e-3,
        4       =>  1,
        5       =>  10,
        6       =>  30,
    },
};

sub new {
    my $proto = shift;
    my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($default_config,@args);
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@args);
    
    return $self
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub set_current {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub _set {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("S%e",$value);
    $self->{vi}->Write($cmd);
    $cmd="E";
    $self->{vi}->Write($cmd);
}

sub get_voltage {
    my $self=shift;
    return $self->_get();
}

sub get_current {
    my $self=shift;
    return $self->_get();
}

sub _get {
    my $self=shift;
    my $cmd="OD";
    my $result=$self->{vi}->Query($cmd);
    $result=~/....([\+\-\d\.E]*)/;
    return $1;
}

sub set_current_mode {
    my $self=shift;
    my $cmd="F5";
    $self->{vi}->Write($cmd);
}

sub set_voltage_mode {
    my $self=shift;
    my $cmd="F1";
    $self->{vi}->Write($cmd);
}

sub set_range {
    my $self=shift;
    my $range=shift;
    my $cmd="R$range";
      #fixed voltage mode
      # 2   10mV
      # 3   100mV
      # 4   1V
      # 5   10V
      # 6   30V
      #fixed current mode
      # 4   1mA
      # 5   10mA
      # 6   100mA
    $self->{vi}->Write($cmd);
}

sub get_info {
    my $self=shift;
    my $result=$self->{vi}->Query("OS");
    return $result;
}

sub output_on {
    my $self=shift;
    $self->{vi}->Write('O1');
    $self->{vi}->Write('E');
}
    
sub output_off {
    my $self=shift;
    $self->{vi}->Write('O0');
    $self->{vi}->Write('E');
}

sub get_output {
    my $self=shift;
    my %res=$self->get_status();
    return $res{output};
}

sub initialize {
    my $self=shift;
    $self->{vi}->Write('RC');
}

sub set_voltage_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LV%e",$value);
    $self->{vi}->Write($cmd);
}

sub set_current_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LA%e",$value);
    $self->{vi}->Write($cmd);
}

sub get_status {
    my $self=shift;
    my $status=$self->{vi}->Query('OC');
    
    $status=~/STS1=(\d*)/;
    $status=$1;
    my @flags=qw/
        CAL_switch  memory_card calibration_mode    output
        unstable    error   execution   setting/;
    my %result;
    for (0..7) {
        if ($status&128) {
            $result{$flags[$_]}=1;
        }
        $status<<=1;
    }
    return %result;
}

1;

=head1 NAME

Lab::Instrument::Yokogawa7651 - a Yokogawa 7651 DC source

=head1 SYNOPSIS

    use Lab::Instrument::Yokogawa7651;
    
    my $gate14=new Lab::Instrument::Yokogawa7651(0,11);
    $gate14->set_range(5);
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_range($range)

    Fixed voltage mode
        2   10mV
        3   100mV
        4   1V
        5   10V
        6   30V

    Fixed current mode
        4   1mA
        5   10mA
        6   100mA

=head2 get_info()

=head2 output_on()

=head2 output_off()

=head2 get_output()

=head2 initialize()

=head2 set_voltage_limit($limit)

=head2 set_current_limit($limit)

=head2 get_status()

=head1 INSTRUMENT SPECIFICATIONS

=head2 DC voltage

The stability (24h) is the value at 23 ± 1°C. The stability (90days),
accuracy (90days) and accuracy (1year) are values at 23 ± 5°C.
The temperature coefficient is the value at 5 to 18°C and 28 to 40°C.

 Range  Maximum     Resolution  Stability 24h   Stability 90d   
        Output                  ±(% of setting  ±(% of setting  
                                +µV)            +µV)            
 ------------------------------------------------------------- 
 10mV   ±12.0000mV  100nV       0.002 + 3       0.014 + 4       
 100mV  ±120.000mV  1µV         0.003 + 3       0.014 + 5       
 1V     ±1.20000V   10µV        0.001 + 10      0.008 + 50      
 10V    ±12.0000V   100µV       0.001 + 20      0.008 + 100     
 30V    ±32.000V    1mV         0.001 + 50      0.008 + 200     



 Range  Accuracy 90d    Accuracy 1yr    Temperature
        ±(% of setting  ±(% of setting  Coefficient
        +µV)            +µV)            ±(% of setting
                                        +µV)/°C
 -----------------------------------------------------
 10mV   0.018 + 4       0.025 + 5       0.0018 + 0.7
 100mV  0.018 + 10      0.025 + 10      0.0018 + 0.7
 1V     0.01 + 100      0.016 + 120     0.0009 + 7
 10V    0.01 + 200      0.016 + 240     0.0008 + 10
 30V    0.01 + 500      0.016 + 600     0.0008 + 30
 

 
 Range   Maximum Output                   Output Noise
         Output  Resistance          DC to 10Hz  DC to 10kHz
                                                 (typical data)
 ----------------------------------------------------------
 10mV    -       approx. 2Ohm        3µVp-p      30µVp-p
 100mV   -       approx. 2Ohm        5µVp-p      30µVp-p
 1V      ±120mA  less than 2mOhm     15µVp-p     60µVp-p
 10V     ±120mA  less than 2mOhm     50µVp-p     100µVp-p
 30V     ±120mA  less than 2mOhm     150µVp-p    200µVp-p


Common mode rejection:
120dB or more (DC, 50/60Hz). (However, it is 100dB or more in the
30V range.)

=head2 DC current

 Range   Maximum     Resolution  Stability (24 h)    Stability (90 days) 
         Output                  ±(% of setting      ±(% of setting      
                                 + µA)               + µA)               
 -----------------------------------------------------------------------
 1mA     ±1.20000mA  10nA        0.0015 + 0.03       0.016 + 0.1         
 10mA    ±12.0000mA  100nA       0.0015 + 0.3        0.016 + 0.5         
 100mA   ±120.000mA  1µA         0.004  + 3          0.016 + 5           



 Range   Accuracy (90 days)  Accuracy (1 year)   Temperature  
         ±(% of setting      ±(% of setting      Coefficient     
         + µA)               + µA)               ±(% of setting  
                                                 + µA)/°C        
 -----   ------------------------------------------------------  
 1mA     0.02 + 0.1          0.03 + 0.1          0.0015 + 0.01   
 10mA    0.02 + 0.5          0.03 + 0.5          0.0015 + 0.1    
 100mA   0.02 + 5            0.03 + 5            0.002  + 1



 Range  Maximum     Output                   Output Noise
        Output      Resistance          DC to 10Hz  DC to 10kHz
                                                    (typical data)
 -----------------------------------------------------------------
 1mA    ±30 V       more than 100MOhm   0.02µAp-p   0.1µAp-p
 10mA   ±30 V       more than 100MOhm   0.2µAp-p    0.3µAp-p
 100mA  ±30 V       more than 10MOhm    2µAp-p      3µAp-p

Common mode rejection: 100nA/V or more (DC, 50/60Hz).

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item Lab::VISA

The Yokogawa7651 class uses the Lab::VISA module (L<Lab::VISA>).

=item Lab::Instrument

The Yokogawa7651 class is a Lab::Instrument (L<Lab::Instrument>).

=item SafeSource

The Yokogawa7651 class is a SafeSource (L<SafeSource>)

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
