package Lab::Instrument::AgilentE8362A;
use strict;
use warnings;

our $VERSION = '3.32';

use feature "switch";
use Lab::Instrument;
use Lab::Instrument::Source;
use Data::Dumper;

our @ISA=('Lab::Instrument::Source');

our %fields = (
    supported_connections => [ 'VISA_GPIB', 'GPIB', 'VISA' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board => 0,
        gpib_address => 16,
    },


    device_settings => {
    
    },

);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    $self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

    # already called in Lab::Instrument::Source, but call it again to respect default values in local channel_defaultconfig
    $self->configure($self->config());
    
    return $self;
}



sub reset {
    my $self=shift;
    $self->write('SYST:FPR');
}



sub set_span
{
    my $self = shift;
    my $span = shift || "DEF"; #Hz
    $self->write("SENS:FREQ:SPAN $span");
}

sub set_bandwidth
{
    my $self = shift;
    my $bw = shift || "DEF"; #Hz
    $self->write("SENS:BAND $bw");
}



sub set_frequency
{
    my $self = shift;
    my $freq = shift || "DEF"; #Hz
    $self->write("SENS:FREQ:CENT $freq");
}



sub set_level {
    my $self=shift;
    my $value=shift;
    my $srcrange = 27;
    
     
    if( abs($value) <= $srcrange ){
        my $cmd=sprintf(":SOUR:POW %f",$value);
        #print $cmd;
        $self->write( $cmd );
        return $self->{'device_cache'}->{'level'} = $value;
    }
    else{
        Lab::Exception::CorruptParameter->throw(
        error=>"Level $value is out of current range $srcrange.");
    }
    
    
}


sub power_on {
    my $self=shift;
    my ($tail) = $self->_check_args( \@_);

    $self->write(":OUTP:ON",$tail);
    
}


sub power_off {
    my $self=shift;
    my ($tail) = $self->_check_args( \@_);

    $self->write(":OUTP:OFF",$tail);
    
}

sub get_value {
    my $self=shift;
    my ($tail) = $self->_check_args( \@_);
    $self->write("FORMAT ASCII"); #REAL 32 und REAL 64 als hexa-alternative, default:ASCII Ausgabe
    return $self->query("CALC:DATA? FDATA");
    
}


sub single_sweep
{
    my $self = shift;
    $self->write("INIT;*OPC?");
}



1;
