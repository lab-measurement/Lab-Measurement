package Lab::Instrument::Yokogawa7651;

use warnings;
use strict;

our $VERSION = '2.94';
use 5.010;


use Lab::Instrument;
use Lab::Instrument::Source;


our @ISA=('Lab::Instrument::Source');

our %fields = (
	supported_connections => [ 'GPIB', 'VISA', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => 22,
	},

	device_settings => {
		gate_protect            => 1,
		gp_equal_level          => 1e-5,
		gp_max_units_per_second  => 0.002,
		gp_max_units_per_step    => 0.001,
		gp_max_step_per_second  => 2,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
		
		stepsize		=> 0.01,
	},
	
	device_cache => {
		function			=> "Voltage", 
		range			=> undef,
		level			=> undef,
		output					=> undef,
	},
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
    
    return $self;
}


sub set_voltage {
    my $self=shift;
    my $voltage=shift;
    
    my $function = $self->get_function();

    if( $function !~ /voltage/i ){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $function. Can't set voltage level.");
    }
    
    
    return $self->set_level($voltage, @_);
}

sub set_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    
    my $function = $self->get_function();

    if($function ne '1'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $function. Can't set voltage level.");
    }
    
    if( abs($voltage) > 32.){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is not capable of voltage level > 32V. Can't set voltage level.");
    }
    
    $self->set_level_auto($voltage, @_);
}

sub set_current_auto {
    my $self=shift;
    my $current=shift;
    
    my $function = $self->get_function();

    if($function ne '5'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $function. Can't set current level.");
    }
    
    if( abs($current) > 0.200){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is not capable of current level > 200mA. Can't set current level.");
    }
    
    $self->set_level_auto($current, @_);
}

sub set_current {
    my $self=shift;
    my $current=shift;

	my $function = $self->get_function();

    if( $function !~ /current/i ){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $function. Can't set current level.");
    }

    $self->set_level($current, @_);
}

sub _set_level {
    my $self=shift;
    my $value=shift;
        
    my $cmd=sprintf("S%ee",$value);
    
    $self->write( $cmd );
    
    return $self->{'device_cache'}->{'level'} = $value;
    
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

sub _sweep_to_level {
    my $self=shift;
    my $target = shift;
    my $time = shift;
    
    
    my $output_now=$self->get_level();
    #Test if $stop in range
    my $range=$self->get_range();
    
    if ( $target > $range || $target < -$range ){
        Lab::Exception->throw("The desired source level $target is not within the source range $range \n");
    }
    
    my $cmd=sprintf("PI%.1fe",$time);
    $self->write( $cmd );
    $cmd=sprintf("SW%.1fe",$time);
    $self->write( $cmd );
    
    $self->write("M1");
    
    # Set Status byte mask to "end program"
    $self->write("MS16");
    
    #Start Programming-----
    $self->execute_program(0);
    $self->start_program();
    
    
    $self->set_setpoint($target);
    $self->end_program();

    $self->execute_program(2);
    
    while (($self->query("OC") =~ /^STS1=(\d+)/g )&& $1 & 2 ){
    	#print $self->query("OC");
    	#print $self->connection()->serial_poll()."\n";
    	sleep 1;
    }
    
    if( ! $self->get_level( device_cache => 1) == $target){
    	Lab::Exception::CorruptParameter->throw(
    	"Sweep failed.")
    }
    
    return $self->device_cache()->{'level'} = $target;
}

sub get_function{
	my $self = shift;
	
	my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if(! $options->{'from_device'}){
     	return $self->{'device_cache'}->{'function'};
    }    
    
    my $cmd="OD";
    my $result=$self->query($cmd);
    if($result=~/^...(V|A)/){
    	return ( $result eq "V" ) ? "Voltage" : "Current";
    }
    else{
    	Lab::Exception::CorruptParameter->throw( "Output of command OD is not valid. \n" );
    }
    
}


sub get_level {
    my $self=shift;
    
    my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if(! $options->{'from_device'}){
     	return $self->{'device_cache'}->{'level'};
    }    
    
    my $cmd="OD";
    my $result=$self->query($cmd);
    $result=~/....([\+\-\d\.E]*)/;
    return $1;
}

sub get_voltage{
	my $self=shift;
	
	my $function = $self->get_function();

    if( $function !~ /voltage/i){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $function. Can't get voltage level.");
    }

    return $self->get_level(@_);
}

sub get_current{
	my $self=shift;
	
	my $function = $self->get_function();

    if( $function !~ /current/i){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $function. Can't get current level.");
    }

    return $self->get_level(@_);
}

sub set_function {
    my $self = shift;
    my $function = shift;
    
    
    if( $function !~ /(current|voltage)/i ){
    	Lab::Exception::CorruptParameter->throw( "$function is not a valid source mode. Choose 1 or 5 for current and voltage mode respectively. \n" );
    }
    
    my $my_function = ($function =~ /current/i) ? 5 : 1;
    
    my $cmd=sprintf("F%de",$my_function);
    
    $self->write( $cmd );
    return $self->{'device_cache'}->{'function'} = $function;
    
}

sub set_range {
    my $self=shift;
    my $my_range = shift;
    my $range = 0;
    
    my $function = $self->get_function();
    if( $function =~ /voltage/i ){
    	given($my_range){
    		when( 0.01 ){ $range = 2 }
    		when( 0.1 ){ $range = 3 }
    		when( 1 ){ $range = 4 }
    		when( 10 ){ $range = 5 }
    		when( 30 ){ $range = 6 }
    		default { 
    			Lab::Exception::CorruptParameter->throw( "$range is not a valid voltage range. Read the documentation for a list of allowed ranges in mode $function. \n" )
    		}
    	}
    }
    elsif($function =~ /current/i){
    	given($my_range){
    		when( 0.001 ){ $range = 4 }
    		when( 0.01 ){ $range = 5 }
    		when( 0.1 ){ $range = 6 }
    		default { Lab::Exception::CorruptParameter->throw( "$range is not a valid current range. Read the documentation for a list of allowed ranges in mode $function.\n" )}
    	}
    }
    else{
    	Lab::Exception::CorruptParameter->throw( "$range is not a valid source range. Read the documentation for a list of allowed ranges in mode $function.\n" );
    }
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
      
    my $cmd = sprintf("R%ue",$range);
    
    $self->write($cmd);
    return $self->{'device_cache'}->{'range'} = $my_range;
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
    }
    return @info;
}

sub get_range{
    my $self=shift;
    
    my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if(! $options->{'from_device'}){
     	return $self->{'device_cache'}->{'range'};
    }    
    
    
    my $range=($self->get_info())[1];
    my $function = $self->get_function();
    
    
    if ($range =~ /F(\d)R(\d)/){
	    $range=$2;
	    #    printf "rangenr=$range_nr\n";
    }
    
    if($function =~ /voltage/i){
    	given ($range) {
    		when( /2/ ){ $range = 0.01; }
    		when( /3/ ){ $range = 0.1; }
    		when( /4/ ){ $range = 1; }
    		when( /5/ ){ $range = 10; }
    		when( /6/ ){ $range = 30; }
    		default {
    			Lab::Exception::CorruptParameter->throw( "$range is not a valid voltage range. Read the documentation for a list of allowed ranges in mode $function.\n")
    		}
    	}
    }
    elsif($function =~ /current/i){
    	given($range){
    		when( /4/ ){ $range = 0.001; }
    		when( /5/ ){ $range = 0.01; }
    		when( /6/ ){ $range = 0.1; }
    		default {
    			Lab::Exception::CorruptParameter->throw( "$range is not a valid current range. Read the documentation for a list of allowed ranges in mode $function.\n" )
    		}
    	}
    }
    else{
    	Lab::Exception::CorruptParameter->throw( "$range is not a valid source range. Read the documentation for a list of allowed ranges in mode $function.\n" );
    }
        
    return $range;
}

sub set_run_mode {
    my $self=shift;
    my $value=shift;
    if ($value!=0 and $value!=1) { Lab::Exception::CorruptParameter->throw( error=>"Run Mode $value not defined\n" ); }
    my $cmd=sprintf("M%u",$value);
    $self->write($cmd);
}

sub set_output {
    my $self = shift;
    my $output = shift;
    
    if( $output !~ /(0|1)/){
    	Lab::Exception::CorruptParameter->throw( "Device does not support output $output \n" );
    }
    my $cmd = sprintf("O%e",$output);
    
    $self->write($cmd);
    $self->write('E');
    
    return $self->{'device_cache'}->{'output'} = $output;
}
    

sub get_output {
    my $self=shift;
    
    my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if(! $options->{'from_device'}){
     	return $self->{'device_cache'}->{'output'};
    }    
    
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
    my $status=$self->query('OC');
    
    $status=~/STS1=(\d*)/;
    $status=$1;
    my @flags=qw/
        CAL_switch  memory_card calibration_mode    output
        unstable    error   execution   setting/;
    my %result;
    for (0..7) {
        $result{$flags[$_]}=$status & 128;
        $status<<=1;
    }
    return %result;
}

#
# Accessor implementations
#

sub autorange() {
	my $self = shift;
	
	return $self->{'autorange'} if scalar(@_)==0;
	my $value = shift;
	
	if($value==0) {
		$self->{'autorange'} = 0;
	}
	elsif($value==1) {
		warn("Warning: Autoranging can give you some nice voltage spikes on the Yokogawa7651. You've been warned!\n");
		$self->{'autorange'} = 1;
	}
	else {
		Lab::Exception::CorruptParameter->throw( error=>"Illegal value for autorange(), only 1 or 0 accepted.\n" );
	}
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
      gate_protecet => 1,
      level => 0.5,
    );
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::Yokogawa7651 class implements an interface to the
discontinued voltage and current source 7651 by Yokogawa. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTORS

=head2 new( %configuration_HASH )

HASH is a list of tuples given in the format

key => value,

please supply at least the configuration for the connection:
		connection_type 		=> "LinxGPIB"
		gpib_address =>

you might also want to have gate protect from the start (the default values are given):

		gate_protect => 1,

		gp_equal_level          => 1e-5,
		gp_max_units_per_second  => 0.05,
		gp_max_units_per_step    => 0.005,
		gp_max_step_per_second  => 10,
		gp_max_units_per_second  => 0.05,
		gp_max_units_per_step    => 0.005,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
	
Additinally there is support to set parameters for the device "on init":		
If those values are not specified, defaults are supplied by the driver.
	
		function			=> Voltage, # specify "Voltage" or "Current" mode, string is case insensitive
		range			=> undef,
		level			=> undef,
		output					=> undef,

If those values are not specified, the current device configuration is left unaltered.



=head1 METHODS

=head2 set_voltage($voltage)

Sets the output voltage to $voltage.
Returns the newly set voltage.

=head2 get_voltage()

Returns the currently set $voltage. The value is read from the driver cache by default. Provide the option

device_cache => 1

to read directly from the device.

=head2 set_current($current)

Sets the output current to $current.
Returns the newly set current.

=head2 get_current()

Returns the currently set $current. The value is read from the driver cache by default. Provide the option

device_cache => 1

to read directly from the device.

=head2 set_range($range)

Set the output range for the device. $range should be either in decimal or scientific notation.
Returns the newly set range.

=head2 get_info()

Returns the information provided by the instrument's 'OS' command, in the form of an array
with one entry per line. For display, use join(',',$yoko->get_info()); or similar.

=head2 set_output( $onoff )

Sets the output switch to "1" (on) or "0" (off).
Returns the new output state;

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
