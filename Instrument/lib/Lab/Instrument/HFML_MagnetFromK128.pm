#$Id: TRMC2.pm 301 2010-05-10 10:12:43Z hua59129 $

package Lab::Instrument::HFML_MagnetFromK128;
# Magnet at HFML in Nijmegen
# David Kalok


use strict;
use warnings;
use Lab::Instrument;
use IO::File;
use Lab::Instrument::K2182;
use Time::HiRes qw/usleep/;
use Time::HiRes qw/sleep/;
our $VERSION = sprintf("0.%04d", q$Revision: 301 $ =~ / (\d+) /);

my $WAIT=0.3; #sec. waiting time for each reading;
#my $mounted=0;  # Ist sie schon mal angemeldet

#my $buffin="C:\\Program Files\\Trmc2\\buffin.txt";# Hierhin gehen die Befehle
#my $buffout="C:\\Program Files\\Trmc2\\buffout.txt";# Hierher kommen die Antworten
my $buffer="C:\\Documents and Settings\\maglab1\\Desktop\\Files\\Files\\current.txt";

my $alpha=0.88449;
my $beta=2.3779E-6;
my $gamma=-1.628E-10;

my $K182_I_conv_fac_1 = -2;
my $K182_I_conv_fac_2 = -2;

my $K182_1;
my $K182_2;

sub initKeithleys{
    $K182_1=new Lab::Instrument::K2182(1,1);
    $K182_2=new Lab::Instrument::K2182(1,2);   
}

sub new {
    initKeithleys();
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self;
}


sub setItoBval{
    my $self =shift;
    $alpha=shift;
    $beta=shift;
    $gamma=shift;
}

sub getItoBval{
    return $alpha,$beta,$gamma;
}

sub get_I{
    my $self=shift;
    #--------Reading Value----------------------
    #my $I->{vi}->Query("X");
    my $K182_current_PS_1=$K182_1->{vi}->Query("X");
    my $K182_current_PS_2=$K182_2->{vi}->Query("X");
    my $I=abs( ($K182_I_conv_fac_1* $K182_current_PS_1) + ($K182_I_conv_fac_2 * $K182_current_PS_2));
    return $I;
   # printf "$tmp";      
}

sub get_B{
    my $self=shift;
    #--------Reading Value----------------------
    my $I=$self->get_I();
    my $B=$alpha*$I+$beta*$I**3+$gamma*$I**5;
    return $B;
}

sub get_IB{
    my $self=shift;
    my $I=$self->get_I();
    my $B=$alpha*$I+$beta*$I**3+$gamma*$I**5;
    return ($I,$B);
}
1;

