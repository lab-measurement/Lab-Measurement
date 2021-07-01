package Lab::Moose::Instrument::KeysightDSOS604A;

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

# On this Infiniium S-Series oscilloscope, the implementation of the *OPC?
# query does not honor the definition in the SCPI standard. Instead it returns
# from the *OPC? query after parsing the previous commands, not after the
# effects of the previous commands are completed. See the programming manual
# page 209 for more information.

# ?? Was heißt das, und wozu wäre das sub unten gut??

# around opc_query  => sub {
#     my ( $self, %args ) = validated_getter( \@_ );
#     return $self->query( command => ':PDER?', %args );
# };

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

###
### DEBUGGING
###

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

sub get_waveform_voltage {
  my ( $self, %args ) = validated_getter( \@_);
  my $yOrg = $self->query(command => ":WAVeform:YORigin?");
  my $yInc = $self->query(command => ":WAVeform:YINCrement?");

  # ?? maybe ask the scope for the number of points and adapt the read_length then?
  #    now we just have another maximum value that can break things!

  my $cData = $self->query(command => ":WAVeform:DATA?", read_length => 1000000);
  my @data = ( split /,/, $cData );
  foreach (0..@data-1) {$data[$_] = $data[$_]*$yInc+$yOrg;}
  return \@data;
}

# obsolete as of right now
# ?? why? I mean, you still need the time axis!

sub get_waveform_time {
  my ( $self, %args ) = validated_getter( \@_);
  my $xOrg = $self->query(command => ":WAVeform:XORigin?");
  my $xInc = $self->query(command => ":WAVeform:XINCrement?");
  my $points = $self->query(command => ":ACQuire:POINts:ANALog?");
  my @time;
  foreach (0..$points) {@time[$_] = $_*$xInc+$xOrg}
  return \@time;

}

# ?? also, what would be useful is a function "get_waveform", which returns a
#    block with two matching columns, time and voltage
#    (this is a standard problem, so not something the actual measurement script
#     should need to care about)

###
### MEASURE
###

=head2 measure_vpp

 $keysight->measure_vpp(source => 'CHANnel1');

Query the Vpp voltage of a specified source.

  ?? generell, wäre da nicht ein Parameter channel => 1 sinnvoller?

=cut

sub measure_vpp {
    my ( $self, %args ) = validated_getter( \@_ );
    my $source = delete $args{'source'};

    return $self->query( command => ":MEASure:VPP? $source", %args );
}

###
### SAVE TO DISK
###

=head2 save_waveform

 $keysight->save_waveform(source => 'CHANnel1',
   filename => 'C:\Users\Administrator\Documents\Results\data2306_c1_5',format => 'CSV');

Save the waveform currently displayed on screen. C<source> can be a channel, function,
histogram, etc, C<filename> specifies the path the waveform is saved to and format can be
C<BIN CSV INTernal TSV TXT H5 H5INt MATlab>.

The following file name extensions are used for the different formats:
=item BIN = file_name.bin
=item CSV (comma separated values) = file_name.csv
=item INTernal = file_name.wfm
=item TSV (tab separated values) = file_name.tsv
=item TXT = file_name.txt
=item H5 (HDF5) = file_name.h5
In the H5 format, data is saved as floats. In this case, the data values are actual
vertical values and do not need to be multiplied by the Y increment value.
=item H5INt (HDF5) = file_name.h5
In the H5INt format, data is saved as integers. In this case, data values are
quantization values and need to be multiplied by the Y increment value and
added to the Y origin value to get the actual vertical values.
=item MATlab (MATLAB data format) = file_name.mat

=cut

sub save_waveform {
    my ( $self, %args ) = validated_getter( \@_,
      source => { isa => 'Str'},
      filename => { isa => 'Str'},
      format => { isa => enum( [qw/BIN CSV INTernal TSV TXT H5 H5INt MATlab/])}
     );
    my ( $source, $filename, $format)
        = delete @args{qw/source filename format/};

    $self->write( command => ":DISK:SAVE:WAVeform $source,\"$filename\",$format,ON", %args );
}

=head2 save_measurements

 $keysight->save_measurements(filename => 'C:\Users\Administrator\Documents\Results\my_measurements');

Save all current measurements on screen to the specified path on the internal
harddrive of the DSO.

=cut

sub save_measurements {
    my ( $self, %args ) = validated_getter( \@_,
      filename => { isa => 'Str'}
     );
    my $filename = delete $args{'filename'};

    $self->write( command => ":DISK:SAVE:MEASurements \"$filename\"", %args );
}

###
### TRIGGER
###

=head2 force_trigger

 $keysight->force_trigger();

Force a trigger event by command.

=cut

sub force_trigger {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => ":TRIGger:FORCe", %args );
}

=head2 trigger_level

 $keysight->trigger_level(channel => 'CHANnel1', level => 0.1);

Adjust the trigger source and level.

  ?? is that adjusting the trigger *of* channel1, or the global triggering to use
     channel1 as source?

  ?? also, to make life easier, it would probably make sense to always use just
     a channel number (and maybe "X") as parameter and translate inside the function
     ... e.g., $keysight->trigger_level(channel => 1, level => 0.1);

  ?? what is 0.1 here? 10% of the maximum range, or 0.1V, or.... ?

=cut

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

=head2 acquire_mode

 $keysight->acquire_mode(value => 'HRESolution');

Allowed values: C<ETIMe, RTIMe, PDETect, HRESolution, SEGMented, SEGPdetect, SEGHres>

 ?? Either write something about the values (much work), or point to the page
    number in the programming handbook (easier): See ... for an explanation.

=cut

sub acquire_mode {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ETIMe RTIMe PDETect HRESolution SEGMented SEGPdetect SEGHres/])},
    );
    $self->write( command => ":ACQuire:MODE $value", %args );
}

=head2 acquire_hres

 $keysight->acquire_hres(value => 'BITF16');

Specify the resolution for the High Resolution acquisition mode.

Allowed values: ...

 ?? how about 0 (= AUTO), 11, 12, ..., 16

=cut

sub acquire_hres {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO BITF11 BITF12 BITF13 BITF14 BITF15 BITF16/])},
    );
    $self->write( command => ":ACQuire:HRESolution $value", %args );
}

=head2 acquire_points

 $keysight->acquire_points(value => 40000);

Specify the amount of data points collected within an acquisition window. 40000
seems to be the minimum. Using this command adjusts the sample rate automatically.

  ?? let's try to explain this for dummies... "acquisition window" is the "recording
     time" of a time trace? is that equal to the "timebase range" below?
     And is it as simple as, an acquisition window of 100ms and 100000 points
     gives a sample rate of 1us?

=cut

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

=head2 timebase_range

 $keysight->timebase_range(value => 0.00022);

Manually adjust the Oscilloscopes time scale on the x axis.

  ?? see also comments above

=cut

sub timebase_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":TIMebase:RANGe $value", %args );
}

=head2 timebase_reference

 $keysight->timebase_reference(value => 'LEFT');

Specify where the time origin is on the display. By default it is centered.
Allowed values: C<LEFT CENTer RIGHt>

=cut

sub timebase_reference {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/LEFT CENTer RIGHt/]) }
    );

    $self->write( command => ":TIMebase:REFerence $value", %args );
}

=head2 timebase_ref_perc

 $keysight->timebase_ref_perc(value => 15);

Shift the time origin by 0% to 100% in the opposite direction than C<timebase_reference>,
100% would shift the origin from left to right or the other way around.

=cut

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

=head2 timebase_clock

 $keysight->timebase_clock(value => 'OFF')

Enable or disable the Oscilloscopes 10 MHz REF IN BNC input (ON or OFF) or the
100MHz REF IN SMA input (HFRequency or OFF). When either option is enabled, the
external reference input is used as a reference clock for the Oscilloscopes
horizonal scale instead of the internal reference clock.

=cut

sub timebase_clock {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON 1 OFF 0 HFRequency/]) }
    );

    $self->write( command => ":TIMebase: $value", %args );
}

###
### WAVEFORM
###

=head2 waveform_format

 $keysight->waveform_format(value => 'WORD');

This command controls how the data is formatted when it is sent from
the oscilloscope, and pertains to all waveforms. The default format is ASCii.

=cut

sub waveform_format {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ASCii BINary BYTE WORD FLOat/]) }
    );

    $self->write( command => ":WAVeform:FORMat $value", %args );
}

=head2 waveform_source

 $keysight->waveform_source(value => 'CHANnel1');

Select a source to the acquired waveform. Allowed values: C<CHANnel1, CHANnel2, CHANnel3, CHANnel4, CLOCk>

=cut

sub waveform_source {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/CHANnel1 CHANnel2 CHANnel3 CHANnel4 CLOCk/]) }
    );

    $self->write( command => ":WAVeform:SOURce $value", %args );
}

###
### CHANNEL
###

=head2 channel_input

 $keysight->channel_input(channel => 'CHANnel1', parameter => 'DC50');

C<parameter> can be either
=item DC — DC coupling, 1 MΩ impedance.
=item DC50 | DCFifty — DC coupling, 50Ω impedance.
=item AC — AC coupling, 1 MΩ impedance.
=item LFR1 | LFR2 — AC 1 MΩ input impedance.
When no probe is attached, the coupling for each channel can be AC, DC, DC50, or DCFifty.
If you have an 1153A probe attached, the valid parameters are DC, LFR1, and LFR2 (low-frequency reject).

=cut

sub channel_input {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => enum( [qw/CHANnel1 CHANnel2 CHANnel3 CHANnel4/])},
        parameter => { isa => enum( [qw/DC DC50 DCFifty LFR1 LFR2/])}
    );
    my ( $channel, $parameter ) = delete @args{qw/channel parameter/};

    $self->write( command => ":$channel:INPut $parameter", %args );
}

=head2 channel_differential

 $keysight->channel_differential(channel => 'CHANnel1', mode => 'ON');

Turns on or off differential mode. C<'mode'> can be C<ON OFF 1 0>.

=cut

sub channel_differential {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => enum( [qw/CHANnel1 CHANnel2 CHANnel3 CHANnel4/])},
        mode => { isa => enum( [qw/ON OFF 1 0/])}
    );
    my ( $channel, $mode ) = delete @args{qw/channel mode/};

    $self->write( command => ":$channel:DIFFerential $mode", %args );
}

=head2 channel_range/channel_offset

 $keysight->channel_range(channel => 'CHANnel1', range => 1);
 $keysight->channel_offset(channel => 'CHANnel1', offset => 0.2);

Allows for manual adjustment of the Oscilloscopes vertical voltage range and -offset for a specific
channel. Requires differential mode to be turned on.

=cut

sub channel_range {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => enum( [qw/CHANnel1 CHANnel2 CHANnel3 CHANnel4/])},
        range => { isa => 'Num'}
    );
    my ( $channel, $range ) = delete @args{qw/channel range/};

    $self->write( command => ":$channel:RANGe $range", %args );
}

sub channel_offset {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => enum( [qw/CHANnel1 CHANnel2 CHANnel3 CHANnel4/])},
        offset => { isa => 'Num'}
    );
    my ( $channel, $offset ) = delete @args{qw/channel offset/};

    $self->write( command => ":$channel:OFFSet $offset", %args );
}

with qw(
    Lab::Moose::Instrument::Common
);

__PACKAGE__->meta()->make_immutable();

1;

__END__
