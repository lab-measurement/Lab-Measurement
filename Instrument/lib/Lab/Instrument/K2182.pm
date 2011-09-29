#$Id: TRMC2.pm 301 2010-05-10 10:12:43Z hua59129 $

package Lab::Instrument::K2182;
# Keithley 2182
# David Kalok
use strict;
use warnings;
use Lab::Instrument;
use Time::HiRes qw/usleep/;
use Time::HiRes qw/sleep/;
our $VERSION="1.21";



sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self;
}


sub get_X{
    my $self=shift;
    #--------Reading Value----------------------
    my $X=$self->{vi}->Query("X");
    return $X;  
}
 sub read_value{
    my $self=shift;
    my $val=$self->{vi}->Query("G0T4Y2X");
    if ($val==10){$val=$self->{vi}->Query("G0T4Y2X")}
    return $val;  
 }

1;

