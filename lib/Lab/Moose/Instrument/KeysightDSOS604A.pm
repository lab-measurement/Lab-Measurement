package Lab::Moose::Instrument::KeysightDSOS604A;
$Lab::Moose::Instrument::KeysightDSOS604A::VERSION = '3.750';
#ABSTRACT: Keysight DSOS604A infiniium S-Series Oscilloscope.

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Lab::Moose::Instrument::Cache;
use Carp 'croak';
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x2a8d, pid => 0x9045,
    reset_device => 0 # Same as with the B2901A
    };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}
###
### SYSTEM
###

sub ask_idn {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "*IDN?", %args );
}

sub ready {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => ":STOP", %args );
    return $self->query( command => "*OPC?", %args );
}

sub read_error {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => ":SYSTem:ERRor? STRing", %args );
}

sub system_debug {
    my ( $self, $output, $filename, %args ) = validated_setter( \@_,
    output => { isa => enum( [qw/FILE SCReen FileSCReen/]) },
    filename => { isa => 'Str' }
    );
    $self->write( command => ":SYSTem:DEBug ON,$output,\"$filename\",CREate", %args );
}

sub disable_debug {
    my ( $self, %args ) = validated_getter( \@_);
    $self->write( command => ":SYSTem:DEBug OFF", %args );
}

###
### MEASURE
###

sub save_measurement {
    my ( $self, $filename, %args ) = validated_setter(
        \@_,
        filename => { isa => 'Str' }
    );
    $self->write( command => ":DISK:SAVE:MEASurements \"$filename\"", %args );
}

sub measure_vpp {
    my ( $self, %args ) = validated_setter( \@_ );
    my $value = delete $args{'value'};

    return $self->query( command => ":MEASure:VPP? $value", %args );
}

###
### SAVE TO DISK
###

sub save_noise {
    my ( $self, $filename, %args ) = validated_setter(
        \@_,
        filename => { isa => 'Str' }
    );
    $self->write( command => ":DISK:SAVE:NOISe \"$filename\"", %args );
}

sub save_waveform {
    my ( $self, %args ) = validated_getter( \@_,
      source => { isa => 'Str'},
      filename => { isa => 'Str'},
      format => { isa => 'Str'}
     );
    my ( $source, $filename, $format)
        = delete @args{qw/source filename format/};

    $self->write( command => ":DISK:SAVE:WAVeform $source,\"$filename\",$format,ON", %args );
}

###
### TRIGGER
###

sub force_trigger {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => ":TRIGger:FORCe", %args );
}

sub trigger_level {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => enum( [qw/CHANnel1 CHANnel2 CHANnel3 CHANnel4 AUX/])},
        level => { isa => 'Num'}
    );
    my ( $channel, $level ) = delete @args{qw/channel level/};

    $self->write( command => ":TRIGger:LEVel $channel,$level", %args );
}

###
### ACQUIRE
###

sub acquire_hres {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO BITF11 BITF12 BITF13 BITF14 BITF15 BITF16/])},
    );
    $self->write( command => ":ACQuire:HRESolution $value", %args );
}

sub acquire_mode {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ETIMe RTIMe PDETect HRESolution SEGMented SEGPdetect SEGHres/])},
    );
    $self->write( command => ":ACQuire:MODE $value", %args );
}

sub acquire_points {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' },
    );
    $self->write( command => ":ACQuire:POINts:ANALog $value", %args );
}

###
### TIMEBASE
###

sub timebase_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":TIMebase:RANGe $value", %args );
}

sub timebase_reference {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/LEFT CENTer RIGHt/]) }
    );

    $self->write( command => ":TIMebase:REFerence $value", %args );
}

sub timebase_ref_perc {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );
    if ($value > 100 || $value < 0){
      croak "The offset percentage must be between 0 and 100";
    };

    $self->write( command => ":TIMebase:REFerence:PERCent $value", %args );
}

sub timebase_clock {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON 1 OFF 0 HFRequency/]) }
    );

    $self->write( command => ":TIMebase:REFerence $value", %args );
}

###
### WAVEFORM
###

sub waveform_format {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ASCii BINary BYTE WORD FLOat/]) }
    );

    $self->write( command => ":WAVeform:FORMat $value", %args );
}

sub waveform_source {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/CHANnel1 CHANnel2 CHANnel3 CHANnel4 CLOCk/]) }
    );

    $self->write( command => ":WAVeform:SOURce $value", %args );
}

with qw(
    Lab::Moose::Instrument::Common
);

__PACKAGE__->meta()->make_immutable();

1;

__END__
