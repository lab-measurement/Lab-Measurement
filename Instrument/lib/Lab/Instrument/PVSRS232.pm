package Lab::Instrument::PVSRS232;

use strict;
use Lab::Instrument;
use Lab::VISA;
use Time::HiRes qw (usleep);



# ------------------ INIT -------------------------

sub new {
    my $proto = shift;
    print "proto=$proto\n";
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
	if (ref($_[0]) eq 'Lab::Instrument::RS232')
		{
		print "Init Precision Voltage Source as RS232 device.\n";
		$self->{vi}=new Lab::Instrument(@_,'dummy_value');
		
		my $status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_BAUD, 9600);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
		
		$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_DATA_BITS, 8);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar: $status";}
		
		$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN,$Lab::VISA::VI_FALSE);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar: $status";}
		
		$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_FLOW_CNTRL, 0);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar enabled: $status";}
		
		$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_STOP_BITS, 10);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar enabled: $status";}
		
		$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_PARITY, 0);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar: $status";}
		
		$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR, 0x0A);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar: $status";}
		
#VI_ATTR_TMO_VALUE = 2000
#VI_ATTR_MAX_QUEUE_LENGTH = 50
#VI_ATTR_SEND_END_EN = VI_TRUE
#VI_ATTR_TERMCHAR = 0x0A
#VI_ATTR_TERMCHAR_EN = VI_FALSE
#VI_ATTR_IO_PROT = 1
#VI_ATTR_SUPPRESS_END_EN = VI_FALSE
#VI_ATTR_ASRL_BAUD = 9600
#VI_ATTR_ASRL_DATA_BITS = 8
#VI_ATTR_ASRL_PARITY = 0
#VI_ATTR_ASRL_STOP_BITS = 10
#VI_ATTR_ASRL_FLOW_CNTRL = 0
#VI_ATTR_ASRL_END_IN = 2
#VI_ATTR_ASRL_END_OUT = 0
#VI_ATTR_ASRL_DCD_STATE = 0
#VI_ATTR_ASRL_DTR_STATE = 1
#VI_ATTR_ASRL_RI_STATE = 0
#VI_ATTR_ASRL_RTS_STATE = 1
#VI_ATTR_ASRL_XON_CHAR = 0x11
#VI_ATTR_ASRL_XOFF_CHAR = 0x13
#VI_ATTR_ASRL_REPLACE_CHAR = 0x00
#VI_ATTR_DMA_ALLOW_EN = VI_FALSE
#VI_ATTR_FILE_APPEND_EN = VI_FALSE
#VI_ATTR_ASRL_DISCARD_NULL = VI_FALSE
#VI_ATTR_ASRL_BREAK_STATE = 0
#VI_ATTR_ASRL_BREAK_LEN = 250
#VI_ATTR_ASRL_ALLOW_TRANSMIT = VI_TRUE
#VI_ATTR_ASRL_WIRE_MODE = 128

		$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_FALSE);
		if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar enabled: $status";}	
		#
		#$status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_END_IN, 	$Lab::VISA::VI_ASRL_END_TERMCHAR);
		#if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting end termchar: $status";}
		
		$self->{vi}->{config}->{RS232_Echo} = 'COMMAND';
		
		return $self
		}
		
	else
		{
		print "Init Precision Voltage Source as GPIB device.\n";
		$self->{vi}=new Lab::Instrument(@_);
		return $self;
		}
}

sub reset {

	my $self=shift;
	$self->{vi}->Write("ADF 1");
	}

sub _set_RS232_Parameter { # internal / advanced use only 
	my $self = shift;
	my $RS232_Parameter = shift;
	my $value = shift;
	
	return $self->{vi}->{config}->{RS232}->set_RS232_Parameter($RS232_Parameter, $value);

}



sub set_voltage{
    my $self=shift;
    my $channel=shift;
    my $voltage=shift;#V
    my $rate=shift;
    my $range=shift;
    if (not defined $channel || not defined $rate){
	die "Error in PVS set voltage channel or voltage not defined";
    }
    elsif (not defined $rate){
    $self->_set_voltage($channel,$voltage);
    }
    elsif( not defined $range){
    $self->_set_voltage($channel,$voltage);
    $self->_set_rate($rate);#V/s
    }
    elsif($range>1 && $range<10)
    {
    $self->_set_voltage($channel,$voltage);
    $self->_set_rate($rate);#V/s
    $self->_set_range($range);#V/s
    }
    my $val=$self->_get_voltage($channel);
    return $val;
    
}


sub _set_voltage {
    my $self=shift;
    my $channel=shift;
    my $voltage=shift;#V
    my $cmd=sprintf(":SOURce:VOLTage%i %.5f?", $channel,$voltage);

    $self->{vi}->Write($cmd);
    #usleep(100);
    #$cmd=sprintf(":SOURce:VOLTage%i?", $channel);
    #$self->{vi}->Query($cmd,100);
}

sub _set_rate{
    my $self=shift;
    my $rate=shift; #V/s
    $rate=$rate*1000.;
    my $cmd=sprintf(":CONFigure:RATE %4.2f", $rate);
    $self->{vi}->Write($cmd);
    $cmd=sprintf(":CONFigure:RATE?");
    $self->{vi}->Write($cmd,100);
}

sub _get_rate{
    my $self=shift;
    my $rate=shift; #V/s
    $rate=$rate*1000.;
    my $cmd=sprintf(":CONFigure:RATE?", $rate);
    $self->{vi}->Query($cmd);
    #usleep(100);
    #my $val=$self->{vi}->Read(300);
}

sub _set_range{
    my $self=shift;
    my $channel=shift;
    my $range=shift; #V
    my $cmd=sprintf(":CONFigure:RANGe%i %i", $channel, $range);
    $self->{vi}->Write($cmd);
}

sub set_range{
    my $self=shift;
    my $range=shift; #V
    my $cmd=sprintf(":CONFigure:RANGe: %i", $range);
    $self->{vi}->Write($cmd);
}


sub _get_voltage {
    my $self=shift;
    my $channel=shift;
    my $cmd=sprintf(":SOURce:VOLTage%i?", $channel);
    my $val=$self->{vi}->Query($cmd);
    $val =~ s/^[_,\\,\/]//;
    return $val;
}

sub _sweep_active {
    my $self=shift;
    my $channel=shift;
    usleep(1000);
    my $cmd=sprintf(":SOURce:VOLTage%i?", $channel);
    my $val=$self->{vi}->Query($cmd);
    if ($val=~m/^_/){$val=0}
    else{$val=1}
    return $val;
}

sub _get_current {
    my $self=shift;
    my $channel=shift;
    my $cmd=sprintf(":MEASure:CURRent%i", $channel);
    my $val=$self->{vi}->Query($cmd);
    $val =~ s/^[_,\\,\/]//;
    $val=$val/1000.;
    #print "val=$1\n";
    return $val;
}


sub set_output{
    my $self=shift;
    my $channel=shift;
    my $onoff=shift;
    if (not defined $channel || not defined $onoff){
	die "Error in PVS no defined channel or defined on/off\n"
    }
    elsif ($onoff){
	my $tmp=$self->_get_output($channel);
	if ($tmp ==1)
	{print "Channel $channel Output already on\n"}
	else{
	$self->set_voltage($channel,0.);
	$self->_set_output($channel,1);
	usleep(100);
	my $val=$self->_get_output($channel);
	return $val;
	}
    }
    else{
	    my $tmp=$self->_get_output($channel);
	    if ($tmp ==0)
		{print "Channel Output already off\n";}
	    else{
		$self->set_voltage($channel,0.);
		$self->_set_output($channel,0);
		usleep(100);
		my $val=$self->_get_output($channel);
		return $val;
	    }

    }    
    
}

sub _set_output {
    my $self=shift;
    my $channel=shift;
    my $onoff=shift;
    if (not defined $channel || not defined $onoff){
	die "Error in PVS no defined channel or defined on/off\n"
    }
    elsif ($onoff){
	my $cmd=sprintf(":CONFigure:OUT%i ON", $channel);
	$self->{vi}->Write($cmd);
    }
    else{
	my $cmd=sprintf(":CONFigure:OUT%i OFF", $channel);
	$self->{vi}->Write($cmd);
    }
}

sub _get_output {
    my $self=shift;
    my $channel=shift;
    if (not defined $channel){
	die "Error in PVS no defined channel or defined on/off\n"
    }
    else{
	my $cmd=sprintf(":CONFigure:OUT%i?", $channel);
	my $val=$self->{vi}->Query($cmd);
	
	    if ($val=~m/OFF/g){
	    $val=0;
	    return $val}
	    elsif ($val=~m/ON/g){
	    $val=1;
	    return $val;}
	else{
	    die "Error in PVS no defined on/off return value\n"
	}
    }
}

sub _IDN {
    my $self=shift;
    my $val=$self->{vi}->Query("*IDN?",1000,100);
    print "value=$val\n";
    #my $cmd=sprintf(":SOURce:VOLTage?")
}
1;


=head1 NAME

	Lab::Instrument::SignalRecovery726x - Signal Recovery 7260 / 7265 Lock-in Amplifier

.

=head1 SYNOPSIS

	  use as GPIB-device

	---------------------

	use Lab::Instrument::SignalRecovery726x;
	my $SR = new Lab::Instrument::SignalRecovery726x(0,22);
	print $SR->get_value('XY');

.

	  use as RS232-device

	----------------------

	use Lab::Instrument::RS232;
	use Lab::Instrument::SignalRecovery726x;
	my $RS232 = new Lab::Instrument::RS232('ASRL1::INSTR');    # ASRL1::INSTR = COM 1, ASRL2::INSTR = COM 2, ...
	my $SR = new Lab::Instrument::SignalRecovery726x($RS232);
	print $SR->get_value('XY');

.

=head1 DESCRIPTION

The Lab::Instrument::SignalRecovery726x class implements an interface to the Signal Recovery 7260 / 7265 Lock-in Amplifier.
Note that the module Lab::Instrument::SignalRecovery726x can work via GPIB or RS232 interface.

.

=head1 CONSTRUCTOR

	my $SR = new(\%options);

.

=head1 METHODS

=head2 get_value

	$value=$SR->get_value($channel);

Makes a measurement using the actual settings.
The CHANNELS defined by $channel are returned as floating point values.
If more than one value is requested, they will be returned as an array.

=over 4

=item $channel

CHANNEL can be:

	  in floating point notation:

	-----------------------------

	'X'   --> X channel output\n 
	'Y'   --> Y channel output\n
	'MAG' --> Magnitude\n 
	'PHA' --> Signale phase\n 
	'XY'  --> X and Y channel output\n 
	'MP'  --> Magnitude and signal Phase\n 
	'ALL' --> X,Y, Magnitude and signal Phase\n

=back

.

=head2 config_measurement

	$SR->config_measurement($channel, $number_of_points, $interval, [$trigger]);

Preset the Signal Recovery 7260 / 7265 Lock-in Amplifier for a TRIGGERED measurement.

=over 4

=item $channel

CHANNEL can be:

	  in floating point notation:

	-----------------------------

	'X'   --> X channel output\n 
	'Y'   --> Y channel output\n 
	'MAG' --> Magnitude\n 
	'PHA' --> Signale phase\n 
	'XY'  --> X and Y channel output\n 
	'MP'  --> Magnitude and signal Phase\n 
	'ALL' --> X,Y, Magnitude and signal Phase\n

.

	  in percent of full range notation:

	------------------------------------

	'X-'   --> X channel output\n 
	'Y-'   --> Y channel output\n 
	'MAG-' --> Magnitude\n 
	'PHA-' --> Signale phase\n 
	'XY-'  --> X and Y channel output\n 
	'MP-'  --> Magnitude and signal Phase\n 
	'ALL-' --> X,Y, Magnitude and signal Phase\n

=over 4

=item $number_of_points

Preset the NUMBER OF POINTS to be taken for one measurement trace.
The single measured points will be stored in the internal memory of the Lock-in Amplifier.
For the Signal Recovery 7260 / 7265 Lock-in Amplifier the internal memory is limited to 32.000 values. 

	--> If you request data for the channels X and Y in floating point notation, for each datapoint three values have to be stored in memory (X,Y and Sensitivity).
	--> So you can store effectivly 32.000/3 = 10666 datapoints.
	--> You can force the instrument not to store additionally the current value of the Sensitivity setting by appending a '-' when you select the channels, eg. 'XY-' instead of simply 'XY'.
	--> Now you will recieve only values between -30000 ... + 30000 from the Lock-in, which is called the full range notation.
	--> You can calculate the measurement value by ($value/100)*Sensitivity. This is easy if you used only a single setting for Sensitivity during the measurement, and it's very hard if you changed the Sensitivity several times during the measurment or even used the auto-range function.

=item $interval

Preset the STORAGE INTERVAL in which datavalues will be stored during the measurement. 
Note: the storage interval is independent from the low pass filters time constant tc.


=item $trigger

Ooptional value. Presets the source where the trigger signal is expected.
	'EXT' --> external trigger source
	'INT' --> internal trigger source

DEF is 'INT'. If no value is given, DEF will be selected.

=back

.

=head2 trg

	$SR->trg();

Sends a trigger signal via the GPIB-BUS to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Signal Recovery 7260 / 7265 Lock-in Amplifier.

.

=head2 get_data

	@data = $SR->get_data(<$sensitivity>);

Reads all recorded values from the internal buffer and returns them as an (2-dim) array of floatingpoint values.

Example:

	requested channels: X --> $SR->get_data(); returns an 1-dim array containing the X-trace as floatingpoint-values
	requested channels: XY --> $SR->get_data(); returns an 2-dim array: 
		--> @data[0] contains an 1-dim array containing the X-trace as floatingpoint-values 
		--> @data[1] contains an 1-dim array containing the Y-trace as floatingpoint-values 

Note: Reading the buffer will not start before all predevined measurement values have been recorded.
The LabVisa-script cannot be continued until all requested readings have been recieved.

=over 4

=item $sensitivity

SENSITIVITY is an optional parameter. 
When it is defined, it will be assumed that the data recieved from the Lock-in are in full range notation. 
The return values will be calculated by $value = ($value/100)*$sensitifity.

=back

.

=head2 abort

	$SR->abort();

Aborts current (triggered) measurement.

.

=head2 wait

	$SR->wait();

Waits until current (triggered) measurement has been finished.

.

=head2 active

	$SR->active();

Returns '1' if  current (triggered) measurement is still running and '0' if current (triggered) measurement has been finished.

.

=head2 set_imode

	$SR->set_imode($imode);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $imode

	 $imode == 0  --> Current Mode OFF
	 $imode == 1  --> High Bandwidth Current Mode
	 $imode == 2  --> Low Noise Current Mode

=back

.

=head2 set_vmode

	$SR->set_vmode($vmode);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $vmode

	  $vmode == 0  --> Both inputs grounded (testmode)
	  $vmode == 1  --> A input only
	  $vmode == 2  --> -B input only
	  $vmode == 3  --> A-B differential mode

=back

.

=head2 set_fet

	$SR->set_fet($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  $value == 0 --> Bipolar device, 10 kOhm input impedance, 2nV/sqrt(Hz) voltage noise at 1 kHz
	  $value == 1 --> FET, 10 MOhm input impedance, 5nV/sqrt(Hz) voltage noise at 1 kHz

=back

.

=head2 set_float

	$SR->set_float($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  $value == 0 --> input conector shield set to GROUND
	  $value == 1 --> input conector shield set to FLOAT

=back

.

=head2 set_cp

	$SR->set_cp($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  $value == 0 --> input coupling mode AC\n
	  $value == 1 --> input coupling mode DC\n

=back

.

=head2 set_linefilter

	$SR->set_linefilter($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  LINE-FILTER == 0 --> OFF\n
	  LINE-FILTER == 1 --> enable 50Hz/60Hz notch filter\n
	  LINE-FILTER == 2 --> enable 100Hz/120Hz notch filter\n
	  LINE-FILTER == 3 --> enable 50Hz/60Hz and 100Hz/120Hz notch filter\n

=back

.

=head2 set_acgain

	$SR->set_acgain($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  AC-GAIN == 0 -->  0 dB gain of the signal channel amplifier\n
	  AC-GAIN == 1 --> 10 dB gain of the signal channel amplifier\n
	  ...
	  AC-GAIN == 9 --> 90 dB gain of the signal channel amplifier\n
=back

.

=head2 set_sen

	$SR->set_sen($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  SENSITIVITY (IMODE == 0) --> 2nV, 5nV, 10nV, 20nV, 50nV, 100nV, 200nV, 500nV, 1uV, 2uV, 5uV, 10uV, 20uV, 50uV, 100uV, 200uV, 500uV, 1mV, 2mV, 5mV, 10mV, 20mV, 50mV, 100mV, 200mV, 500mV, 1V\n
	  SENSITIVITY (IMODE == 1) --> 2fA, 5fA, 10fA, 20fA, 50fA, 100fA, 200fA, 500fA, 1pA, 2pA, 5pA, 10pA, 20pA, 50pA, 100pA, 200pA, 500pA, 1nA, 2nA, 5nA, 10nA, 20nA, 50nA, 100nA, 200nA, 500nA, 1uA\n
	  SENSITIVITY (IMODE == 2) --> 2fA, 5fA, 10fA, 20fA, 50fA, 100fA, 200fA, 500fA, 1pA, 2pA, 5pA, 10pA, 20pA, 50pA, 100pA, 200pA, 500pA, 1nA, 2nA, 5nA, 10nA\n

=back

.

=head2 set_refchannel

	$SR->set_refchannel($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  INT --> internal reference input mode\n
	  EXT LOGIC --> external rear panel TTL input\n
	  EXT --> external front panel analog input\n

=back

.

=head2 set_refpha

	$SR->set_refpha($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  REFERENCE PHASE can be between 0 ... 306°

=back

.

=head2 autophase

	$SR->autophase();

Trigger an autophase procedure

.

=head2 set_outputfilter_slope

	$SR->set_outputfilter_slope($value);

Preset Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	   6dB -->  6dB/octave slope of output filter\n
	  12dB --> 12dB/octave slope of output filter\n
	  18dB --> 18dB/octave slope of output filter\n
	  24dB --> 24dB/octave slope of output filter\n

=back

.

=head2 set_tc

	$SR->set_tc($value);

Preset the output(signal channel) low pass filters time constant tc of the Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  Filter Time Constant: 
	10us, 20us, 40us, 80us, 160us, 320us, 640us, 5ms, 10ms, 20ms, 50ms, 100ms, 200ms, 500ms, 1s, 2s, 5s, 10s, 20s, 50s, 100s, 200s, 500s, 1ks, 2ks, 5ks, 10ks, 20ks, 50ks, 100ks\n

=back

.

=head2 set_osc

	$SR->set_osc($value);

Preset the oscillator output voltage of the Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  OSCILLATOR OUTPUT VOLTAGE can be between 0 ... 5V in steps of 1mV (Signal Recovery 7260) and 1uV (Signal Recovery 7265)

=back

.

=head2 set_frq

	$SR->set_frq($value);

Preset the oscillator frequency of the Signal Recovery 7260 / 7265 Lock-in Amplifier

=over 4

=item $value

	  OSCILLATOR FREQUENCY can be between 0 ... 259kHz

=back

.

=head2 display_on

	$SR->display_on();

.

=head2 display_off

	$SR->display_on();

.

=head2 reset

	$SR->reset();

.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

2011 Stefan Geissler