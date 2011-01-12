#
# Driver for SIKA TLK43 controller with RS485 MODBUS-RTU interface
# (over RS232)
#

package Lab::Instrument::TLK43;

use strict;
use Lab::Instrument;
use Lab::Connection;
use Lab::Connection::RS232;
use Data::Dumper;
use Carp;

our $VERSION = sprintf("0.%04d", q$Revision: 720 $ =~ / (\d+) /);
our @ISA = ("Lab::Instrument");

my %fields = (
	SupportedConnections => [ 'MODBUS' ],
	InstrumentHandle => undef,

	MemTable => {
		Measurement => 			0x0200,		# measured value
		Decimal => 				0x0201,		# decimal points dp
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

		nSP =>					0x2800,		# number of programmable setpoints
		SPAt =>					0x2801,		# selects active setpoint
		SP1 =>					0x2802,		# setpoint 1
		SP2 =>					0x2803,		# setpoint 2
		SP3 =>					0x2804,		# setpoint 3
		SP4 =>					0x2805,		# setpoint 4
		SPLL  =>				0x2806,		# low setpoint limit
		SPHL =>					0x2807,		# high setpoint limit
		HCFG =>					0x2808,		# type of input with universal input configuration
		SEnS =>					0x2809,		# type of sensor (depends on HCFG)
		rEFL =>					0x2857,		# coefficient of reflection
		SSC =>					0x280A,		# start of scale
		FSC =>					0x280B,		# full scale deflection
		dp =>					0x280C,		# decimal points (for measurement)



											# to be continued
		
	}
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);	# sets $self->Config
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;

	# SlaveAddress checken - nimmt nicht volle 256

	# check the configuration hash for a valid connection object or connection type, and set the connection
	if( defined($self->Config()->{'Connection'}) ) {
		if($self->_checkconnection($self->Config()->{'Connection'})) {
			$self->Connection($self->Config()->{'Connection'});
		}
		else { croak('Given Connection not supported'); }
	}
	else {
		print "Conntype: " . $self->Config()->{'ConnType'} . "\n";
		if($self->_checkconnection($self->Config()->{'ConnType'})) {
			my $ConnType = $self->Config()->{'ConnType'};
			my $Port = $self->Config()->{'Port'};
			my $SlaveAddress = $self->Config()->{'SlaveAddress'};
			my $Interface = "";
			$Interface = 'RS232' if($ConnType eq 'MODBUS');	# Todo: add connection checks
			$self->Connection(eval("new Lab::Connection::$ConnType( {Interface => '$Interface', Port => '$Port', SlaveAddress => $SlaveAddress} )")) || croak('Failed to create connection');
		}
		else { croak('Given Connection Type not supported'); }
	}
	$self->InstrumentHandle( $self->Connection()->InstrumentNew(SlaveAddress => $self->Config()->{'SlaveAddress'}) );

	return $self;
}



sub read_temperature {
	my $self=shift;
	my @Result = ();
	my $Temp = undef;
	my $dp = 0;
	return undef unless defined($dp = $self->read_address_int('dp'));

	return undef unless defined($Temp = $self->read_address_int( $self->MemTable()->{'Measurement'} ));

	return $Temp / 10**$dp;
}



sub set_setpoint { # { Slot => (1..4), Value => Int }
	my $self=shift;
	my $args=shift;
	my $TargetTemp = sprintf("%f",$args->{'Value'});
	my $Slot = $args->{'Slot'};
	my $nSP = 1;
	my $dp = 0;

	return undef unless defined($nSP = $self->read_address_int('nSP'));
	return undef unless defined($dp = $self->read_address_int('dp'));

	if ($Slot > $nSP || $Slot < 1) {
		return undef;
	}
	else {
		$TargetTemp *= 10**$dp;
		$TargetTemp = sprintf("%.0f",$TargetTemp);
		return $self->write_address({ MemAddress => $self->MemTable()->{'Setpoint'}+$Slot-1, MemValue => $TargetTemp });
	}
}


sub set_active_setpoint { # $value
	my $self=shift;
	my $TargetTemp = sprintf("%f",shift);
	my $Slot = 1;
	my $dp = 0;
	return undef unless defined($Slot = $self->read_address_int('SPAt'));
	return undef unless defined($dp = $self->read_address_int('dp'));

	$TargetTemp *= 10**$dp;
	$TargetTemp = sprintf("%.0f",$TargetTemp);
	printf("Setpoint address: %X\n",$self->MemTable()->{'SP1'});
	print "Trying: self->write_address({ MemAddress => $self->MemTable()->{'SP1'}+$Slot-1, MemValue => $TargetTemp })\n";
	return $self->write_address({ MemAddress => $self->MemTable()->{'SP1'}+$Slot-1, MemValue => $TargetTemp });
}


sub set_setpoint_slot { # { Slot => (1..4) }
	my $self = shift;
	my $args = shift;
	my $Slot = int($args->{'Slot'}) || return undef;
	my $nSP = undef;
	return undef unless defined($nSP = $self->read_address_int('nSP'));

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
	my $MemAddress = shift || undef;
	if($MemAddress !~ /^[0-9]*$/) {
		$MemAddress = $self->MemTable()->{$MemAddress} || undef;
	}

	if(!$MemAddress || $MemAddress > 0xFFFF || $MemAddress < 0x0200) {
		return undef;
	}
	else {
		@Result = $self->Connection()->InstrumentRead($self->InstrumentHandle(), {Function => 3, MemAddress => $MemAddress, MemCount => 1});
		if(scalar(@Result)==2) { # correct answer has to be two bytes long
			return ( $Result[0] << 8) + $Result[1];
		}
		else {
			return undef;
		}
	}
}


sub write_address {	# { MemAddress => Address (16bit), MemValue => Value (16 bit word) }
	my $self = shift;
	my $args = shift;
	my $MemAddress = int($args->{MemAddress}) || undef;
	my $MemValue = int($args->{MemValue}) || undef;
	if($MemAddress !~ /^[0-9]*$/) {
		$MemAddress = $self->MemTable()->{$MemAddress} || undef;
	}

	if(!$MemAddress || !$MemValue || $MemAddress > 0xFFFF || $MemAddress < 0x0200 || $MemValue > 0xFFFF || $MemValue < 0) {
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
have to be equipped with the optional RS485 interface. The device can be fully programmed using RS485 or RS232 and an interface
converter (e.g. "GRS 485 ISO" RS232- RS485 Converter)


=head1 CONSTRUCTOR

    my $tlk=new(\%options);

=head1 METHODS

	

	sub 

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
set_setpoint() will cut off the decimal values according to the value of the "dp" parameter of the device.
(dp=0..3 meaning 0..3 decimal points. only 0,1 work for temperature sensors)

=back


=head2 set_active_setpoint

    $success=$tlk->set_active_setpoint($Value);

Set the value of the currently active setpoint slot.

=over 4

=item $Value

Float value to set the setpoint to. Internally this is held by a 16bit number.
set_setpoint() will cut off the decimal values according to the value of the "dp" parameter of the device.
(dp=0..3 meaning 0..3 decimal points. only 0,1 work for temperature sensors)

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

This is $Id: TLK43.pm 722 2011-01-12Z F. Olbrich $

Copyright 2010 Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
