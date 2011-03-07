#
# Driver for SIKA TLK43/42/41 controller with RS485 MODBUS-RTU interface
# (over RS232)
#

package Lab::Instrument::TLK43;

use strict;
use Lab::Instrument;
use Lab::Connection::MODBUS_RS232;
use feature "switch";
use Data::Dumper;
use Carp;

our $VERSION = sprintf("0.%04d", q$Revision: 720 $ =~ / (\d+) /);
our @ISA = ("Lab::Instrument");

my %fields = (
	SupportedConnections => [ 'MODBUS_RS232' ],
	InstrumentHandle => undef,
	SlaveAddress => undef,

	MemTable => {
		Measurement => 			0x0200,		# measured value
		Decimal => 				0x0201,		# decimal points dP
		CalculatedPower => 		0x0202,		# calculated power
		HeatingPower => 		0x0203,		# available heating power
		CoolingPower => 		0x0204,		# available cooling power
		State_Alarm1 => 		0x0205,		# state of alarm 1
		State_Alarm2 => 		0x0206,		# state of alarm 2
		State_Alarm3 => 		0x0207,		# state of alarm 3
		Setpoint		 =>		0x0208,		# current setpoint
		State_AlarmLBA =>		0x020A,		# state of alarm LBA
		State_AlarmHB =>		0x020B,		# state of alarm HB (heater break)
		CurrentHB_closed =>		0x020C,		# current for HB with closed circuit
		CurrentHB_open =>		0x020D,		# current for HB with open circuit
		State_Controller =>		0x020F,		# state of controller (0: Off, 1: auto. Reg., 2: Tuning, 3: man. Reg.
		PreliminaryTarget =>	0x0290,		# preliminary target value (TLK43)
		AnalogueRepeat =>		0x02A0,		# value to repeat on analogue output (TLK43)

		# SP group (parameters relative to setpoint)
		nSP =>					0x2800,		# number of programmable setpoints
		SPAt =>					0x2801,		# selects active setpoint
		SP1 =>					0x2802,		# setpoint 1
		SP2 =>					0x2803,		# setpoint 2
		SP3 =>					0x2804,		# setpoint 3
		SP4 =>					0x2805,		# setpoint 4
		SPLL  =>				0x2806,		# low setpoint limit
		SPHL =>					0x2807,		# high setpoint limit

		# InP group (parameters relative to the measure input)
		HCFG =>					0x2808,		# type of input with universal input configuration
		SEnS =>					0x2809,		# type of sensor (depends on HCFG)
		rEFL =>					0x2857,		# coefficient of reflection
		SSC =>					0x280A,		# start of scale
		FSC =>					0x280B,		# full scale deflection
		dP =>					0x280C,		# decimal points (for measurement)
		Unit =>					0x280D,		# 0=°C, 1=F
		FiL =>					0x280E,		# digital filter on input (OFF .. 20.0 sec)
		OFSt =>					0x2810,		# offset of measurement with dP decimal points (-1999..9999) ?
		rot =>					0x2811,		# rotation of the measuring straight line
		InE =>					0x2812,		# "OPE" functioning in case of measuring error (0=OR, 1=Ur, 2=OUr)
		OPE =>					0x2813,		# output power in case of measuring error (-100..100)
		dIF =>					0x2858,		# digital input function

		# O1 group (parameteres relative to output 1)
		O1F =>					0x2814,		# Functioning of output 1 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)
		Aor1 =>					0x2859,		# Beginning of analogue output 1 scale (0=0, 1=no_0)
		Ao1F =>					0x285A,		# Functioning of analogue output 1 (0=OFF, 1=inp, 2=err, 3=r.SP, 4=r.SEr)
		Ao1L =>					0x285B,		# Minimum reference for analogical output 1 for signal transmission (with dP, -1999..9999)
		A01H =>					0x285C,		# Maximum reference for analogical output 1 for signal transmission (with dP, A01L..9999)

		# O2 group (parameteres relative to output 2)
		O2F =>					0x2815,		# Functioning of output 2 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)
		Aor2 =>					0x285D,		# Beginning of analogue output 2 scale (0=0, 1=no_0)
		Ao2F =>					0x285E,		# Functioning of analogue output 2 (0=OFF, 1=inp, 2=err, 3=r.SP, 4=r.SEr)
		Ao2L =>					0x285F,		# Minimum reference for analogical output 2 for signal transmission (with dP, -1999..9999)
		A02H =>					0x2860,		# Maximum reference for analogical output 2 for signal transmission (with dP, A02L..9999)

		# O3 group (parameteres relative to output 3)
		O3F =>					0x2816,		# Functioning of output 3 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)
		Aor3 =>					0x2861,		# Beginning of analogue output 3 scale (0=0, 1=no_0)
		Ao3F =>					0x2862,		# Functioning of analogue output 3 (0=OFF, 1=inp, 2=err, 3=r.SP, 4=r.SEr)
		Ao3L =>					0x2863,		# Minimum reference for analogical output 3 for signal transmission (with dP, -1999..9999)
		A03H =>					0x2864,		# Maximum reference for analogical output 3 for signal transmission (with dP, A03L..9999)

		# O4 group (parameters relative to output 4)
		O4F =>					0x2817,		# Functioning of output 4 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)

		# Al1 group (parameteres relative to alarm 1
		OAL1 =>					0x2818,		# Output where alarm AL1 is addressed (0=OFF, 1=Out1, 2=Out2, 3=Out3, 4=Out4)
		AL1t =>					0x2819,		# Alarm AL1 type (0=LoAb, 1=HiAb, 2=LHAb, 3=LodE, 4=HidE, 5=LHdE)
		Ab1 =>					0x281A,		# Alarm AL1 functioning (0=no function, 1=alarm hidden at startup, 2=alarm delayed, 4=alarm stored, 8=alarm acknowledged
		AL1 =>					0x281B,		# Alarm AL1 threshold (with dP, -1999..9999)
		AL1L =>					0x281C,		# Low threshold band alarm AL1 or Minimum set alarm AL1 for high or low alarm (with dP, -1999..9999)
		AL1H =>					0x281D,		# High threshold band alarm AL1 or Maximum set alarm AL1 for high or low alarm (with dP, -1999..9999)
		HAL1 =>					0x281E,		# Alarm AL1 hysteresis (with dP, 0=OFF..9999)
		AL1d =>					0x281F,		# Activation delay of alarm AL1 (with dP, 9=OFF..9999sec)
		AL1i =>					0x2820,		# Alarm AL1 activation in case of measuring error (0=no, 1=yes)




											# to be continued
		
	},

	MemCache => {	# used by read_int_cached and write_int_cached to cache 16bit values
	},
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);	# sets $self->Config, configures parent class
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;

	return undef unless $self->SlaveAddress($self->Config()->{'SlaveAddress'});
	# check the configuration hash for a valid connection object or connection type, and set the connection
	if( defined($self->Config()->{'Connection'}) ) {
		if($self->_checkconnection($self->Config()->{'Connection'})) {
			$self->Connection($self->Config()->{'Connection'});
		}
		else { 
			warn('Given Connection not supported');
			return undef;
		}
	}
	else {
		if($self->_checkconnection($self->Config()->{'ConnType'})) {
			my $ConnType = $self->Config()->{'ConnType'};
			my $Port = $self->Config()->{'Port'};
			my $SlaveAddress = $self->Config()->{'SlaveAddress'};
			my $Interface = "";
			if($ConnType eq 'MODBUS_RS232') {
				$self->Config()->{'Interface'} = 'RS232';
				$self->Connection(new Lab::Connection::MODBUS_RS232( $self->Config() )) || croak('Failed to create connection');
				#$self->Connection(eval("new Lab::Connection::$ConnType( $self->Config() )")) || croak('Failed to create connection');
			}
			else {
				warn('Only RS232 connection type supported for now!\n');
				return undef;
			 }
		}
		else {
			warn('Given Connection Type not supported');
			return undef;
		}
	}

	$self->InstrumentHandle( $self->Connection()->InstrumentNew(SlaveAddress => $self->SlaveAddress()) );
	return $self;
}



sub read_temperature {
	my $self=shift;
	my @Result = ();
	my $Temp = undef;
	my $dP = 0;
	#return undef unless defined($dP = $self->read_int_cached({ MemAddress => 'dP' }));
	if(!defined($dP = $self->read_int_cached({ MemAddress => 'dP' }))) {
		print "Error in cached read of dP\n";
		return undef;
	}

	return undef unless defined($Temp = $self->read_address_int( $self->MemTable()->{'Measurement'} ));
	given( $Temp ) {
		when(10001) {
			warn("Warning: Measurement exception $Temp received. Sensor disconnected.\n");
			return undef;
		}
		when(10000) {
			warn("Warning: Measurement exception $Temp received. Measuring value underrange.\n");
			return undef;
		}
		when(-10000) {
			warn("Warning: Measurement exception $Temp received. Measuring value overrange.\n");
			return undef;
		}
		when(10003) {
			warn("Warning: Measurement exception $Temp received. Measured variable not available.\n");
			return undef;
		}
		default {
			return $Temp / 10**$dP;
		}
	}
}


sub read_int_cached { # { MemAddress => $MemAddress, ForceRead => (1,0) }
	my $self = shift;
	my $args = shift;
	my $MemAddress = $args->{'MemAddress'} || undef;
	my $ForceRead = $args->{'ForceRead'};
	if($MemAddress !~ /^[0-9]*$/) {
		$MemAddress = $self->MemTable()->{$MemAddress} || undef;
	}

	if( !$ForceRead && exists($self->MemCache()->{$MemAddress}) && defined($self->MemCache()->{$MemAddress}) ) {
		return $self->MemCache()->{$MemAddress};
	}
	else {
		return undef unless defined($self->MemCache()->{$MemAddress} = $self->read_address_int($MemAddress));
		return $self->MemCache()->{$MemAddress};
	}
}

sub write_int_cached {	# { MemAddress => $MemAddress, MemValue => $Value }  stores MemValue as number (int)
	my $self = shift;
	my $args = shift;
	my $MemAddress = $args->{MemAddress} || undef;
	my $MemValue = int($args->{MemValue}) || undef;
	if($MemAddress !~ /^[0-9]*$/) {
		$MemAddress = $self->MemTable()->{$MemAddress} || undef;
	}

	return undef unless $self->write_address({ MemAddress => $MemAddress, MemValue => $MemValue });
	return( ($self->MemCache()->{$MemAddress} = $MemValue) );
}


sub set_setpoint { # { Slot => (1..4), Value => Int }
	my $self=shift;
	my $args=shift;
	my $TargetTemp = $args->{'Value'};
	my $Slot = $args->{'Slot'};
	my $nSP = 1;
	my $dP = 0;

	return undef unless defined($nSP = $self->read_int_cached('nSP'));
	return undef unless defined($dP = $self->read_int_cached('dP'));

	if ($Slot > $nSP || $Slot < 1) { 
		return undef;
	}
	else {
		$TargetTemp = sprintf("%.${dP}f",$TargetTemp) * 10**$dP;	# rounding, shifting decimal places
		return undef if ($TargetTemp > 32767 || $TargetTemp < -32768);	# still fitting in a signed 16bit int?
		#$TargetTemp = ( $TargetTemp + 2**16  ) if $TargetTemp < 0;
		return $self->write_address({ MemAddress => $self->MemTable()->{'Setpoint'}+$Slot-1, MemValue => $TargetTemp });
	}
}


sub set_active_setpoint { # $value
	my $self=shift;
	my $TargetTemp = shift;
	my $Slot = 1;
	my $dP = 0;
	return undef unless defined($Slot = $self->read_int_cached({ MemAddress => 'SPAt' }));
	return undef unless defined($dP = $self->read_int_cached({ MemAddress => 'dP' }));

	$TargetTemp = sprintf("%.${dP}f",$TargetTemp) * 10**$dP;	# rounding, shifting decimal places
	return undef if ($TargetTemp > 32767 || $TargetTemp < -32768);	# still fitting in a signed 16bit int?
	#$TargetTemp = ( $TargetTemp + 2**16  ) if $TargetTemp < 0;
	return $self->write_address({ MemAddress => $self->MemTable()->{'SP1'}+$Slot-1, MemValue => $TargetTemp });
}


sub set_setpoint_slot { # { Slot => (1..4) }
	my $self = shift;
	my $args = shift;
	my $Slot = int($args->{'Slot'}) || return undef;
	my $nSP = undef;
	return undef unless defined($nSP = $self->read_int_cached('nSP'));

	if ($Slot > $nSP || $Slot < 1) {
		return undef;
	}
	else {
		return $self->write_address({ MemAddress => $self->MemTable()->{'SPAt'}, MemValue => $Slot });
	}
}


sub set_Precision {	# $Precision
	my $self = shift;
	my $precision = int(shift);

	return undef if ($precision < 0 || $precision > 3);
	return $self->write_address({ MemAddress => $self->MemTable()->{'sP'}, MemValue => $precision });
}


sub read_range { # { MemAddress => Address (16bit), MemCount => Count (8bit, (1..4), default 1)
	my $self = shift;
	my $args = shift;
	my $MemAddress = $args->{MemAddress} || undef;
	my $MemCount = $args->{MemCount} || 1;
	$MemCount = int($MemCount);
	if($MemAddress !~ /^[0-9]*$/) {
		$MemAddress = $self->MemTable()->{$MemAddress} || undef;
	}

	if(!$MemAddress || !$MemCount || $MemAddress > 0xFFFF || $MemAddress < 0x0200 || $MemCount > 4 || $MemCount <= 0) {
		return undef;
	}
	else {
		return $self->Connection()->InstrumentRead($self->InstrumentHandle(), {Function => 3, MemAddress => $MemAddress, MemCount => $MemCount});
	}
}


sub read_address_int { # $Address
	my $self = shift;
	my @Result = ();
	my $SignedValue = 0;
	my $MemAddress = shift || undef;
	if($MemAddress !~ /^[0-9]*$/) {
		$MemAddress = $self->MemTable()->{$MemAddress} || undef;
	}

	if(!$MemAddress || $MemAddress > 0xFFFF || $MemAddress < 0x0200) {
		print "Address invalid\n";
		return undef;
	}
	else {
		@Result = $self->Connection()->InstrumentRead($self->InstrumentHandle(), {Function => 3, MemAddress => $MemAddress, MemCount => 1});
		if(scalar(@Result)==2) { # correct answer has to be two bytes long
			$SignedValue = unpack('n!', join('', @Result));
		}
		else {
			warn "Error on connection level\n";
			return undef;
		}
	}
}


sub write_address {	# { MemAddress => Address (16bit), MemValue => Value (16 bit word) }
	my $self = shift;
	my $args = shift;
	my $MemAddress = $args->{MemAddress} || undef;
	my $MemValue = int($args->{MemValue}) || undef;
	
	if($MemAddress !~ /^[0-9]*$/) {
		$MemAddress = $self->MemTable()->{$MemAddress} || undef;
	}

	if( !$MemAddress || (!$MemValue && $MemValue != 0) || $MemAddress > 0xFFFF || $MemAddress < 0x0200 || $MemValue > 0xFFFF || $MemValue < 0) {
		return undef;
	}
	else {
		return $self->Connection()->InstrumentWrite($self->InstrumentHandle(), {Function => 6, MemAddress => $MemAddress, MemValue => $MemValue} );
	}
}



1;










=head1 NAME

Lab::Instrument::TLK43 - Electronic process controller TLKA41/42/43 (SIKA GmbH)

=head1 SYNOPSIS

    use Lab::Instrument::TLK43;
    
    my $tlk=new Lab::Instrument::TLK43({ Port => '/dev/ttyS0', SlaveAddress => 1, Baudrate => 19200, Parity => 'none', Databits => 8, Stopbits => 1, Handshake => 'none'  });

	or

	my $Connection = new Lab::Connection::MODBUS({ Port => '/dev/ttyS0', Interface => 'RS232', SlaveAddress => 1, Baudrate => 19200, Parity => 'none', Databits => 8, Stopbits => 1, Handshake => 'none' });
	my $tlk=new Lab::Instrument::TLK43({ Connection => $Connection });

    print $tlk->read_temperature();
	$tlk->set_setpoint(200);

=head1 DESCRIPTION

The Lab::Instrument::TLK43 class implements an interface to SIKA GmbH's TLK41/42/43 process controllers. The devices
have to be equipped with the optional RS485 interface. The device can be fully programmed using RS232 and an interface
converter (e.g. "GRS 485 ISO" RS232 - RS485 Converter).

The following parameter list configures the RS232 port correctly for a setup with the GRS485 converter and a speed of 19200 baud:
Port => '/dev/ttyS0', Interface => 'RS232', Baudrate => 19200, Parity => 'none', Databits => 8, Stopbits => 1, Handshake => 'none'


=head1 CONSTRUCTOR

    my $tlk=new(\%options);

=head1 METHODS
 

=head2 read_temperature

    $temp = read_temperature();

Returns the currently measured temperature, or undef on errors.


=head2 set_setpoint

    $success=$tlk->set_setpoint({ Slot => $Slot, Value => $Value })

Set the value of setpoint slot $Slot.

=over 4

=item $Slot

The TLK controllers provide 4 setpoint slots. $Slot has to be a number of (1..4) and may not
exceed the nSP-parameter set in the device (set_setpoint return undef in this case)

=item $Value

Float value to set the setpoint to. Internally this is held by a 16bit number.
set_setpoint() will cut off the decimal values according to the value of the "dP" parameter of the device.
(dP=0..3 meaning 0..3 decimal points. only 0,1 work for temperature sensors)

=back


=head2 set_active_setpoint

    $success=$tlk->set_active_setpoint($Value);

Set the value of the currently active setpoint slot.

=over 4

=item $Value

Float value to set the setpoint to. Internally this is held by a 16bit number.
set_setpoint() will cut off the decimal values according to the value of the "dP" parameter of the device.
(dP=0..3 meaning 0..3 decimal points. only 0,1 work for temperature sensors)

=back


=head2 read_range

    $value=$tlk->read_range({ MemAddresss => (0x0200..0xFFFF || Name), MemCount => (1..4) })

Read the values of $MemCount memory slots from $MemAddress on. The Address may be specified as a 16bit Integer in the valid range,
or as an address name (see TLK43.pm, %fields{'MemTable'}). $MemCount may be in the range 1..4.
Returns the memory as an array (one byte per field)


=head2 read_address_int

    $value=$tlk->read_range({ MemAddresss => (0x0200..0xFFFF || Name), MemCount => (1..4) })

Read the value of the 16bit word at $MemAddress on. The Address may be specified as a 16bit Integer in the valid range,
or as an address name (see TLK43.pm, %fields{'MemTable'}).
Returns the value as unsigned integer (internally (byte1 << 8) + byte2)



=head2 write_address

    $success=$tlk->write_address({ MemAddress => (0x0200...0xFFFF || Name), MemValue => Value (16 bit word) });

Write $Value to the given address. The Address may be specified as a 16bit Integer in the valid range,
or as an address name (see TLK43.pm, %fields{'MemTable'}).


=head2 set_setpoint_slot

    $success=$tlk->set_setpoint_slot({ Slot => $Slot })

Set the active setpoint to slot no. $Slot.

=over 4

=item $Slot

The TLK controllers provide 4 setpoint slots. $Slot has to be a number of (1..4) and may not
exceed the nSP-parameter set in the device (set_setpoint_slot return undef in this case)

=back


=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

Copyright 2010 Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
