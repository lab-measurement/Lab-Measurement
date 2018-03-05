package Lab::Moose::Instrument::OI_Common;

#ABSTRACT: Role for handling Oxfords Instruments common SCPI commands

use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

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

    my $rv
        = $self->oi_getter( cmd => "READ:DEV:$channel:TEMP:SIG:TEMP", %args );
    $rv =~ s/K.*$//;
    return $rv;
}

sub _parse_setter_retval {
    my $self = shift;
    my ( $header, $retval ) = @_;

    $header = 'STAT:' . $header;
    if ( $retval !~ /^\Q$header\E:([^:]+):VALID$/ ) {
        croak "Invalid return value of setter for header $header:\n $retval";
    }
    return $1;
}

sub _parse_getter_retval {
    my $self = shift;
    my ( $header, $retval ) = @_;

    $header =~ s/^READ:/STAT:/;

    if ( $retval !~ /^\Q$header\E:(.+)/ ) {
        croak "Invalid return value of getter for header $header:\n $retval";
    }
    return $1;
}

=head2 oi_getter

 my $current = $self->oi_getter(cmd => "READ:DEV:$channel:PSU:SIG:CURR", %args);
 $current =~ s/A$//;

Perform query with I<READ:*> command and parse return value.

=cut

sub oi_getter {
    my ( $self, %args ) = validated_getter(
        \@_,
        cmd => { isa => 'Str' }
    );
    my $cmd = delete $args{cmd};
    my $rv = $self->query( command => $cmd, %args );
    return $self->_parse_getter_retval( $cmd, $rv );
}

=head2 oi_setter

  $self->oi_setter(
        cmd => "SET:DEV:$channel:PSU:SIG:SWHT",
        value => $value,
        %args);

Perform set/query with I<SET:*> command and parse return value.

=cut

sub oi_setter {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        cmd => { isa => 'Str' }
    );
    my $cmd = delete $args{cmd};
    my $rv = $self->query( command => "$cmd:$value", %args );
    return $self->_parse_setter_retval( $cmd, $rv );
}

1;
