#$Id$

package VISA::Instrument::HP34401A;

use strict;
use VISA::Instrument;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

	$self->{vi}=new VISA::Instrument(@_);

	return $self
}

sub read_voltage_dc {
	my $self=shift;
	my ($range,$resolution)=@_;
	
	$range="DEF" unless (defined $range);
	$resolution="DEF" unless (defined $resolution);
	
	my $cmd=sprintf("MEASure:VOLTage:DC? %u,%f",$range,$resolution);
	my ($value)=split "\n",$self->{vi}->Query($cmd);
	return $value;
}

sub read_voltage_ac {
	my $self=shift;
	my ($range,$resolution)=@_;
	
	$range="DEF" unless (defined $range);
	$resolution="DEF" unless (defined $resolution);
	
	my $cmd=sprintf("MEASure:VOLTage:AC? %u,%f",$range,$resolution);
	my ($value)=split "\n",$self->{vi}->Query($cmd);
	return $value;
}

sub read_current_dc {
	my $self=shift;
	my ($range,$resolution)=@_;
	
	$range="DEF" unless (defined $range);
	$resolution="DEF" unless (defined $resolution);
	
	my $cmd=sprintf("MEASure:CURRent:DC? %u,%f",$range,$resolution);
	my ($value)=split "\n",$self->{vi}->Query($cmd);
	return $value;
}

sub read_current_ac {
	my $self=shift;
	my ($range,$resolution)=@_;
	
	$range="DEF" unless (defined $range);
	$resolution="DEF" unless (defined $resolution);
	
	my $cmd=sprintf("MEASure:CURRent:AC? %u,%f",$range,$resolution);
	my ($value)=split "\n",$self->{vi}->Query($cmd);
	return $value;
}

sub display_text {
	my $self=shift;
	my $text=shift;
	
	if ($text) {
		$self->{vi}->Write(qq(DISPlay:TEXT "$text"));
	} else {
		chomp($text=$self->{vi}->Query(qq(DISPlay:TEXT?)));
		$text=~s/\"//g;
	}
	return $text;
}

sub display_on {
	my $self=shift;
	$self->{vi}->Write("DISPlay ON");
}

sub display_off {
	my $self=shift;
	$self->{vi}->Write("DISPlay OFF");
}

sub display_clear {
	my $self=shift;
	$self->{vi}->Write("DISPlay:TEXT:CLEar");
}

sub beep {
	my $self=shift;
	$self->{vi}->Write("SYSTem:BEEPer");
}

sub get_error {
	my $self=shift;
	chomp(my $err=$self->{vi}->Query("SYSTem:ERRor?"));
	my ($err_num,$err_msg)=split ",",$err;
	$err_msg=~s/\"//g;
	return ($err_num,$err_msg);
}

sub reset {
	my $self=shift;
	$self->{vi}->Write("*RST");
}

1;

=head1 NAME

VISA::Instrument::HP34401A - a HP 34401A digital multimeter

=head1 SYNOPSIS

    use VISA::Instrument::HP34401A;
    
    my $hp=new VISA::Instrument::HP34401A(0,22);
    print $hp->read_voltage_dc(10,0.00001);

=head1 DESCRIPTION

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head2 read_voltage_dc

    $datum=$hp->read_voltage_dc($range,$resolution);

Preset and make a dc voltage measurement with the specified range
and resolution.

=over 4

=item $range

Range is given in terms of volts and can be [0.1|1|10|100|1000|MIN|MAX|DEF]. DEF is default.

=item $resolution

Resolution is given in terms of $range or [MIN|MAX|DEF]. $resolution=0.0001 means 4½ digits for example.
The best resolution is 100nV: $range=0.1;$resolution=0.000001.

=back

=head2 read_voltage_ac

    $datum=$hp->read_voltage_ac($range,$resolution);

Preset and make an ac voltage measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6½ digits. The resolution parameter only affects the front-panel display.

=head2 read_current_dc

    $datum=$hp->read_current_dc($range,$resolution);

Preset and make a dc current measurement with the specified range
and resolution.

=head2 read_current_ac

    $datum=$hp->read_current_ac($range,$resolution);

Preset and make an ac current measurement with the specified range
and resolution. For ac measurements, resolution is actually fixed
at 6½ digits. The resolution parameter only affects the front-panel display.

=head2 display_on

    $hp->display_on();

Turn the front-panel display on.

=head2 display_off

    $hp->display_off();

Turn the front-panel display off.

=head2 display_text

    $hp->display_text($text);
    print $hp->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

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

=head2 reset

    $hp->reset();

Reset the multimeter to its power-on configuration.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item VISA::Instrument

The HP34401A uses the VISA::Instrument class (L<VISA::Instrument>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
