#!/usr/bin/perl

package Lab::Instrument::HP34401A;
our $VERSION = '2.93';

use strict;
use Scalar::Util qw(weaken);
use Lab::Instrument;
use Carp;
use Data::Dumper;
use Lab::Instrument::Multimeter;


our @ISA = ("Lab::Instrument::Multimeter");

our %fields = (
	supported_connections => [ 'GPIB', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
	},

	device_settings => { 
		plc_freq => 50,
	},

);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	return $self;
}


# 
# first, all internal stuff
# 



#
# all methods that fill in general Multimeter methods
#

sub _display_text {
    my $self=shift;
    my $text=shift;
    
    if ($text) {
        $self->connection()->Write( command => qq(DISPlay:TEXT "$text"));
    } else {
        chomp($text=$self->connection()->Query( command => qq(DISPlay:TEXT?) ));
        $text=~s/\"//g;
    }
    return $text;
}

sub _display_on {
    my $self=shift;
    $self->connection()->Write( command => "DISPlay ON" );
}

sub _display_off {
    my $self=shift;
    $self->connection()->Write( command => "DISPlay OFF" );
}

sub _display_clear {
    my $self=shift;
    $self->connection()->Write( command => "DISPlay:TEXT:CLEar");
}

sub _id {
    my $self=shift;
    return $self->query('*IDN?');
}

sub _get_value {
    my $self=shift;
    my $value=$self->query('READ?');
    chomp $value;
    return $value;
}

sub _configure_voltage_measurement{
    my $self=shift;
    my $range=shift; # in V, or "AUTO"
    my $tint=shift;  # in sec
    
    # supported by this dmm:
    # range:  AUTO, 100 mV, 1 V, 10 V, 100 V, 1000 V
    # integration time:  0.02, 0.2, 1, 10, or 100 power line cycles
    #   we assume 50Hz as used in decent countries -> 1 plc = 0.02 sec
    #   -> 0.4ms, 4ms, 20ms 0.2s, 2s
    
    $tint/=0.02;
    
    

    # unfinished :)
    die "configure_voltage_measurement not yet implemented for this instrument\n";
}



#
# all methods that are called directly
#


sub get_resistance {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
	my $cmd=sprintf("MEASure:SCALar:RESIStance? %s,%s",$range,$resolution);
	my $value = $self->query($cmd);
    return $value;
}


sub get_4wresistance {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
	my $cmd=sprintf("MEASure:SCALar:FRESIStance? %s,%s",$range,$resolution);
	my $value = $self->query($cmd);
    return $value;
}


sub get_voltage_dc {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:VOLTage:DC? %s,%s",$range,$resolution);
    my $value = $self->query($cmd);
    return $value;
}


sub get_voltage_ac {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:VOLTage:AC? %s,%s",$range,$resolution);
    my $value = $self->query($cmd);
    return $value;
}


sub get_current_dc {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:CURRent:DC? %s,%s",$range,$resolution);
    my $value = $self->query($cmd);
    return $value;
}


sub get_current_ac {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:CURRent:AC? %s,%s",$range,$resolution);
    my $value = $self->query($cmd);
    return $value;
}

sub beep {
    my $self=shift;
    $self->write("SYSTem:BEEPer");
}

sub get_error {
    my $self=shift;
    chomp(my $err=$self->connection()->Query( command => "SYSTem:ERRor?"));
    my ($err_num,$err_msg)=split ",",$err;
    $err_msg=~s/\"//g;
    return ($err_num,$err_msg);
}

sub reset {
    my $self=shift;
    $self->connection()->Write( command => "*CLS");
    $self->connection()->Write( command => "*RST");
#	$self->connection()->InstrumentClear($self->instrument_handle());
}

sub autozero {
	my $self=shift;
	my $enable=shift;
	my $az_status=undef;
	my $command = "";
	
	if(!defined $enable) {
		# read autozero setting
		$command = "ZERO:AUTO?";
		$az_status=$self->query( $command );
	}
	else {
		if ($enable =~ /^ONCE$/i) {
			$command = "ZERO:AUTO ONCE";
		}
		elsif($enable =~ /^(ON|1)$/i) {
			$command = "ZERO:AUTO ONCE";
		}
		elsif($enable =~ /^(OFF|0)$/i) {
			$command = "ZERO:AUTO OFF";
		}
		else {
			Lab::Exception::CorruptParameter->throw( error => "HP34401A::autozero() can be set to 'ON'/1, 'OFF'/0 or 'ONCE'. Received '${enable}'\n" . Lab::Exception::Base::Appendix() );
		}
		$self->write( $command );
	}	
	
	# look for errors
	my ($errcode, $errmsg) = $self->_check_device_error();
	if($errcode) {
		Lab::Exception::DeviceError->throw(
			error => "Error from device in HP34401A::autozero(), the received error is '${errcode},${errmsg}'\n" . Lab::Exception::Base::Appendix(),
			code => $errcode,
			message => $errmsg,
			command => $command
		)
	}
	
	return $az_status;
}

sub _configure_voltage_dc {
	my $self=shift;
    my $range=shift; # in V, or "AUTO", "MIN", "MAX"
    my $tint=shift;  # integration time in sec, "DEFAULT", "MIN", "MAX"
    my $res_cmd='';
    
    if($range eq 'AUTO' || !defined($range)) {
    	$range='DEF';
    }
    elsif($range =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	    #$range = sprintf("%e",abs($range));
    }
    elsif($range !~ /^(MIN|MAX)$/) {
    	Lab::Exception::CorruptParameter->throw( error => "Range has to be set to a decimal value or 'AUTO', 'MIN' or 'MAX' in HP34401A::configure_voltage_dc()\n" . Lab::Exception::Base::Appendix() );	
    }
    
    if($tint eq 'DEFAULT' || !defined($tint)) {
    	$res_cmd=',DEF';
    }
    elsif($tint =~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
    	# Convert seconds to PLC (power line cycles)
    	$tint*=$self->plc_freq(); 
    }
    elsif($tint !~ /^(MIN|MAX)$/) {
		Lab::Exception::CorruptParameter->throw( error => "Integration time has to be set to a positive value or 'AUTO', 'MIN' or 'MAX' in HP34401A::configure_voltage_dc()\n" . Lab::Exception::Base::Appendix() )    	
    }
    
	# do it
	$self->write( "CONF:VOLT:DC ${range} ${res_cmd}" );
	$self->write( "VOLT:DC:NPLC ${tint}" ) if $res_cmd eq ''; # integration time implicitly set through resolution
	
	# look for errors
	my ($errcode, $errmsg) = $self->_check_device_error();
	if($errcode) {
		my $command = "CONF:VOLT:DC ${range} ${res_cmd}";
		$command .= "\nVOLT:DC:NPLC ${tint}" if $res_cmd eq '';
		Lab::Exception::DeviceError->throw(
			error => "Error from device in HP34401A::configure_voltage_dc(), the received error is '${errcode},${errmsg}'\n" . Lab::Exception::Base::Appendix(),
			code => $errcode,
			message => $errmsg,
			command => $command
		)
	}
}

sub _configure_voltage_dc_trigger {
	my $self=shift;
    my $range=shift; # in V, or "AUTO", "MIN", "MAX"
    my $tint=shift;  # integration time in sec, "DEFAULT", "MIN", "MAX"
    my $count=shift;
    my $delay=shift; # in seconds, 'MIN'
    
    $count=1 if !defined($count);
    Lab::Exception::CorruptParameter->throw( error => "Sample count has to be an integer between 1 and 512\n" . Lab::Exception::Base::Appendix() )
    	if($count !~ /^[0-9]*$/ || $count < 1 || $count > 512); 

	$delay=0 if !defined($delay);
    Lab::Exception::CorruptParameter->throw( error => "Trigger delay has to be a positive decimal value\n" . Lab::Exception::Base::Appendix() )
    	if($count !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
        

    $self->_configure_voltage_dc($range, $tint);
        
    $self->write( "TRIG:SOURce BUS" );
    $self->write( "SAMPle:COUNt $count");
    $self->write( "TRIG:DELay $delay");
    $self->write( "TRIG:DELay:AUTO OFF");
}
	

sub _triggered_read {
    my $self=shift;
	my $args=undef;
	if (ref $_[0] eq 'HASH') { $args=shift }
	else { $args={@_} }
	
	$args->{'timeout'} = $args->{'timeout'} || $self->timeout();

    $self->write( "INIT" );
    $self->write( "*TRG");
    my $value = $self->query( "FETCh?", $args);

    chomp $value;

    my @valarray = split(",",$value);

    return @valarray;
}


sub scroll_message {
    use Time::HiRes (qw/usleep/);
    my $self=shift;
    my $message=shift || "            Lab::Measurement - designed to make measuring fun!            ";
    for my $i (0..(length($message)-12)) {
        $self->display_text(sprintf "%12.12s",substr($message,$i));
        usleep(100000);
    }
    $self->display_clear();
}


#
# Check the error status of the device. Read the (first) error and return the code and message;
#
sub _check_device_error {
	my $self=shift;
	my $error = $self->query( "SYST:ERR?" );
	if($error !~ /\+0,/) {
		if ($error =~ /^(\+[0-9]*)\,(.*)$/) {
			return ($1, $2); # ($code, $message)
		}
		else {
			Lab::Exception::DeviceError->throw(
				error => "Reading the error status of the device failed in Instrument::HP34401A::_check_device_error(). Something's going wrong here.\n" . Lab::Exception::Base::Appendix(),
			)	
		}
	}
	else {
		return undef;
	}
}
1;



=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::HP34401A - HP/Agilent 34401A digital multimeter

=head1 SYNOPSIS

  use Lab::Instrument::HP34401A;
  
  my $Agi = new Lab::Instrument::HP34401A({
    connection => new Lab::Connection::GPIB(
		gpib_board => 0,
		gpib_address => 14,
	),
  }


=head1 DESCRIPTION

The Lab::Instrument::HP34401A class implements an interface to the 34401A digital 
multimeter by Agilent (formerly HP). This module can also be used to address the newer 
34410A and 34411A multimeters, but doesn't include new functions. Use the 
L<Lab::Instrument::HP34411A> class for full functionality (not ported yet).

=head1 CONSTRUCTOR

    my $Agi=new(\%options);

=head1 METHODS

=head2 autozero

    $hp->autozero($setting);

$setting can be 1/'ON', 0/'OFF' or 'ONCE'.

When set to "ON", the device takes a zero reading after every measurement.
"ONCE" perform one zero reading and disables the automatic zero reading.
"OFF" does... you get it.

=head2 configure_voltage_dc

    $hp->configure_voltage_dc($range, $integration_time);

Configures all the details of the device's DC voltage measurement function.

$range is a positive numeric value (the largest expected value to be measured) or one of 'MIN', 'MAX', 'AUTO'.
It specifies the largest value to be measured. You can set any value, but the HP/Agilent 34401A effectively uses
one of the values 0.1, 1, 10, 100 and 1000V.

$integration_time is the integration time in seconds. This implicitly sets the provided resolution.


=head2 pl_freq
Parameter: pl_freq

	$hp->pl_freq($new_freq);
	$npl_freq = $hp->pl_freq();
	
Get/set the power line frequency at your location (50 Hz for most countries, which is the default). This
is the basis of the integration time setting (which is internally specified as a count of power
line cycles, or PLCs). The integration time will be set incorrectly if this parameter is set incorrectly.

=head2 display_text

    $Agi->display_text($text);
    print $Agi->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.
Inherited from L<Lab::Instrument::Multimeter>

=head2 display_on

    $Agi->display_on();

Turn the front-panel display on.
Inherited from L<Lab::Instrument::Multimeter>

=head2 display_off

    $Agi->display_off();

Turn the front-panel display off.
Inherited from L<Lab::Instrument::Multimeter>

=head2 display_clear

    $Agi->display_clear();

Clear the message displayed on the front panel.
Inherited from L<Lab::Instrument::Multimeter>

=head2 id

    $id=$Agi->id();

Returns the instrument ID string.
Inherited from L<Lab::Instrument::Multimeter>

=head2 get_value

Inherited from L<Lab::Instrument::Multimeter>



=head2 get_resistance

    $resistance=$Agi->get_resistance($range,$resolution);

Preset and measure resistance with specified range and resolution.

=head2 get_voltage_dc

    $datum=$Agi->get_voltage_dc($range,$resolution);

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

=head2 get_voltage_ac

    $datum=$Agi->get_voltage_ac($range,$resolution);

Preset and make an ac voltage measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6 1/2 digits. The resolution parameter only affects the front-panel display.

=head2 get_current_dc

    $datum=$Agi->get_current_dc($range,$resolution);

Preset and make a dc current measurement with the specified range
and resolution.

=head2 get_current_ac

    $datum=$Agi->get_current_ac($range,$resolution);

Preset and make an ac current measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6 1/2 digits. The resolution parameter only affects the front-panel display.

=head2 beep

=head2 get_error

=head2 reset

=head2 config_voltage

    $inttime=$Agi->config_voltage($digits,$range,$count);

Configures device for measurement with specified number of digits (4 to 6), voltage range and number of data
points. Afterwards, data can be taken by triggering the multimeter, resulting in faster measurements than using
read_voltage_xx.
Returns string with integration time resulting from number of digits.

=head2 get_with_trigger_voltage_dc

    @array = $Agi->get_with_trigger_voltage_dc()

Take data points as configured with config_voltage(). returns an array.

=head2 scroll_message

    $Agi->scroll_message($message);

Scrolls the message C<$message> on the display of the HP.

=head2 beep

    $Agi->beep();

Issue a single beep immediately.

=head2 get_error

    ($err_num,$err_msg)=$Agi->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 reset

    $Agi->reset();

Reset the multimeter to its power-on configuration.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item * L<Lab::Instrument>

=item * L<Lab::Instrument::Multimeter>

=item * L<Lab::Instrument::HP3458A>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2004-2006 Daniel Schröer (<schroeer@cpan.org>), 2009-2010 Daniela Taubert, 
            2011 Florian Olbrich, Andreas Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
