package Lab::IO::Interface;

our $VERSION = '3.520';

use Lab::Generic;

our @ISA = ('Lab::Generic');

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = Lab::Generic::new( $class, @_ )
        ;    #<---- What is this???? Why not SUPER new?
    $self->{CHANNELS};
    $self->{last_object};
    $self->{last_channel};
    return $self;
}

sub receive {
    my $self = shift;
    my $chan = shift;
    my $DATA = shift;
    if ( not defined $chan ) {
        return;
    }    #{print "Receive: Missing channel id!\n"; return;}
    if ( not defined $DATA || ref($DATA) != 'HASH' ) {
        return;
    }    #{print "Receive: Missing data object!\n"; return;}

    if ( exists $self->{CHANNELS}->{$chan}
        && defined $self->{CHANNELS}->{$chan} ) {
        $self->{CHANNELS}->{$chan}->( $self, $DATA );
        $self->{last_object}  = $DATA->{object};
        $self->{last_channel} = $chan;
    }
    else { return; } #{print "Receive: Channel $chan not supported!"; return;}
}

# print: prototype
# sub print {
# my $self = shift;
# my $msg = shift;
# print "$msg\n";
# }

sub valid_channel {
    my $self = shift;
    my $chan = shift;
    if ( not defined $chan ) { return 0; }
    if ( not defined $self->{CHANNELS}->{$chan} ) { return 0; }
    return 1;
}

sub same_object {
    my $self   = shift;
    my $DATA   = shift;
    my $object = $DATA->{object};

    # print "Object compare between '".$self->{last_object}."' (".ref($self->{last_object}).") and '".$object."':\n";
    # print "Defined? ", (defined $self->{last_object} ? "Yes" : "No"), "\n";
    # print "Hash? ", (ref($self->{last_object}) ? "Yes" : "No"), "\n";
    # print "Same? ", ($object == $self->{last_object} ? "Yes" : "No"), "\n";
    # print "Result: ", (defined $self->{last_object} && ref($self->{last_object}) && $object == $self->{last_object} ? "Yes" : "No"), "\n";

    return (   defined $self->{last_object}
            && ref( $self->{last_object} )
            && $object == $self->{last_object} );
}

sub same_channel {
    my $self = shift;
    my $chan = shift;

    # print "Channel compare between '".$self->{last_channel}."' and '".$chan."': ", (defined $self->{last_channel} && $chan eq $self->{last_channel} ? "Yes" : "No"), "\n";

    return ( defined $self->{last_channel}
            && $chan eq $self->{last_channel} );
}

1;
