#$Id$

package Lab::Instrument::IsoBus;

use strict;
use Lab::Instrument;
use Lab::VISA;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);


#                 /* Verify that the RS-232 port has the right settings. */
# 
#                 if ( isobus_flags & MXF_ISOBUS_READ_TERMINATOR_IS_LINEFEED ) {
#                         read_terminator = MX_LF;
#                 } else {
#                         read_terminator = MX_CR;
#                 }
# 
#                 mx_status = mx_rs232_verify_configuration( interface_record,
#                                 9600, 8, 'N', 1, 'N', read_terminator, 0x0d );


    my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_BAUD, 9600);
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting baud: $status";}

    $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR, 13);
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar: $status";}

    $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, 1);
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar enabled: $status";}

    $status=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_ASRL_END_IN, 	$Lab::VISA::VI_ASRL_END_TERMCHAR);
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting end termchar: $status";}

#                 /* Reinitialize the serial port. */
# 
#                 mx_status = mx_resynchronize_record( interface_record );
# 
#                 if ( mx_status.code != MXE_SUCCESS )
#                         return mx_status;

    sleep(1);

#                 /* Discard any characters waiting to be sent or received. */
# 
#                 mx_status = mx_rs232_discard_unwritten_output(
#                                         interface_record, MXI_ISOBUS_DEBUG );
# 
#                 if ( mx_status.code != MXE_SUCCESS )
#                         return mx_status;
# 
#                 mx_status = mx_rs232_discard_unread_input(
#                                         interface_record, MXI_ISOBUS_DEBUG );
# 
#                 if ( mx_status.code != MXE_SUCCESS )
#                         return mx_status;
#                 break;

return $self;
}

sub IsoBus_Write {
  my $self=shift;
  my $addr=shift;
  my $command=shift;

  my $value=$self->{vi}->Write(sprintf("@%d%s\r",$addr,$command));
  return $value;
}

sub IsoBus_Read {
  my $self=shift;
  my $addr=shift;
  my $length=shift;

  my $result=$self->{vi}->Read($length);
  return $result;
};

sub IsoBus_valid {
  return 1;
}

1;

=head1 NAME

Lab::Instrument::IsoBus - Oxford Instruments IsoBus device

=head1 SYNOPSIS

    use Lab::Instrument::IsoBus;
    
    my $isobus=new Lab::Instrument::ILM(0,1);
	my $ilm=new Lab::Instrument::ILM($isobus,$addr);

=head1 DESCRIPTION

The Lab::Instrument::IsoBus class implements an interface to the Oxford Instruments IsoBus. The IsoBus is treated
as a VISA device, and can thus be attached directly at a serial port or at a GPIB gateway device. The corresponding 
VISA resource has to be specified at initialization. 

Later, IsoBus devices attached to this IsoBus can be instantiated by passing the IsoBus as first constructor argument.


=head1 CONSTRUCTOR

    my $isobus=new Lab::Instrument::IsoBus($gpibadapter,$gpibaddr);

Instantiates a new IsoBus object. All argument variants valid for the C<Lab::Instrument> 
constructor can be used. This way, an IsoBus can be attached to a GPIB gateway device or
directly to a serial port.

=head1 METHODS

=head2 IsoBus_Write

    $write_cnt=$isobus->IsoBus_Write($addr,$command);

Sends C<$command> to the device attached to this IsoBus with IsoBus address C<$addr>. The number of bytes
actually written is returned.

=head2 IsoBus_Read

    $result=$isobus->IsoBus_Read($addr,$length);

Reads at most C<$length> bytes from the device attached to this IsoBus with IsoBus address C<$addr>.
The resulting string is returned.

=head2 IsoBus_valid

    $is_an_isobus=$isobus->IsoBus_valid();

Returns 1.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>
=item L<Lab::Instrument::ILM>
=item and probably more...

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2010 Andreas K. Hüttel (L<http://www.akhuettel.de/>)

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
