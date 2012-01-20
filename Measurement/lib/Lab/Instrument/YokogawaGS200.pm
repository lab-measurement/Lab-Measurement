
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

sub set_voltage {
    my $self=shift;
    my $voltage=shift;
    
    my $source_function = $self->get_source_function();

    if($source_function ne 'VOLT'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't set voltage level.");
    }
    
    
    return $self->set_source_level($voltage);
}

sub set_voltage_auto {
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
    
    $self->set_source_level_auto($voltage);
}

sub set_current_auto {
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
    
    $self->set_source_level_auto($current);
}

sub set_current {
    my $self=shift;
    my $current=shift;

	my $source_function = $self->get_source_function();

    if($self->get_source_function ne 'CURR'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't set current level.");
    }

    $self->set_source_level($current);
}

sub set_source_level {
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

sub set_source_level_auto {
    my $self=shift;
    my $value=shift;
    
    my $cmd=sprintf(":SOURce:LEVel:AUTO %e",$value);
	
	$self->write( $cmd );
	
	$self->{'device_cache'}->{'source_range'} = $self->get_source_range( device_cache => 1 );

    return $self->{'device_cache'}->{'source_level'} = $value;
	
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
    my $cmd=sprintf(":PROGram:INTerval %.1f",$interval_time);
	$self->connection()->write( "$cmd" );
    $cmd=sprintf(":PROGram:SLOPe %.1f",$sweep_time);
	$self->connection()->write( "$cmd" );
}

sub run_program {
    my $self=shift;
    my $cmd=sprintf(":PROGram:RUN");
	$self->connection()->write( "$cmd" );
}

sub pause_program {
    my $self=shift;
    my $cmd=sprintf(":PROGram:PAUSe");
	$self->connection()->write( "$cmd" );
}
sub continue_program {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf(":PROGram:CONTinue");
	$self->connection()->write( "$cmd" );
    
}

sub halt_program{
	my $self=shift;
	my $cmd=":PROGram:HALT";
	$self->connection()->writ("$cmd");
}

sub sweep {
    my $self=shift;
    my $stop=shift;
    my $rate=shift;
    my $return_rate=$rate;
    $self->pause_program();
    my $output_now=$self->get_source_level();
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
    if ($time<$self->get_min_sweep_time()) {
        warn "Warning Sweep Time: $time smaller than ${\$self->device_settings('min_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('min_sweep_time')} sec";
        $time=$self->get_min_sweep_time();
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

sub get_voltage {
    my $self=shift;

	my $source_function = $self->get_source_function();

    if(!$self->get_source_function eq 'V'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't get voltage level.");
    }

    return $self->{'device_cache'}->get_source_level(@_);
}

sub get_current {
    my $self=shift;
    
    my $source_function = $self->get_source_function();
    
    if(!$self->get_source_function() eq 'C'){
    	Lab::Exception::CorruptParameter->throw(
    	error=>"Source is in mode $source_function. Can't get current level.");
    }
   	
    return $self->{'device_cache'}->get_source_level(@_);
}

sub get_source_level {
    my $self=shift;
    my $options = undef;
	if (ref $_[0] eq 'HASH') { $options=shift }	else { $options={@_} }
	
    if( $options->{'device_cache'}){
     	return $self->query( ":SOURce:LEVel?" );
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

sub get_info {
    my $self=shift;
    $self->connection()->Write( command  => "OS" );
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


sub set_run_mode {
    my $self=shift;
    my $value=shift;
    if ($value!=0 and $value!=1) { Lab::Exception::CorruptParameter->throw( error=>"Run Mode $value not defined\n" ); }
    my $cmd=sprintf("M%u",$value);
    $self->connection()->Write( command  => $cmd );
}

sub output_on {
    my $self=shift;
    $self->connection()->Write( command  => ':OUTP 1' );
}
    
sub output_off {
    my $self=shift;
    $self->connection()->Write( command  => ':OUTP 0' );
}

sub get_output {
    my $self=shift;
    my %res=$self->get_status();
    return $res{output};
}

sub initialize {
    my $self=shift;
    $self->connection()->Write( command  => 'RC' );
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
    );
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::YokogawaGS200 class implements an interface to the
discontinued voltage and current source GS200 by Yokogawa. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_range($range)

    Fixed voltage mode
    10E-3    10mV
    100E-3   100mV
    1E+0     1V
    10E+0    10V
    30E+0    30V

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

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
