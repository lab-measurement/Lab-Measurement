#$Id$

package Lab::Instrument::ILM;

use strict;
use Lab::Instrument::IsoBus;
use Lab::Instrument;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{vi}=new Lab::Instrument(@_);
    return $self;
}

sub get_level {
  my $self = shift;

  my $level=$self->{vi}->{IsoBus}->IsoBus_Query($self->{isoaddress}, "R1");
  $level=~s/^R//;
  $level/=10;
  return $level;  
};

1;
