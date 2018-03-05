package Lab::Moose::Instrument::OI_Common;

#ABSTRACT: Role for handling Oxfords Instruments common SCPI commands

use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument 'validated_getter';

use Carp;

use namespace::autoclean;

=head1 DESCRIPTION


=head1 METHODS

=head2 get_temperature

 $t = $m->get_temperature_channel(channel => 'MB1.T1');

Read out the designated temperature channel. Result is in Kelvin.

=cut

sub get_temperature_channel {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str' }
    );

    my $channel = delete $args{channel};

    my $cmd = "READ:DEV:$channel:TEMP:SIG:TEMP";
    my $rv = $self->query( command => $cmd, %args );

    $rv = $self->parse_getter_retval( $cmd, $rv );

    $rv =~ s/K.*$//;
    return $rv;
}

=head2 parse_setter_retval

 my $cmd = "SET:DEV:$channel:PSU:SIG:SWHT";
 my $rv = $self->query(command => "$cmd:$value", %args);
 return $self->parse_setter_retval( $cmd, $rv );

Remove header and trailing ':VALID'

=cut

sub parse_setter_retval {
    my $self = shift;
    my ( $header, $retval ) = @_;

    $header = 'STAT:' . $header;
    if ( $retval !~ /^\Q$header\E:([^:]+):VALID$/ ) {
        croak "Invalid return value of setter for header $header:\n $retval";
    }
    return $1;
}

=head2 parse_getter_retval

 my $cmd = "READ:DEV:$channel:PSU:SIG:RCST";
 my $sweeprate = $self->query( command => $cmd, %args );
 $sweeprate = $self->_parse_getter_retval( $cmd, $sweeprate );
 # remove unit
 $sweeprate =~ s/A\/m$//;
 return $sweeprate;

=cut

sub parse_getter_retval {
    my $self = shift;
    my ( $header, $retval ) = @_;

    $header =~ s/^READ:/STAT:/;

    if ( $retval !~ /^\Q$header\E:(.+)/ ) {
        croak "Invalid return value of getter for header $header:\n $retval";
    }
    return $1;
}

1;
