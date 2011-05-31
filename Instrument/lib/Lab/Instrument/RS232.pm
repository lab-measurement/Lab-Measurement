#$Id: IsoBus.pm 613 2010-04-14 20:40:41Z schroeer $

package Lab::Instrument::RS232;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep sleep);
use Lab::VISA;

our $VERSION = sprintf("0.%04d", q$Revision: 613 $ =~ / (\d+) /);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless ($self, $class);

	$self->{vi}=new Lab::Instrument(@_);
	
	return $self;
}

sub set_RS232_Parameter{
	my $self = shift;
	my $RS232_Parameter = shift;
	my $value = shift;

	my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $RS232_Parameter, $value);
	if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}
	
	return $status;
}

sub RS232_Write {
	my $self = shift;
	my $cmd = shift;
	my $echo = shift;
	my $break;
	
	if ($echo eq 'OFF') # ECHO OFF
		{
		$self->{vi}->Write($cmd);
		return length($cmd)+2;
		}
	elsif ($echo eq 'CHARACTER')
		{
		# Send the COMMAND STRING Byte by Byte and check after each Byte the ECHO of the RS232 device. Retry to send lost Bytes.	
		for (my $i = 0; $i < length($cmd); $i++)
			{
			my $byte = substr($cmd,$i,1); # select one Byte to send ...
			$break = 0;
			while($break < 10) 
				{
			
				$self->{vi}->Write($byte); # send selected Byte ...
				if ( (my $echo = $self->{vi}->BrutalRead(1)) eq $byte ) {last;} # check ECHO ...
				else {print "$echo != $byte --> retry\n"; $break++; usleep(1e5);} # and retry if lost.
				}
			if ($break == 10)
				{
				die "Error while writing string \"$cmd\"";
				}
			}
		$self->{vi}->Write("\r\n");  # send Termination Character 
		$self->{vi}->BrutalRead(2);  # and recieve ECHO
		return length($cmd)+2;
		
		}
	elsif ($echo eq 'COMMAND')
		{
		$break = 0;
		while ($break < 10)
			{
			$self->{vi}->Write("$cmd"); # send command ...
			my $echo2 = $self->{vi}->BrutalRead(length($cmd));
			if ($echo2  eq $cmd ) {last;}
			else { print "$echo2 != $cmd --> retry\n"; $break++; usleep(1e5); }
			}
			
		if ($break == 10)
			{
			die "Error while writing string \"$cmd\"";
			}	
		return length($cmd)+2;
		}
	else
		{
		die "ERROR in RS232-settings.";
		}
	
	
	
	
}

sub RS232_Read {
	my $self=shift;
	my $length=shift;

	my $result=$self->{vi}->Read($length);
	return $result;
}

sub RS232_BrutalRead {
	my $self=shift;
	my $length=shift;

	my $result=$self->{vi}->BrutalRead($length);
	return $result;
}

sub RS232_valid {
	return 1;
}
1;

=head1 NAME

	Lab::Instrument::RS232

=head1 SYNOPSIS

	use Lab::Instrument::RS232;
	my $rs232=new Lab::Instrument::RS232('ASRL1::INSTR'); # ASRL1::INSTR = COM 1, ASRL2::INSTR = COM 2, ...
	my $SignalRecovery726x=new Lab::Instrument::SignalRecovery726x($rs232);

.

=head1 DESCRIPTION

The Lab::Instrument::RS232 class implements an interface to the SERIAL PORT. 
Later, RS232 devices attached to this SERIAL PORT can be instantiated by passing the RS232 as first constructor argument.

.

=head1 CONSTRUCTOR

	my $rs232=new Lab::Instrument::RS232('ASRL1::INSTR'); # ASRL1::INSTR = COM 1, ASRL2::INSTR = COM 2, ...

Instantiates a new RS232 object.

.

=head1 METHODS

=head2 IsoBus_Write

	$write_cnt=$rs232-device->RS232_Write($command, $echo);

Sends C<$command> to the device attached to this RS232-device with echo  C<$echo>. The number of bytes
actually written is returned.

.

=head2 IsoBus_Read

    $result=$rs232-device->RS232_Read($length);

Reads at most C<$length> bytes from the RS232-device.
The resulting string is returned.

.

=head2 IsoBus_valid

    $is_an_rs232=$rs232-device->RS232_valid();

Returns 1.

.

=head1 CAVEATS/BUGS

probably many

.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>
=item L<Lab::Instrument::ILM>
=item and probably more...

=back

.

=head1 AUTHOR/COPYRIGHT

This is $Id: IsoBus.pm 613 2010-04-14 20:40:41Z schroeer $

Copyright 2010 Andreas K. Hüttel (L<http://www.akhuettel.de/>)

Modified 2011 by Stefan Geissler

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

.

=cut
