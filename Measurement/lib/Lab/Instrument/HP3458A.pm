#!/usr/bin/perl

package Lab::Instrument::HP3458A;
our $VERSION = '2.93';

use strict;
use Lab::Instrument;
use Lab::Instrument::Multimeter;
use Time::HiRes qw (usleep sleep);


our @ISA = ("Lab::Instrument::Multimeter");

our %fields = (
	supported_connections => [ 'GPIB', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
	},

	device_settings => {
		pl_freq => 50,
	},

);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	$self->write("END 2"); # or ERRSTR? and other queries will time out, unless using a line/message end character
	
	#$self->connection()->SetTermChar("\r\n");
	#$self->connection()->EnableTermChar(1);
	
	return $self;
}




sub configure_voltage_dc {
	my $self=shift;
    my $range=shift; # in V, or "AUTO", "MIN", "MAX"
    my $tint=shift;  # integration time in sec, "DEFAULT", "MIN", "MAX"
    
    if($range eq 'AUTO' || !defined($range)) {
    	$range='AUTO';
    }
    elsif($range =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	    #$range = sprintf("%e",abs($range));
    }
    elsif($range !~ /^(MIN|MAX)$/) {
    	Lab::Exception::CorruptParameter->throw( error => "Range has to be set to a decimal value or 'AUTO', 'MIN' or 'MAX' in " . (caller(0))[3] . "\n" );	
    }
    
    if($tint eq 'DEFAULT' || !defined($tint)) {
    	$tint=10;
    }
    elsif($tint =~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && ( ($tint>=0 && $tint<=1000) || $tint==-1 ) ) {
    	# Convert seconds to PLC (power line cycles)
    	$tint*=$self->pl_freq(); 
    }
    elsif($tint =~ /^MIN$/) {
    	$tint = 0;
    }
    elsif($tint =~ /^MAX$/) {
    	$tint = 1000;
    }
    elsif($tint !~ /^(MIN|MAX)$/) {
		Lab::Exception::CorruptParameter->throw( error => "Integration time has to be set to a positive value or 'AUTO', 'MIN' or 'MAX' in " . (caller(0))[3] . "\n" )    	
    }
    
	# do it
	$self->write( "FUNC DCV ${range}" );
	$self->write( "NPLC ${tint}" );
	
	# look for errors
	my ($errcode, $errmsg) = $self->get_error();
	if($errcode) {
		my $command = "FUNC DCV ${range}\nNPLC ${tint}";
		Lab::Exception::DeviceError->throw(
			error => "Error from device in " . (caller(0))[3] . ", the received error is '${errcode},${errmsg}'\n",
			code => $errcode,
			message => $errmsg,
			command => $command
		)
	}
}

sub configure_voltage_dc_trigger {
	my $self=shift;
    my $range=shift; # in V, or "AUTO", "MIN", "MAX"
    my $tint=shift;  # integration time in sec, "DEFAULT", "MIN", "MAX"
    my $count=shift;
    my $delay=shift; # in seconds, 'MIN'
    
    $count=1 if !defined($count);
    Lab::Exception::CorruptParameter->throw( error => "Sample count has to be an integer between 1 and 512\n" )
    	if($count !~ /^[0-9]*$/ || $count < 1 || $count > 16777215); 

	$delay=0 if !defined($delay);
    Lab::Exception::CorruptParameter->throw( error => "Trigger delay has to be a positive decimal value\n" )
    	if($count !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
        

    $self->_configure_voltage_dc($range, $tint);

	#$self->write( "PRESET NORM" );
	$self->write( "INBUF ON" );
    $self->write( "TARM AUTO" );
    $self->write( "TRIG HOLD" );
    $self->write( "NRDGS $count, AUTO" );
    $self->write( "TIMER $delay");
    #$self->write( "TRIG:DELay:AUTO OFF");
	
	# look for errors
	my ($errcode, $errmsg) = $self->get_error();
	if($errcode) {
		my $command = "";
		Lab::Exception::DeviceError->throw(
			error => "Error from device in " . (caller(0))[3] . ", the received error is '${errcode},${errmsg}'\n",
			code => $errcode,
			message => $errmsg,
			command => $command
		)
	}
}

sub configure_voltage_dc_trigger_highspeed {
	my $self=shift;
    my $range=shift || 10; # in V, or "AUTO", "MIN", "MAX"
    my $tint=shift || 1.4e-6;  # integration time in sec, "DEFAULT", "MIN", "MAX". Default of 1.4e-6 is the highest possible value for 100kHz sampling.
    my $count=shift || 10000;
    my $delay=shift; # in seconds, 'MIN'

    if($range eq 'AUTO' || !defined($range)) {
    	$range='AUTO';
    }
    elsif($range =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	    #$range = sprintf("%e",abs($range));
    }
    elsif($range !~ /^(MIN|MAX)$/) {
    	Lab::Exception::CorruptParameter->throw( error => "Range has to be set to a decimal value or 'AUTO', 'MIN' or 'MAX' in " . (caller(0))[3] . "\n" );	
    }
    
    if($tint eq 'DEFAULT' || !defined($tint)) {
    	$tint=1.4e-6;
    }
    elsif($tint =~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && ( ($tint>=0 && $tint<=1000) || $tint==-1 ) ) {
    	# Convert seconds to PLC (power line cycles)
    	#$tint*=$self->pl_freq(); 
    }
    elsif($tint =~ /^MIN$/) {
    	$tint = 0;
    }
    elsif($tint =~ /^MAX$/) {
    	$tint = 1000;
    }
    elsif($tint !~ /^(MIN|MAX)$/) {
		Lab::Exception::CorruptParameter->throw( error => "Integration time has to be set to a positive value or 'AUTO', 'MIN' or 'MAX' in " . (caller(0))[3] . "\n" )    	
    }

    $count=1 if !defined($count);
    Lab::Exception::CorruptParameter->throw( error => "Sample count has to be an integer between 1 and 512\n" )
    	if($count !~ /^[0-9]*$/ || $count < 1 || $count > 16777215); 

	$delay=0 if !defined($delay);
    Lab::Exception::CorruptParameter->throw( error => "Trigger delay has to be a positive decimal value\n" )
    	if($count !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);

	$self->write( "PRESET FAST" );
    $self->write( "TARM HOLD");
	$self->write( "APER ".$tint );
    $self->write( "MFORMAT SINT" );
    $self->write( "OFORMAT SINT" );
    $self->write( "MEM FIFO" );
    $self->write( "NRDGS $count, AUTO" );
    #$self->write( "TIMER $delay") if defined($delay);	

}
	

sub triggered_read {
    my $self=shift;
	my $args=undef;
	if (ref $_[0] eq 'HASH') { $args=shift }
	else { $args={@_} }
	
	$args->{'timeout'} = $args->{'timeout'} || $self->timeout();

    my $value = $self->query( "TARM SGL");

    chomp $value;

    my @valarray = split("\n",$value);

    return @valarray;
}


sub triggered_read_raw {
    my $self=shift;
	my $args=undef;
	if (ref $_[0] eq 'HASH') { $args=shift }
	else { $args={@_} }
	
	my $read_until_length=$args->{'read_until_length'};
	my $value='';
	my $fragment=undef;
	
	{
		use bytes;
		$value=$self->query( "TARM SGL", $args);
		my $tmp=length($value);
		while(defined $read_until_length && length($value)<$read_until_length) {
			$value .= $self->read($args);
		}
	}
	
    return $value;
}

sub decode_SINT {
	use bytes;
    my $self=shift;
	my $args=undef;
	my $bytestring=shift;
	my $iscale=shift || $self->query('ISCALE?');
	if (ref $_[0] eq 'HASH') { $args=shift }
	else { $args={@_} }
	
	my @values = split( //, $bytestring);
	my $ival=0;
	my $val_revb=0;
	my $tbyte=0;
	my $value=0;
	my @result_list=();
	my $i=0;
	for(my $v=0; $v<$#values;$v+=2) {
		$ival = unpack('S',join('',$values[$v],$values[$v+1]));

		$val_revb = 0;
		for ($i=0; $i<2; $i++) {
			$val_revb = $val_revb | (($ival>>$i*8 & 0x000000FF)<<((1-$i)*8));
		}

		my $decval=0;
		my $msb = ( $val_revb>>15 ) & 0x0001;
		$decval = $msb==0 ? 0 : -1*($msb**15);
		for($i=14;$i>=0;$i--) {
			$decval += ((($val_revb>>$i)&0x0001)*2)**$i;
		}
		push(@result_list,$decval*$iscale);
	}
	return @result_list;
}


sub autozero {
	my $self=shift;
	my $enable=shift;
	my $az_status=undef;
	my $command = "";
	
	if(!defined $enable) {
		# read autozero setting
		$command = "AZERO?";
		$az_status=$self->query( $command );
	}
	else {
		if ($enable =~ /^ONCE$/i) {
			$command = "AZERO ONCE";
		}
		elsif($enable =~ /^(ON|1)$/i) {
			$command = "AZERO ON";
		}
		elsif($enable =~ /^(OFF|0)$/i) {
			$command = "AZERO OFF";
		}
		else {
			Lab::Exception::CorruptParameter->throw( error => (caller(0))[3] . " can be set to 'ON'/1, 'OFF'/0 or 'ONCE'. Received '${enable}'\n" );
		}
		$self->write( $command );
	}	
	
	# look for errors
	my ($errcode, $errmsg) = $self->get_error();
	if($errcode) {
		Lab::Exception::DeviceError->throw(
			error => "Error from device in " . (caller(0))[3] . ", the received error is '${errcode},${errmsg}'\n",
			code => $errcode,
			message => $errmsg,
			command => $command
		)
	}
	
	return $az_status;
}


sub get_voltage_dc {
    my $self=shift;
    return $self->query("DCV");
}

sub set_nplc {
    my $self=shift;
    my $n=shift;   
    $self->write("NPLC $n");
}

sub selftest {
    my $self=shift;
    $self->write("TEST");
}

sub autocalibration {
    my $self=shift;
    my $mode=shift;
    
    if($mode !~ /^(ALL|0|DCV|1|DIG|2|OHMS|4)$/i) {
    	Lab::Exception::CorruptParameter->throw("preset(): Illegal preset mode given: $mode\n");
    }    
    
    $self->write("ACAL \U$mode\E");
}

sub reset {
    my $self=shift;
    $self->write("PRESET NORM");
}

sub set_display_state {
    my $self=shift;
    my $value=shift;
    if($value==1 || $value =~ /on/i ) {
    	$self->write("DISP ON");
    }
    elsif($value==0 || $value =~ /off/i ) {
    	$self->write("DISP OFF");
    }
    else {
    	Lab::Exception::CorruptParameter->throw( "set_display_state(): Illegal parameter.\n" );
    }
}

sub display_clear {
    my $self=shift;
    $self->write("DISP CLR");
}

sub set_display_text {
    my $self=shift;
    my $text=shift;
    if( $text !~ /^[A-Za-z0-9\ \!\#\$\%\&\'\(\)\^\\\/\@\;\:\[\]\,\.\+\-\=\<\>\?\_]*$/ ) { # characters allowed by the 3458A
    	Lab::Exception::CorruptParameter->throw( "set_display_text(): Illegal characters in given text.\n" );
    }
    $self->write("DISP MSG,\"$text\"");
}

sub beep {
    # It beeps!
    my $self=shift;
    $self->write("BEEP");
}

sub get_error {
	my $self=shift;
	my $error = $self->query( "ERRSTR?", brutal => 1 ); # brutal is a workaround for the moment - somehow ERRSTR? timeouts  	
	if($error !~ /\+0,/) {
		if ($error =~ /^\+?([0-9]*)\,\"?(.*)\"?$/m) {
			return ($1, $2); # ($code, $message)
		}
		else {
			Lab::Exception::DeviceError->throw("Reading the error status of the device failed in " . (caller(0))[3] . ". Something's going wrong here.\n");
		}
	}
	else {
		return undef;
	}
}

sub preset {
    # Sets HP3458A into predefined configurations
    # 0 Fast
    # 1 Norm
    # 2 DIG 
    my $self=shift;
    my $preset=shift;
    if($preset !~ /^(FAST|0|NORM|1|DIG|2)$/i) {
    	Lab::Exception::CorruptParameter->throw("preset(): Illegal preset mode given: $preset\n");
    }
    
    $self->write("PRESET \U$preset\E");
}

sub get_id {
    my $self=shift;
    return $self->query('*IDN?');
}


sub get_value {
    # Triggers one Measurement and Reads it
    my $self=shift;
    my $val=$self->query("TRIG SGL");
    chomp $val;
    return $val;
}


1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::HP3458A - Agilent 3458A Multimeter

=head1 SYNOPSIS

    use Lab::Instrument::HP3458A;
    
    my $dmm=new Lab::Instrument::HP3458A({
        gpib_board   => 0,
        gpib_address => 11,
    });
    print $dmm->get_voltage_dc();

=head1 DESCRIPTION

The Lab::Instrument::HP3458A class implements an interface to the Agilent / HP 
3458A digital multimeter. 

=head1 CONSTRUCTOR

    my $hp=new(%parameters);

=head1 METHODS

=head2 pl_freq
Parameter: pl_freq

	$hp->pl_freq($new_freq);
	$npl_freq = $hp->pl_freq();
	
Get/set the power line frequency at your location (50 Hz for most countries, which is the default). This
is the basis of the integration time setting (which is internally specified as a count of power
line cycles, or PLCs). The integration time will be set incorrectly if this parameter is set incorrectly.

=head2 get_voltage_dc

    $voltage=$hp->get_voltage_dc();

Make a dc voltage measurement.

=head2 configure_voltage_dc

	$hp->configure_voltage_dc($range, $integration_time);
	
Configure range and integration time for the following DCV measurements.

$range is a voltage or one of "AUTO", "MIN" or "MAX".
$integration_time is given in seconds or one of "DEFAULT", "MIN" or "MAX".

=head2 configure_voltage_dc_trigger

	$hp->configure_voltage_dc_trigger($range, $integration_time, $count, $delay);

Configures range, integration time, sample count and delay (between samples) for triggered
readings.

$range, $integration_time: see configure_voltage_dc().
$count is the sample count per trigger (integer).
$delay is the delay between the samples in seconds.

=head2 configure_voltage_dc_trigger_highspeed

	$hp->configure_voltage_dc_trigger_highspeed($range, $integration_time, $count, $delay);

Same as configure_voltage_dc_trigger, but configures the device for maximum measurement speed.
Values are transferred in SINT format and can be fetched and decoded using triggered_read_raw()
and decode_SINT().
This mode allows measurements of up to about 100 kSamples/second.

$range: see configure_voltage_dc().
$integration_time: integration time in seconds. The default is 1.4e-6.
$count is the sample count per trigger (integer).
$delay is the delay between the samples in seconds.

=head2 set_display_state
Parameter: display_state

    $hp->set_display_state(1/'on'/0/'off');

Turn the front-panel display on/off (1/0)

=head2 set_display_text
Parameter: display_text

    $hp->set_display_text($text);

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.

=head2 display_clear

    $hp->display_clear();

Clear the message displayed on the front panel.

=head2 beep

    $hp->beep();

Issue a single beep immediately.

=head2 get_error

    ($err_num,$err_msg)=$hp->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 set_nlpc

    $hp->set_nlcp($number);

Sets the integration time in units of power line cycles.

=head2 reset

    $hp->reset();

Reset the multimeter to its power-on configuration. Same as preset('NORM').

=head2 preset

    $hp->preset($config);

$config can be
  'FAST'  / 0
  'NORM'  / 1
  'DIG'   / 2 

Choose one of several configuration presets (0: fast, 1: norm, 2: DIG).

=head2 selftest

    $hp->selftest();

Starts the internal self-test routine.

=head2 autocalibration

    $hp->autocalibration($mode);

Starts the internal autocalibration. Warning... this procedure takes 11 minutes with the 'ALL' mode!

$mode can be
  'ALL'  / 0
  'DCV'  / 1
  'AC'   / 2
  'OHMS' / 4
each meaning the obvious. 


=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item * L<Lab::Instrument>

=item * L<Lab::Instrument::Multimeter>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2009-2011 David Kalok, Andreas K. Hüttel
            2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
