package Lab::Moose::Instrument::KeysightDSOS604A;

#ABSTRACT: Keysight DSOS604A infiniium S-Series Oscilloscope.

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params validated_channel_getter
    validated_channel_setter/;
use Lab::Moose::Instrument::Cache;
use Carp 'croak';
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

has input_impedance => (
    is      => 'ro',
    isa     => enum( [qw/DC DC50 DCFifty LFR1 LFR2/]),
    default => 'DC50'
);

has instrument_nselect => (
    is      => 'ro',
    isa     => 'Int',
    default => 1
);

has waveform_format => (
    is      => 'rw',
    isa     => enum([qw/ASCii BINary BYTE WORD FLOat/]),
    default => 'FLOat'
);

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

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 my $source = instrument(
     type => 'KeysightDSOS604A',
     input_impedance => ...,
     instrument_nselect => ...,
     waveform_format => ...
 );

=over

=item * C<input_impedance> specifies the default input input impedance. See channel_input for more information
=item * C<instrument_nselect> specifies the default input channel
=item * C<waveform_format> specifies the default format for waveform data. See set_waveform_format for more information

=back

=cut

# It is recommended to use the :PDER? query instead of the standard *OPC? query
# on this oscilloscope. This is because *OPC? returns after the previous
# commands are parsed, not after the previous commands are executed completely.
# :PDER? does just this, like you would expect from the standard SCPI *OPC?
# query. See the programming manual page 209 for more information.

# around opc_query  => sub {
#     my ( $self, %args ) = validated_getter( \@_ );
#     return $self->query( command => ':PDER?', %args );
# };

sub BUILD {
  my $self = shift;
  $self->clear();
  $self->cls();
  $self->write(command => ":CHANnel".$self->instrument_nselect.":DISPlay ON");
  $self->write(command => ":WAVeform:FORMat ".$self->waveform_format);
  $self->write(command => ":WAVeform:BYTeorder LSBFirst" );
  $self->write(command => ":WAVeform:SOURce CHANnel".$self->instrument_nselect);
  $self->write(command => ":WAVeform:STReaming ON" );
  $self->timebase_reference(value => 'LEFT');
  $self->timebase_ref_perc(value => 5);
  $self->channel_input(channel => $self->instrument_nselect, parameter => $self->input_impedance);
  $self->write(command => ":TRIGger:EDGE:SOURce CHANnel".$self->instrument_nselect);
  $self->write(command => ":TRIGger:EDGE:SLOPe POSitive");
  $self->write(command => ":MEASure:CLEar");

}

sub get_default_channel {
  my $self = shift;
  return $self->instrument_nselect;
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

###
### MEASURE
###

=head2 save_measurement

 $keysight->save_measurement(value => 'C:\Users\Administrator\Documents\Results\my_measurement');

Save all current measurements on screen to the specified path.

=cut

sub save_measurement {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Str' }
    );
    $self->write( command => ":DISK:SAVE:MEASurements \"$value\"", %args );
}

=head2 measure_vpp

 $keysight->measure_vpp(source => 'CHANnel1');

Query the Vpp voltage of a specified source.

=cut

sub measure_vpp {
    my ( $self, $channel, %args ) = validated_getter( \@_ );

    return $self->query( command => ":MEASure:VPP? CHANnel${channel}", %args );
}

###
### SAVE TO DISK
###

=head2 save_waveform

 $keysight->save_waveform(source => 'CHANnel1', filename => 'C:\Users\Administrator\Documents\Results\data2306_c1_5',format => 'CSV');

Save the waveform currently displayed on screen. C<source> can be a channel, function,
histogram, etc, C<filename> specifies the path the waveform is saved to and format can be
C<BIN CSV INTernal TSV TXT H5 H5INt MATlab>.

The following file name extensions are used for the different formats:

=over

=item * BIN = file_name.bin
=item * CSV (comma separated values) = file_name.csv
=item * INTernal = file_name.wfm
=item * TSV (tab separated values) = file_name.tsv
=item * TXT = file_name.txt
=item * H5 (HDF5) = file_name.h5
In the H5 format, data is saved as floats. In this case, the data values are actual
vertical values and do not need to be multiplied by the Y increment value.
=item * H5INt (HDF5) = file_name.h5
In the H5INt format, data is saved as integers. In this case, data values are
quantization values and need to be multiplied by the Y increment value and
added to the Y origin value to get the actual vertical values.
=item * MATlab (MATLAB data format) = file_name.mat

=back

=cut

sub save_waveform {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_,
      filename => { isa => 'Str'},
      format => { isa => enum( [qw/BIN CSV INTernal TSV TXT H5 H5INt MATlab/])}
     );
    my ( $source, $filename, $format)
        = delete @args{qw/source filename format/};

    $self->write( command => ":DISK:SAVE:WAVeform CHANnel${channel},\"$filename\",$format,ON", %args );
}

=head2 save_measurements

 $keysight->save_measurements(filename => 'C:\Users\Administrator\Documents\Results\my_measurements');

Save all measurements on-screen to a file.

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

 $keysight->trigger_level(channel => 1, value => 0.1);

Set the global trigger to a specified channel with a trigger level in volts.

=cut

sub trigger_level {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => ":TRIGger:LEVel CHANnel${channel},$value", %args );
}

###
### ACQUIRE
###

=head2 acquire_mode

 $keysight->acquire_mode(value => 'HRESolution');

Allowed values: C<ETIMe, RTIMe, PDETect, HRESolution, SEGMented, SEGPdetect, SEGHres>

See the programming manual on page 243 for more information on the different
acquisation modes. The default is RTIMe.

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

Specify the minimum resolution for the High Resolution acquisition mode.

=cut

sub acquire_hres {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Int', default => 0},
    );
    if ($value == 0){
      $self->write( command => ":ACQuire:HRESolution AUTO", %args );
    } elsif ($value >= 11 and $value <= 16){
      $self->write( command => ":ACQuire:HRESolution BITF$value", %args );
    } else {
      croak "The Bit resolution can be 0 (for an automatic choice) or between 11 and 16";
    }

}

=head2 acquire_points

 $keysight->acquire_points(value => 40000);

Specify the amount of data points collected within an acquisition window. Using
this command adjusts the sample rate automatically.

=cut

sub acquire_points {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );
    $self->write( command => ":ACQuire:POINts:ANALog $value", %args );
}

###
### TIMEBASE
###

=head2 timebase_range

 $keysight->timebase_range(value => 0.00022);

Manually adjust the Oscilloscopes time scale on the x-axis. The timebase range
specifies the time interval on-screen.

=cut

sub timebase_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
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
the external reference input is used as a reference clock for the Oscilloscopes
horizonal scale instead of the internal reference clock.

=cut

sub timebase_clock {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON 1 OFF 0 HFRequency/]) }
    );

    $self->write( command => ":TIMebase:REFClock $value", %args );
}

###
### WAVEFORM
###

=head2 get_waveform

 $keysight->get_waveform(channel => 1);

Query the waveform on any channel. When executing this subroutine the oscilloscope
waits for a trigger event, acquires a full waveform and returns an array reference
containing the scaled time and voltage axis in the form of [\@time, \@voltage].

This acquisition method is called Blocking Synchronisation and should only be
used if the oscilloscope is certain to trigger, for example when measuring a
periodically oscillating signal. For more information see the programming manual
on page 211 and following.

=cut

sub get_waveform {
  my ( $self, $channel, %args ) = validated_channel_getter( \@_);
  if ($channel < 1 or $channel > 4){
    croak "The available channels are 1,2,3 and 4";
  }
  # Capture a waveform after the next trigger event
  $self->write(command => ":DIGitize CHANnel${channel}");
  $self->opc_query();
  # Query some parameters
  my $yOrg = $self->query(command => ":WAVeform:YORigin?");
  my $yInc = $self->query(command => ":WAVeform:YINCrement?");
  my $xOrg = $self->query(command => ":WAVeform:XORigin?");
  my $xInc = $self->query(command => ":WAVeform:XINCrement?");
  my $points = $self->query(command => ":ACQuire:POINts:ANALog?");
  # Compute the required data size in bits depending on the waveform format
  my $format = $self->query(command => ":WAVeform:FORMat?");
  my $fbits;
  if ($format eq 'BYTE') { $fbits = 8; } elsif ($format eq 'WORD') { $fbits = 16; }
  elsif ($format eq 'FLOat') { $fbits = 32; } else { $fbits = 64; }
  # The read length is the amount of acquired points times the bit count plus
  # a small buffer of 128 bits
  my @data = ( split /,/, $self->query(
    command => ":WAVeform:DATA?",
    read_length => $points*$fbits+128
  ));
  # Wait for the data download to complete
  $self->opc_query();
  # Turn on the display for visual feedback
  $self->write(command => ":CHANnel${channel}:DISPlay ON");
  # Rescale the voltage values
  foreach (0..@data-1) {$data[$_] = $data[$_]*$yInc+$yOrg;}
  # Compute the time axis corresponding to each voltage value
  my @times;
  foreach (1..@data) {@times[$_-1] = $_*$xInc+$xOrg}
  # Return a data block containing both the time and voltage values
  return [\@times, \@data];
}

=head2 set_waveform_format

 $keysight->set_waveform_format(value => 'WORD');

This command controls how the data is formatted when it is sent from
the oscilloscope, and pertains to all waveforms. The default format is FLOat.
The possible formats are:

=over

=item * ASCii
ASCii-formatted data consists of waveform data values converted to the currently
selected units, such as volts, and are output as a string of ASCII characters with
each value separated from the next value by a comma.
=item * BYTE
BYTE data is formatted as signed 8-bit integers.
=item * WORD
WORD-formatted data is transferred as signed 16-bit integers in two bytes.
=item * BINary
BINary will return a binary block of (8-byte) uint64 values.
=item * FLOat
FLOat will return a binary block of (4-byte) single-precision floating-point values.

=back

For more information on these formats see the programming manual on page 1564.

=cut

sub set_waveform_format {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ASCii BINary BYTE WORD FLOat/]) }
    );

    $self->write( command => ":WAVeform:FORMat $value", %args );
}

=head2 waveform_source

 $keysight->waveform_source(channel => 1);

Select an input channel for the acquired waveform.

=cut

sub waveform_source {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_, );

    $self->write( command => ":WAVeform:SOURce CHANnel${channel}", %args );
}

###
### CHANNEL
###

=head2 channel_input

 $keysight->channel_input(channel => 'CHANnel1', parameter => 'DC50');

C<parameter> can be either

=over

=item * DC — DC coupling, 1 MΩ impedance.
=item * DC50 | DCFifty — DC coupling, 50Ω impedance.
=item * AC — AC coupling, 1 MΩ impedance.
=item * LFR1 | LFR2 — AC 1 MΩ input impedance.

=back

When no probe is attached, the coupling for each channel can be AC, DC, DC50, or
DCFifty. If you have an 1153A probe attached, the valid parameters are DC, LFR1,
and LFR2 (low-frequency reject). See the programming manual on page 347 for more
information.


=cut

sub channel_input {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        parameter => { isa => enum( [qw/DC DC50 DCFifty LFR1 LFR2/])}
    );
    my $parameter = delete $args{'parameter'};

    $self->write( command => ":CHANnel${channel}:INPut $parameter", %args );
}

=head2 channel_differential

 $keysight->channel_differential(channel => 1, mode => 1);

Turns on or off differential mode. C<mode> is an integer value, where 0 is
false and everything else is true.

=cut

sub channel_differential {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        mode => { isa => 'Int'}
    );
    my $mode = delete $args{'mode'};

    $self->write( command => ":CHANnel${channel}:DIFFerential $mode", %args );
}

=head2 channel_range/channel_offset

 $keysight->channel_range(channel => 1, range => 1);
 $keysight->channel_offset(channel => 1, offset => 0.2);

Allows for manual adjustment of the oscilloscopes vertical voltage range and
-offset for a specific channel. Differential mode is turned on automatically
on execution. C<range> and C<offset> parameters are in volts.

=cut

sub channel_range {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        range => { isa => 'Num'}
    );
    my $range = delete $args{'range'};

    $self->write( command => ":CHANnel${channel}:RANGe $range", %args );
}

sub channel_offset {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        offset => { isa => 'Num'}
    );
    my $offset = delete $args{'offset'};

    $self->write( command => ":CHANnel${channel}:OFFSet $offset", %args );
}

with qw(
    Lab::Moose::Instrument::Common
);

__PACKAGE__->meta()->make_immutable();

1;

__END__
