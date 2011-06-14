
package Lab::Instrument::HP34401A;

use strict;
use Scalar::Util qw(weaken);
use Lab::Instrument;
use Carp;
use Data::Dumper;


our @ISA = ("Lab::Instrument");

our %fields = (
	# SupportedConnections => [ 'GPIB', 'RS232' ],	# in principle RS232, too, but not implemented (yet)
	supported_connections => [ 'GPIB', 'VISA_GPIB', 'DEBUG' ],
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);	# sets $self->config
	$self->_construct(__PACKAGE__, \%fields); 	# this sets up all the object fields out of the inheritance tree.
												# also, it does generic connection setup.

	return $self;
}



#
# utility methods
#

sub read_resistance {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
	my $cmd=sprintf("MEASure:SCALar:RESIStance? %s,%s",$range,$resolution);
	my $value = $self->connection()->Query( command => $cmd );
    return $value;
}


sub read_voltage_dc {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:VOLTage:DC? %s,%s",$range,$resolution);
    my $value = $self->connection()->Query( command => $cmd );
    return $value;
}

sub read_voltage_ac {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:VOLTage:AC? %s,%s",$range,$resolution);
    my $value = $self->connection()->Query( command => $cmd );
    return $value;
}

sub read_current_dc {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:CURRent:DC? %s,%s",$range,$resolution);
    my $value = $self->connection()->Query( command => $cmd );
    return $value;
}

sub read_current_ac {
    my $self=shift;
    my ($range,$resolution)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:CURRent:AC? %s,%s",$range,$resolution);
    my $value = $self->connection()->Query( command => $cmd );
    return $value;
}

sub display_text {
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

sub display_on {
    my $self=shift;
    $self->connection()->Write( command => "DISPlay ON" );
}

sub display_off {
    my $self=shift;
    $self->connection()->Write( command => "DISPlay OFF" );
}

sub display_clear {
    my $self=shift;
    $self->connection()->Write( command => "DISPlay:TEXT:CLEar");
}

sub beep {
    my $self=shift;
    $self->connection()->Write( command => "SYSTem:BEEPer");
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


sub config_voltage {
    my $self=shift;
    my ($digits, $range, $counts)=@_;

    #set input resistance to >10 GOhm for the three highest resolution values 
    $self->connection()->Write( command => "INPut:IMPedance:AUTO ON");

    $digits = int($digits);
    $digits = 4 if $digits < 4;
    $digits = 6 if $digits > 6;
 
    if ($range < 0.1) {
      $range = 0.1;
    }
    elsif ($range < 1) {
      $range = 1;
    }
    elsif ($range < 10) {
      $range = 10;
    }
    elsif ($range < 100) {
      $range = 100;
    }
    else{
      $range = 1000;
    }

    my $resolution = (10**(-$digits))*$range;
    $self->connection()->Write( command => "CONF:VOLT:DC $range,$resolution");


    # calculate integration time, set it and prepare for output
 
    my $inttime = 0;

    if ($digits ==4) {
      $inttime = 0.4;
      $self->connection()->Write( command => "VOLT:NPLC 0.02");
    }
    elsif ($digits ==5) {
      $inttime = 4;
      $self->connection()->Write( command => "VOLT:NPLC 0.2");
    }
    elsif ($digits ==6) {
      $inttime = 200;
      $self->connection()->Write( command => "VOLT:NPLC 10");
      $self->connection()->Write( command => "ZERO:AUTO OFF");
    }

    my $retval = $inttime." ms";


    # triggering
    $self->connection()->Write( command => "TRIGger:SOURce BUS");
    $self->connection()->Write( command => "SAMPle:COUNt $counts");
    $self->connection()->Write( command => "TRIGger:DELay MIN");
    $self->connection()->Write( command => "TRIGger:DELay:AUTO OFF");

    return $retval;
}

sub read_with_trigger_voltage_dc {
    my $self=shift;

    $self->connection()->Write( command => "INIT");
    $self->connection()->Write( command => "*TRG");
    my $value = $self->connection()->Query( command => "FETCh?");

    chomp $value;

    my @valarray = split(",",$value);

    return @valarray;
}


sub scroll_message {
    use Time::HiRes (qw/usleep/);
    my $self=shift;
    my $message=shift || "            This perl instrument driver is copyright 2004/2005 by Daniel Schroeer.            ";
    for my $i (0..(length($message)-12)) {
        $self->display_text(sprintf "%12.12s",substr($message,$i));
        usleep(100000);
    }
    $self->display_clear();
}

sub id {
    my $self=shift;
    $self->connection()->Query( command => '*IDN?');
}

sub read_value {
    my $self=shift;
    my $value=$self->connection()->Query( command => 'READ?');
    chomp $value;
    return $value;
}

1;










=head1 NAME

Lab::Instrument::HP34401A - HP/Agilent 34401A digital multimeter

=head1 SYNOPSIS

  use Lab::Instrument::HP34401A;

  my $Agi = new Lab::Instrument::HP34401A({
    connection => new Lab::Connection::GPIB(
		gpib_address => 14,
	),
  }

This omits the connection option "GPIB_Board => 0" (default). More elaborate:

  my $Agi = new Lab::Instrument::HP34401A({
    connection => new Lab::Connection::GPIB(
		gpib_board => 0,
		gpib_address => 14,
	),
  }


Beware that only the first set of parameters specific to an individual GPIB board (or any bus hardware, really) gets used.
Settings for EOI assertion for example. Right now, this doesn't really matter because the options aren't there (or documented) yet.
Just keep it in mind.

If you know what you're doing or you have an exotic scenario you can use the connection parameter "IgnoreTwin => 1", but this
is discouraged - it will kill connector management and you might run into hardware/resource sharing issues.


=head1 DESCRIPTION

The Lab::Instrument::HP34401A class implements an interface to the 34401A digital multimeter by
Agilent (formerly HP). This module can also be used to address the newer 34410A and 34411A multimeters,
but doesn't include new functions. Use the Lab::Instrument::HP34411A class for full functionality.

=head1 CONSTRUCTOR

    my $Agi=new(\%options);

=head1 METHODS

=head2 read_resistance

    $resistance=$Agi->read_resistance($range,$resolution);

Preset and measure resistance with specified range and resolution.

=head2 read_voltage_dc

    $datum=$Agi->read_voltage_dc($range,$resolution);

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

=head2 read_voltage_ac

    $datum=$Agi->read_voltage_ac($range,$resolution);

Preset and make an ac voltage measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6 1/2 digits. The resolution parameter only affects the front-panel display.

=head2 read_current_dc

    $datum=$Agi->read_current_dc($range,$resolution);

Preset and make a dc current measurement with the specified range
and resolution.

=head2 read_current_ac

    $datum=$Agi->read_current_ac($range,$resolution);

Preset and make an ac current measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6 1/2 digits. The resolution parameter only affects the front-panel display.

=head2 config_voltage

    $inttime=$Agi->config_voltage($digits,$range,$count);

Configures device for measurement with specified number of digits (4 to 6), voltage range and number of data
points. Afterwards, data can be taken by triggering the multimeter, resulting in faster measurements than using
read_voltage_xx.
Returns string with integration time resulting from number of digits.

=head2 read_with_trigger_voltage_dc

    @array = $Agi->read_with_trigger_voltage_dc()

Take data points as configured with config_voltage(). returns an array.

=head2 display_on

    $Agi->display_on();

Turn the front-panel display on.

=head2 display_off

    $Agi->display_off();

Turn the front-panel display off.

=head2 display_text

    $Agi->display_text($text);
    print $Agi->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 display_clear

    $Agi->display_clear();

Clear the message displayed on the front panel.

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

=head2 id

    $id=$Agi->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

Copyright 2004-2006 Daniel Schröer (<schroeer@cpan.org>), 2009-2010 Daniela Taubert, 2011 Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
