
package Lab::Instrument::YokogawaGS200;
use strict;
use warnings;

our $VERSION = '2.93';

use feature "switch";
use Lab::Instrument;
use Lab::Instrument::Source;


our @ISA=('Lab::Instrument::Source');

our %fields = (
	supported_connections => [ 'VISA_GPIB', 'GPIB', 'VISA', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => 22,
	},

	device_settings => {
		gate_protect            => 1,
		gp_equal_level          => 1e-5,
		gp_max_volt_per_second  => 0.05,
		gp_max_volt_per_step    => 0.005,
		gp_max_step_per_second  => 10,
		gp_max_amps_per_second  => 0.05,
		gp_max_amps_per_step    => 0.005,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
	},
	# If class does not provide set_$var for those, AUTOLOAD will take care.
	device_cache => {
		source_function			=> undef, # 'VOLT' - voltage, 'CURR' - current
		source_range			=> undef,
		source_level			=> undef,
	},
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	# already called in Lab::Instrument::Source, but call it again to respect default values in local channel_defaultconfig
	$self->configure($self->config());
    
    return $self;
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    
    my $source_function = $self->get_source_function();

    if($source_function ne 'VOLT'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't set voltage level.");
    }
    
    
    return $self->_set_source_level($voltage);
}

sub _set_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    
    my $source_function = $self->get_source_function();

    if($source_function ne 'VOLT'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't set voltage level.");
    }
    
    if( abs($voltage) > 32.){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is not capable of voltage level > 32V. Can't set voltage level.");
    }
    
    $self->_set_source_level_auto($voltage);
}

sub _set_current_auto {
    my $self=shift;
    my $current=shift;
    
    my $source_function = $self->get_source_function();

    if($source_function ne 'CURR'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't set current level.");
    }
    
    if( abs($current) > 0.200){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is not capable of current level > 200mA. Can't set current level.");
    }
    
    $self->_set_source_level_auto($current);
}

sub _set_current {
    my $self=shift;
    my $current=shift;

	my $source_function = $self->get_source_function();

    if($self->get_source_function ne 'CURR'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't set current level.");
    }

    $self->_set_source_level($current);
}

sub _set_source_level {
    my $self=shift;
    my $value=shift;
    my $srcrange = $self->get_source_range();
    
    (my $dec, my $exp) = ($srcrange =~ m/(^\d+)E([-\+]\d+)$/);
        
    $srcrange = eval("$dec*10**$exp+2*$dec*10**($exp-1)");
        
    if( abs($value) <= $srcrange ){
    	my $cmd=sprintf(":SOURce:LEVel %f",$value);
    	#print $cmd;
		$self->write( $cmd );
		return $self->{'device_cache'}->{'source_level'} = $value;
    }
    else{
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Level $value is out of curren range $srcrange.");
    }
	
	
}

sub _set_source_level_auto {
    my $self=shift;
    my $value=shift;
    
    my $cmd=sprintf(":SOURce:LEVel:AUTO %e",$value);
	
	$self->write( $cmd );
	
	$self->{'device_cache'}->{'source_range'} = $self->get_source_range( device_cache => 1 );

    return $self->{'device_cache'}->{'source_level'} = $value;
	
}



sub run_program {
    my $self=shift;
    my $cmd = shift;
    
    $self->write( ":PROG:LOAD $cmd" ) if $cmd;
    
    $self->write(":PROG:RUN");
    
}

sub pause_program {
    my $self=shift;   
    
    my $cmd=sprintf(":PROGram:PAUSe");
	$self->write( "$cmd" );
}
sub continue_program {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf(":PROGram:CONTinue");
	$self->write( "$cmd" );
    
}

sub halt_program{
	my $self=shift;
	my $cmd=":PROGram:HALT";
	$self->write("$cmd");
}

sub sweep_to_voltage {
    my $self=shift;
    my $target=shift;
    my $time=shift;
    
    my $vpsec = undef;
    my $vpstep = undef;
    my $spsec = undef;
    
    my $current = $self->get_voltage();
    my $source_function = $self->{'device_cache'}->{'source_function'};
    
    if($source_function ne 'VOLT'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't set voltage level.");
    }
    
    if( $target && $time){
    	$vpsec= (abs($target-$current))/$time;
    	
    	if($self->{'device_settings'}->{'gate_protect'}){
    		$self->_check_gate_protect();
    		$vpsec = $self->{'device_settings'}->{'gp_max_volt_per_second'} ? ($vpsec > $self->{'device_settings'}->{'gp_max_volt_per_second'}): $vpstep;
    		    		
    	}	 
    }
    else{
    
    # if we use gate_protect, we make sure that the rates are oke.
    
   	$self->_check_gate_protect();
	
	$vpsec = $self->device_settings()->{gp_max_amps_per_second};
	$vpstep = $self->device_settings()->{gp_max_amps_per_step};
	$spsec = $self->device_settings()->{gp_max_step_per_second};
    
	
    }
    
    $self->write("*CLS");
    $self->write(":PROG:REP 0");
    $self->write(":PROG:SLOP $time");
    $self->write(":PROG:INT $time");
    $self->write(":PROG:EDIT:START");
    $self->write(":SOUR:LEV $target");
    $self->write(":PROG:EDIT:END");
    $self->write(":STAT:ENAB 64");
    $self->write(":PROG:RUN");
    
    print $self->connection()->serial_poll()->{'1'} . "\n";
    
    while ($self->connection()->serial_poll()->{'1'} ne "1"){
    	print $self->connection()->serial_poll()->{'1'} ."\n";
    	sleep 1;
    }
    
    if( ! $self->get_source_level( device_cache => 1) == $target){
    	Lab::Exception::CorruptParameter->throw(
    	"Sweep failed.")
    }
    
    $self->{'device_cache'}->{'source_level'} = $target;
    
    return $target;
}

sub get_voltage {
    my $self=shift;

	my $source_function = $self->get_source_function();

    if(! $self->get_source_function eq 'VOLT'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't get voltage level.");
    }

    return $self->get_source_level(@_);
}

sub get_current {
    my $self=shift;
    
    my $source_function = $self->get_source_function();
    
    if(!$self->get_source_function() eq 'CURR'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't get current level.");
    }
   	
    return $self->get_source_level(@_);
}

sub get_source_level {
    my $self=shift;
    my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if( $options->{'device_cache'}){
     	$self->query( ":SOURce:LEVel?" );
     	s/(\d+\.\d+)E\d+/\1/g;
     	return;
    }
    else{
		return $self->device_cache()->{'source_level'};
    }
}

sub get_source_function{
	my $self=shift;	
	my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if( $options->{'device_cache'}){
    	my $cmd=":SOURce:FUNCtion?";
    	return $self->query( $cmd );
    }
    else{
		return $self->device_cache()->{'source_function'};
    }
		
}

sub get_source_range{
	my $self=shift;
	my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if( $options->{'device_cache'}){
    	my $cmd=":SOURce:RANGe?";
    	return $self->query( $cmd );
    }
    else{
		return $self->device_cache()->{'source_range'};
    }
}

sub set_source_function {
    my $self=shift;
    my $func=shift;
    
    
    if( $func =~ m/(^VOLT|^CURR)/ ){
    	my $cmd=":SOURce:FUNCtion $func";
    	#print "$cmd\n";
    	$self->write( $cmd );
    	return $self->{'device_cache'}->{'source_function'} = $func;	
    }
    else{
    	Lab::Exception::CorruptParameter->throw( error=>"source function $func not defined for this device.\n" ); 
    }    
            
}


sub set_source_range {
    my $self=shift;
    my $range=shift;

    
    my $srcf = $self->get_source_function();
    
    if( $srcf eq 'VOLT'  ){    	
    	if( $range =~ m/(^10E-3|^100E-3|^1E\+0|^1E\+1|^3E\+1)/){
    		$self->write("SOURce:RANGe $range");
    		return $self->{'device_cache'}->{'source_range'} = $range;
    		
    	}
    	else{
    	  	Lab::Exception::CorruptParameter->throw(
    		error=>"Source is in mode $srcf. For this mode, $range is not a valid range.");	
    	} 
    }
    elsif( $srcf eq 'CURR' ){
    		if( $range =~ m/(^1E-3|^10E-3|^100E-3|^200E-3)/ ){
    			$self->write( "SOURce:RANGe $range" );
    			return $self->{'device_cache'}->{'source_range'} = $range;
    			 }
    		else{
    	  		Lab::Exception::CorruptParameter->throw(
    			error=>"Source is in mode $srcf. For this mode, $range is not a valid range.");	
    		}
    }
    else{
    	Lab::Exception::CorruptParameter->throw(
    			error=>"Something went wrong. $srcf is not a valid source function.");
    }	

}


sub output_on {
    my $self=shift;
    return $self->{"device_cache"}->{"output"} = $self->write( ':OUTP 1' );
}
    
sub output_off {
    my $self=shift;
    return $self->{"device_cache"}->{"output"} = $self->write( ':OUTP 0' );
}

sub get_output {
    my $self=shift;
    
    my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if( $options->{'device_cache'}){
     	$self->query( ":OUTP?" );
     	return;
    }
    
    return $self->{"device_cache"}->{"output"};
}


sub set_voltage_limit {
    my $self=shift;
    my $value=shift;
    my $cmd = ":SOURce:PROTection:VOLTage $value";
    
    if($value > 30. || $value < 1. ){
    	Lab::Exception::CorruptParameter->throw( error=>"The voltage limit $value is not within the allowed range.\n" );
    }
    
    $self->connection()->write( $cmd );
    
    return $self->device_cache()->{'voltage_limit'} = $value;
    
}

sub set_current_limit {
    my $self=shift;
    my $value=shift;
    my $cmd = ":SOURce:PROTection:CURRent $value";
    
    if($value > 0.2 || $value < 0.001 ){
    	Lab::Exception::CorruptParameter->throw( error=>"The current limit $value is not within the allowed range.\n" );
    }
    
    $self->connection()->write( $cmd );
    
    return $self->device_cache()->{'current_limit'} = $value;
    
}


sub get_error{
	my $self=shift;
	
	my $cmd = ":SYSTem:ERRor?";
	
	return $self->connection()->query( $cmd );
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::YokogawaGS200 - Yokogawa GS200 DC source

=head1 SYNOPSIS

    use Lab::Instrument::YokogawaGS200;
    
    my $gate14=new Lab::Instrument::YokogawaGS200(
      connection_type => 'LinuxGPIB',
      gpib_address => 22,
      source_function => 'VOLT',
      source_level => 0.4,
    );
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::YokogawaGS200 class implements an interface to the
discontinued voltage and current source GS200 by Yokogawa. This class derives from
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
		gp_max_volt_per_second  => 0.05,
		gp_max_volt_per_step    => 0.005,
		gp_max_step_per_second  => 10,
		gp_max_amps_per_second  => 0.05,
		gp_max_amps_per_step    => 0.005,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
	
Additinally there is support to set parameters for the device "on init":		
	
		source_function			=> undef, # 'VOLT' - voltage, 'CURR' - current
		source_range			=> undef,
		source_level			=> undef,
		output					=> undef,

If those values are not specified, they are read from the device.

=head1 METHODS

=head2 sweep_to_voltage($voltage,$time)

Sweeps to $voltage in $time seconds.
For this function to work, the source has to be in output mode.

Returns the newly set voltage. 
This function is also called internally to set the voltage when gate protect is used.

=head2 run_program($program)

Runs a program stored on the YokogawaGS200. If no prgram name is given, the currently loaded program is executed.

=head2 pause_program

Pauses the currently running program.

=head2 continue_program

Continues the paused program.

=head2 set_voltage($voltage)

Sets the output voltage. The driver checks whether you stay inside the currently selected range. 
Returns the newly set voltage.

=head2 set_voltage_auto($voltage)

Sets the output voltage. The range is chosen automatically.
Does not work with gate protect on.
Returns the newly set voltage.

=head2 set_current($current)

See set_voltage

=head2 set_current_auto($current)

See set_current_auto

=head2 set_range($range)

    Fixed voltage mode
    10E-3    10mV
    100E-3   100mV
    1E+0     1V
    10E+0    10V
    30E+0    30V

    Fixed current mode
    1E-3   		1mA
    10E-3   	10mA
    100E-3   	100mA
    200E-3		200mA
    
    Please use the format on the left for the range command.

=head2 set_source_function($function)

Sets the source function. The Yokogawa supports the values 

"CURR" for current mode and
"VOLT" for voltage mode.

Returns the newly set source function.

=head2 set_voltage_limit($limit)

Sets a voltage limit to protect the device.
Returns the new voltage limit.

=head2 set_current_limit($limit)

See set_voltage_limit.

=head2 output_on()

Sets the output switch to on and returns the new value of the output status.

=head2 output_off()

Sets the output switch to off. The instrument outputs no voltage
or current then, no matter what voltage you set. Returns the new value of the output status.


=head2 get_error()

Queries the error code from the device. This is a very useful thing to do when you are working remote and the source is not responding.


=head2 get_voltage()


=head2 get_current()


=head2 get_output()


=head2 get_source_range()



=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4


=item * Lab::Instrument

The YokogawaGP200 class is a Lab::Instrument (L<Lab::Instrument>).

=item * Lab::Instrument::Source

The YokogawaGP200 class is a Source (L<Lab::Instrument::Source>)

=back

=head1 AUTHOR/COPYRIGHT

 (c) 2004-2006 Daniel Schröer
 (c) 2007-2010 Daniel Schröer, Daniela Taubert, Andreas K. Hüttel, and others
 (c) 2011 Florian Olbrich, Andreas K. Hüttel
 (c) 2012 Alois Dirnaichner

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
