package Lab::Instrument::Yokogawa7651;
use strict;
use Switch;
use Lab::Instrument;
use Lab::Instrument::Source;


our @ISA=('Lab::Instrument::Source');

my %fields = (
	supported_connections => [ 'GPIB', 'VISA', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => 22,
	},

	device_settings => {
		gate_protect            => 1,
		gp_equal_level          => 1e-5,
		gp_max_volt_per_second  => 0.002,
		gp_max_volt_per_step    => 0.001,
		gp_max_step_per_second  => 2,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
	},
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->_construct(__PACKAGE__, \%fields);

	# already called in Lab::Instrument::Source, but call it again to respect default values in local channel_defaultconfig
	$self->configure($self->config());
	$self->device_settings($self->config('device_settings')) if defined $self->config('device_settings') && ref($self->config('device_settings')) eq 'HASH';
    
    return $self;
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub _set_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    $self->_set_auto($voltage);
}

# huh? something is strange here
sub set_current {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub _set {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("S%e",$value);
    $self->write( $cmd );
    $cmd="E";
    $self->write( $cmd );
}

sub _set_auto {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("SA%e",$value);
    $self->write( $cmd );
    $cmd="E";
    $self->write( $cmd );
}

sub set_setpoint {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("S%+.4e",$value);
    $self->write($cmd);
}

sub set_time {
    my $self=shift;
    my $sweep_time=shift; #sec.
    my $interval_time=shift;
    if ($sweep_time<$self->device_settings('min_sweep_time')) {
        warn "Warning Sweep Time: $sweep_time smaller than ${\$self->device_settings('min_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('min_sweep_time')} sec";
        $sweep_time=$self->device_settings('min_sweep_time')}
    elsif ($sweep_time>$self->device_settings('max_sweep_time')) {
        warn "Warning Sweep Time: $sweep_time> ${\$self->device_settings('max_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('max_sweep_time')} sec";
        $sweep_time=$self->device_settings('max_sweep_time')
    };
    if ($interval_time<$self->device_settings('min_sweep_time')) {
        warn "Warning Interval Time: $interval_time smaller than ${\$self->device_settings('min_sweep_time')} sec!\n Interval time set to ${\$self->device_settings('min_sweep_time')} sec";
        $interval_time=$self->device_settings('min_sweep_time')}
    elsif ($interval_time>$self->device_settings('max_sweep_time')) {
        warn "Warning Interval Time: $interval_time> ${\$self->device_settings('max_sweep_time')} sec!\n Interval time set to ${\$self->device_settings('max_sweep_time')} sec";
        $interval_time=$self->device_settings('max_sweep_time')
    };
    my $cmd=sprintf("PI%.1f",$interval_time);
    $self->write( $cmd );
    $cmd=sprintf("SW%.1f",$sweep_time);
    $self->write( $cmd );
}

sub start_program {
    my $self=shift;
    my $cmd=sprintf("PRS");
    $self->write( $cmd );
}

sub end_program {
    my $self=shift;
    my $cmd=sprintf("PRE");
    $self->write( $cmd );
}

sub execute_program {
    # 0 HALT
    # 1 STEP
    # 2 RUN
    #3 Continue
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("RU%d",$value);
    $self->write( $cmd );
}

sub sweep {
    my $self=shift;
    my $stop=shift;
    my $rate=shift;
    my $return_rate=$rate;
    $self->execute_program(0);
    my $output_now=$self->_get();
    #Test if $stop in range
    my $range=$self->get_range();
    #Start Programming-----
    $self->start_program();
    if ($stop>$range){
        $stop=$range;
    }
    elsif ($stop< -$range) {
        $stop=-$range;
    }
    $self->set_setpoint($stop);
    $self->end_program();

    my $time=abs($output_now -$stop)/$rate;
    if ($time<$self->device_settings('min_sweep_time')) {
        warn "Warning Sweep Time: $time smaller than ${\$self->device_settings('min_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('min_sweep_time')} sec";
        $time=$self->device_settings('min_sweep_time');
        $return_rate=abs($output_now -$stop)/$time;
    }
    elsif ($time>$self->device_settings('max_sweep_time')) {
        warn "Warning Interval Time: $time> ${\$self->device_settings('max_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('max_sweep_time')} sec";
        $time=$self->device_settings('max_sweep_time');
        $return_rate=abs($output_now -$stop)/$time;
    }
    $self->set_time($time,$time);
    $self->execute_program(2);
    return $return_rate;
}

sub _get_voltage {
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
    my $result=$self->query($cmd);
    $result=~/....([\+\-\d\.E]*)/;
    return $1;
}

sub set_current_mode {
    my $self=shift;
    my $cmd="F5";
    $self->write($cmd);
}

sub set_voltage_mode {
    my $self=shift;
    my $cmd="F1";
    $self->write($cmd);
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
    $self->write($cmd);
}

sub get_info {
    my $self=shift;
    $self->write("OS");
    my @info;
    for (my $i=0;$i<=10;$i++){
        my $line=$self->connection()->Read( read_length => 300 );
        if ($line=~/END/){last};
        chomp $line;
        $line=~s/\r//;
        push(@info,sprintf($line));
    };
    return @info;
}

sub get_range{
    my $self=shift;
    my @info=$self->get_info();
    my $result=$info[1];
    my $func_nr=0;
    my $range_nr=0;
    my $range=0;
    #printf "$result\n";
    if ($result=~/F(\d)R(\d)/){
    $func_nr=$1;
    #printf "funcnr=$func_nr\n";
    $range_nr=$2;
    #    printf "rangenr=$range_nr\n";
    }
    if ($func_nr==1){ # DC V
        switch ($range_nr) {
            case 2 {$range=10e-3} #10mV
            case 3 {$range=100e-3} #100mV
            case 4 {$range=1} #1V
            case 5 {$range=10} #10V
            case 6 {$range=30} #30V
            else { Lab::Exception::CorruptParameter->throw( error=>"Range $range_nr not defined\n" . Lab::Exception::Base::Appendix() ); }
        }
    }
    elsif ($func_nr==5){
        switch ($range_nr) {
            case 4 {$range=1e-3} #1mA
            case 5 {$range=10e-3} #10mA
            case 6 {$range=100e-3} #100mA
            else { Lab::Exception::CorruptParameter->throw( error=>"Range $range_nr not defined\n" . Lab::Exception::Base::Appendix() ); }
        }
    }
    else { Lab::Exception::CorruptParameter->throw( error=>"Function not defined: $func_nr\n" . Lab::Exception::Base::Appendix() ); }
    #printf "$range\n";
    return $range
}

sub set_run_mode {
    my $self=shift;
    my $value=shift;
    if ($value!=0 and $value!=1) { Lab::Exception::CorruptParameter->throw( error=>"Run Mode $value not defined\n" . Lab::Exception::Base::Appendix() ); }
    my $cmd=sprintf("M%u",$value);
    $self->write($cmd);
}

sub output_on {
    my $self=shift;
    $self->write('O1');
    $self->write('E');
}
    
sub output_off {
    my $self=shift;
    $self->write('O0');
    $self->write('E');
}

sub get_output {
    my $self=shift;
    my %res=$self->get_status();
    return $res{output};
}

sub initialize {
    my $self=shift;
    $self->write('RC');
}

sub set_voltage_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LV%e",$value);
    $self->write($cmd);
}

sub set_current_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LA%e",$value);
    $self->write($cmd);
}

sub get_status {
    my $self=shift;
    my $status=$self->write('OC');
    
    $status=~/STS1=(\d*)/;
    $status=$1;
    my @flags=qw/
        CAL_switch  memory_card calibration_mode    output
        unstable    error   execution   setting/;
    my %result;
    for (0..7) {
        $result{$flags[$_]}=$status&128;
        $status<<=1;
    }
    return %result;
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::Yokogawa7651 - Yokogawa 7651 DC source

=head1 SYNOPSIS

    use Lab::Instrument::Yokogawa7651;
    
    my $gate14=new Lab::Instrument::Yokogawa7651(
      connection_type => 'LinuxGPIB',
      gpib_address => 22,
    );
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::Yokogawa7651 class implements an interface to the
discontinued voltage and current source 7651 by Yokogawa. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

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

Returns the information provided by the instrument's 'OS' command, in the form of an array
with one entry per line. For display, use join(',',$yoko->get_info()); or similar.

=head2 output_on()

Sets the output switch to on.

=head2 output_off()

Sets the output switch to off. The instrument outputs no voltage
or current then, no matter what voltage you set.

=head2 get_output()

Returns the status of the output switch (0 or 1).

=head2 initialize()

=head2 set_voltage_limit($limit)

=head2 set_current_limit($limit)

=head2 get_status()

Returns a hash with the following keys:

    CAL_switch
    memory_card
    calibration_mode
    output
    unstable
    error
    execution
    setting

The value for each key is either 0 or 1, indicating the status of the instrument.

=head1 INSTRUMENT SPECIFICATIONS

=head2 DC voltage

The stability (24h) is the value at 23 +- 1°C. The stability (90days),
accuracy (90days) and accuracy (1year) are values at 23 +- 5°C.
The temperature coefficient is the value at 5 to 18°C and 28 to 40°C.


 Range  Maximum     Resolution  Stability 24h   Stability 90d   
        Output                  +-(% of setting +-(% of setting  
                                + µV)           + µV)            
 ------------------------------------------------------------- 
 10mV   +-12.0000mV 100nV       0.002 + 3       0.014 + 4       
 100mV  +-120.000mV 1µV         0.003 + 3       0.014 + 5       
 1V     +-1.20000V  10µV        0.001 + 10      0.008 + 50      
 10V    +-12.0000V  100µV       0.001 + 20      0.008 + 100     
 30V    +-32.000V   1mV         0.001 + 50      0.008 + 200     



 Range  Accuracy 90d    Accuracy 1yr    Temperature
        +-(% of setting +-(% of setting Coefficient
        +µV)           +µV)           +-(% of setting
                                        +µV)/°C
 -----------------------------------------------------
 10mV   0.018 + 4       0.025 + 5       0.0018 + 0.7
 100mV  0.018 + 10      0.025 + 10      0.0018 + 0.7
 1V     0.01 + 100      0.016 + 120     0.0009 + 7
 10V    0.01 + 200      0.016 + 240     0.0008 + 10
 30V    0.01 + 500      0.016 + 600     0.0008 + 30



 Range   Maximum Output              Output Noise
         Output  Resistance          DC to 10Hz  DC to 10kHz
                                     (typical data)
 ----------------------------------------------------------
 10mV    -       approx. 2Ohm        3µVp-p      30µVp-p
 100mV   -       approx. 2Ohm        5µVp-p      30µVp-p
 1V      +-120mA less than 2mOhm     15µVp-p     60µVp-p
 10V     +-120mA less than 2mOhm     50µVp-p     100µVp-p
 30V     +-120mA less than 2mOhm     150µVp-p    200µVp-p


Common mode rejection:
120dB or more (DC, 50/60Hz). (However, it is 100dB or more in the
30V range.)

=head2 DC current

 Range   Maximum     Resolution  Stability (24 h)    Stability (90 days) 
         Output                  +-(% of setting     +-(% of setting      
                                 + µA)              + µA)               
 -----------------------------------------------------------------------
 1mA     +-1.20000mA 10nA        0.0015 + 0.03       0.016 + 0.1         
 10mA    +-12.0000mA 100nA       0.0015 + 0.3        0.016 + 0.5         
 100mA   +-120.000mA 1µA         0.004  + 3          0.016 + 5           


 Range   Accuracy (90 days)  Accuracy (1 year)   Temperature  
         +-(% of setting     +-(% of setting     Coefficient     
         + µA)               + µA)               +-(% of setting  
                                                 + µA)/°C
 -----   ------------------------------------------------------  
 1mA     0.02 + 0.1          0.03 + 0.1          0.0015 + 0.01   
 10mA    0.02 + 0.5          0.03 + 0.5          0.0015 + 0.1    
 100mA   0.02 + 5            0.03 + 5            0.002  + 1


 Range  Maximum     Output                   Output Noise
        Output      Resistance          DC to 10Hz  DC to 10kHz
                                                    (typical data)
 -----------------------------------------------------------------
 1mA    +-30 V      more than 100MOhm   0.02µAp-p   0.1µAp-p
 10mA   +-30 V      more than 100MOhm   0.2µAp-p    0.3µAp-p
 100mA  +-30 V      more than 10MOhm    2µAp-p      3µAp-p

Common mode rejection: 100nA/V or more (DC, 50/60Hz).

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item * Lab::Instrument

The Yokogawa7651 class is a Lab::Instrument (L<Lab::Instrument>).

=item * Lab::Instrument::Source

The Yokogawa7651 class is a Source (L<Lab::Instrument::Source>)

=back

=head1 AUTHOR/COPYRIGHT

 (c) 2004-2006 Daniel Schröer
 (c) 2007-2010 Daniel Schröer, Daniela Taubert, Andreas K. Hüttel, and others
 (c) 2011 Florian Olbrich, Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
