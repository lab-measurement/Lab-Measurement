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
  my $query=shift;

  my $value=$self->{vi}->Write(sprintf("@%d%s\r",$addr,$query));
  return $value;
}

sub IsoBus_Query {
  my $self=shift;
  my $addr=shift;
  my $query=shift;

  my $value=$self->{vi}->Query(sprintf("@%d%s\r",$addr,$query));
  return $value;
};

sub IsoBus_valid {
  return 1;
}

1;
