package Lab::Moose::Instrument::Rigol_DG5000;

#ABSTRACT: Rigol DG5000 series Function/Arbitrary Waveform Generator

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use List::Util qw/sum/;
use List::MoreUtils qw/minmax/;
use Math::Round;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter validated_getter validated_setter/;
use Lab::Moose::Instrument::Cache;
use Carp 'croak';
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x1ab1, pid => 0x0640 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

sub get_default_channel {
    return '';
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 my $rigol = instrument(
    type => 'Rigol_DG5000',
    connection_type => 'USB' # For NT-VISA use 'VISA::USB'
    );


All C<source_*> commands accept a C<channel> argument, which can be 1 (default)
or 2:

 $rigol->source_function_shape(value => 'SIN'); # Channel 1
 $rigol->source_function_shape(value => 'SQU', channel => 2); # Channel 2

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=cut

#
# MY FUNCTIONS
#

=head2 gen_arb_step

$rigol->gen_arb_step(channel => 1, value => [
  0.2,  0.00002,
  0.5,  0.0001,
  0.35, 0.0001
  ], bdelay => 0, bcycles => 1
);

Generate an arbitrary voltage step function. With C<value> an array referrence is
passed to the function, containing data pairs of an amplitude and time value.
In the example above repeatedly outputs a constant 200mV for 20µs, 500mV for
100µs and 350mV for 100µs.

WORK IN PROGRESS: With C<bdelay> and C<bcycles> a delay between a specified
amount of cycles is enabled using the Rigols burst mode.

 If C<bdelay> = 0 the burst mode is disabled.

=cut

sub gen_arb_step {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value   => { isa => 'ArrayRef' },
        bdelay  => { isa => 'Num' },
        bcycles => { isa => 'Num' }
    );
    my @data = @$value;    # Dereference the input data
    my ( $bdelay, $bcycles ) = delete @args{qw/bdelay bcycles/};

    # If number of input data points is uneven croak
    if ( @data % 2 != 0 ) {
        croak "Please enter an even number of arguments with
    the layout <amplitude1[V]>,<length1[s]>,<amplitude2[V]>,<length2[s]>,...";
    }

    # Split input data into the time lengths and amplitude values...
    my @times = @data[ grep { $_ % 2 == 1 } 0 .. @data - 1 ];
    my @amps  = @data[ grep { $_ % 2 == 0 } 0 .. @data - 1 ];

    # ...and compute the period lentgth as well as the min and max amplitude
    my $period = sum @times;
    my ( $minamp, $maxamp ) = minmax @amps;

    # now apply everything to the Rigol: Frequency = 1/T, amplitude and offset
    # are computed, so that the whole waveform lies within that amplitude range
    $self->source_apply_arb(
        channel => $channel,          freq  => 1 / $period,
        amp     => 2 * abs($maxamp) + 2 * abs($minamp),
        offset  => $maxamp + $minamp, phase => 0.0
    );
    $self->arb_mode( channel => $channel, value => 'INTernal' );
    $self->trace_data_points_interpolate( value => 'OFF' );

    # Convert all amplitudes into values from 0 to 16383 (14Bit) and generate
    # 16384 data points in total
    my $input = "";
    my $counter;

    # go through each amp (or time) value
    foreach ( 0 .. @amps - 1 ) {

        # Compute what length in units of the resolution (16384) each step has
        my $c = round( 16383 * $times[$_] / $period );
        $counter += $c;    # Count them all up
          # On the last iteration check, if there are really 16384 data points,
          # there might be less because of rounding. Add the remaining at the end if
          # necessary
        if ( $_ == @amps - 1 && $counter != 16384 ) { $c += 16384 - $counter }

        # Lastly append the according amplitude value (in 14Bit resolution) to the
        # whole string
        $input = $input
            . (
            ","
                . round(
                16383 * $amps[$_] / ( 1.5 * $maxamp - 0.5 * $minamp )
                )
            ) x $c;
    }

    # Finally download everything to the volatile memory
    $self->trace_data_points( value => 16384 );
    $self->trace_data_dac( value => $input );

    my $off = 0;
    if ( $bdelay > 0 ) {
        $self->source_burst_mode( channel => $channel, value => 'TRIG' );
        $self->source_burst_tdelay( channel => $channel, value => $bdelay );
        $self->source_burst_ncycles( channel => $channel, value => $bcycles );
        $self->source_burst_state( channel => $channel, value => 'ON' );

        $self->trace_data_value( point => 0,     data => 0 );
        $self->trace_data_value( point => 16383, data => 0 );
        $off = $amps[0];
    }
}

=head2 arb_mode

 $rigol->arb_mode(value => 'INTernal');

Allowed values: C<INT, INTernal, PLAY>

=cut

sub arb_mode {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/INT INTernal PLAY/] ) }
    );

    $self->write(
        command => ":SOURCE${channel}:FUNCtion:ARB:MODE $value",
        %args
    );
}

=head2 phase_align

 $rigol->phase_align();

Phase-align the two output channels.

=cut

sub phase_align {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_, );

    $self->write( command => ":SOURce${channel}:PHASe:INITiate", %args );
}

=head2 output_toggle

 $rigol->source_apply_pulse(channel => 1, state => 'ON');

Turn output channels on or off, allowed values: C<ON, OFF>

=cut

sub output_toggle {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) }
    );

    $self->write( command => "OUTPUT${channel} $value", %args );
}

#
# SOURCE APPLY
#

=head2 source_apply_ramp

 $rigol->source_apply_ramp(
     freq => ...,
     amp => ...,
     offset => ....,
     phase => ...
 );

=cut

sub source_apply_ramp {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command => "SOURCE${channel}:APPLY:RAMP $freq,$amp,$offset,$phase",
        %args
    );
}

=head2 source_apply_pulse

 $rigol->source_apply_pulse(freq => 50000000, amp => 1, offset => 0, delay => 0.000001);

=cut

sub source_apply_pulse {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        delay  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $delay )
        = delete @args{qw/freq amp offset delay/};

    $self->write(
        command => "SOURCE${channel}:APPLY:PULSE $freq,$amp,$offset,$delay",
        %args
    );
}

=head2 source_apply_sinusoid

 $rigol->source_apply_sinusoid(freq => 50000000, amp => 1, offset => 0, phase => 0);

=cut

sub source_apply_sinusoid {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command =>
            "SOURCE${channel}:APPLY:SINUSOID $freq,$amp,$offset,$phase",
        %args
    );
}

=head2 source_apply_square

 $rigol->source_apply_square(freq => 50000000, amp => 1, offset => 0, phase => 0);

=cut

sub source_apply_square {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command => "SOURCE${channel}:APPLY:SQUare $freq,$amp,$offset,$phase",
        %args
    );
}

=head2 source_apply_arb

 $rigol->source_apply_arb(freq => 50000000, amp => 1, offset => 0, phase => 0);

=cut

sub source_apply_arb {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command => "SOURCE${channel}:APPLY:USER $freq,$amp,$offset,$phase",
        %args
    );
}

#
# SOURCE BURST
#

=head2 source_burst_mode/source_burst_mode_query

 $rigol->source_burst_mode(value => 'TRIG');
 say $rigol->source_burst_mode_query();

Allowed values: C<TRIG, GAT, INF>.


=cut

sub source_burst_mode {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/TRIG GAT INF/] ) }
    );

    $self->write( command => "SOURCE${channel}:BURST:MODE $value", %args );
}

sub source_burst_mode_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:BURST:MODE?", %args );
}

=head2 source_burst_ncycles/source_burst_ncycles_query

 $rigol->source_burst_ncycles(value => 1);
 say $rigol->source_burst_ncycles_query();

=cut

sub source_burst_ncycles {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );

    $self->write( command => "SOURCE${channel}:BURST:NCYCLES $value", %args );
}

sub source_burst_ncycles_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:NCYCLES?",
        %args
    );
}

=head2 source_burst_state/source_burst_state_query

 $rigol->source_burst_state(value => 'ON');
 say $rigol_source_burst_state_query();

Allowed values: C<ON, OFF>


=cut

sub source_burst_state {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) }
    );

    $self->write( command => "SOURCE${channel}:BURST:STATE $value", %args );
}

sub source_burst_state_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:BURST:STATE?", %args );
}

=head2 source_burst_tdelay/source_burst_tdelay_query

 $rigol->source_burst_tdelay(value => 1e-3);
 say $rigol->source_burst_tdelay_query();

=cut

sub source_burst_tdelay {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write( command => "SOURCE${channel}:BURST:TDELAY $value", %args );
}

sub source_burst_tdelay_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:BURST:TDELAY?", %args );
}

=head2 source_burst_trigger

 $rigol->source_burst_trigger();

=cut

sub source_burst_trigger {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:IMMEDIATE",
        %args
    );
}

=head2 source_burst_trigger_slope/source_burst_trigger_slope_query

 $rigol->source_burst_trigger_slope(value => 'POS');
 say $rigol->source_burst_trigger_slope_query();

Allowed values: C<POS, NEG>.

=cut

sub source_burst_trigger_slope {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/POS NEG/] ) }
    );

    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:SLOPE $value",
        %args
    );
}

sub source_burst_trigger_slope_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:TRIGGER:SLOPE?",
        %args
    );
}

=head2 source_burst_trigger_trigout/source_burst_trigger_trigout_query

 $rigol->source_burst_trigger_trigout(value => 'POS');
 $rigol->source_burst_trigger_trigout_query();

Allowed values: C<POS, NEG, OFF>.

=cut

sub source_burst_trigger_trigout {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/OFF POS NEG/] ) }
    );

    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:TRIGOUT $value",
        %args
    );
}

sub source_burst_trigger_trigout_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:TRIGGER:TRIGOUT?",
        %args
    );
}

=head2 source_burst_trigger_source/source_burst_trigger_source_query

 $rigol->source_burst_trigger_source(value => 'INT');
 $rigol->source_burst_trigger_source_query();

Allowed values: C<INT, EXT>.

=cut

sub source_burst_trigger_source {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/INT EXT/] ) }
    );

    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:SOURCE $value",
        %args
    );
}

sub source_burst_trigger_source_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:TRIGGER:SOURCE?",
        %args
    );
}

=head2 source_burst_period

 $rigol->source_burst_period(value => 0.00001);

=cut

sub source_burst_period {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write(
        command => "SOURCE${channel}:BURST:INTERNAL:PERIOD $value",
        %args
    );
}

#
# SOURCE FUNCTION
#

=head2 source_function_shape/source_function_shape_query

 $rigol->source_function_shape(value => 'SIN');
 say $rigol->source_function_shape_query();

Allowed values: C<SIN, SQU, RAMP, PULSE, NOISE, USER, DC, SINC, EXPR, EXPF, CARD, GAUS, HAV, LOR, ARBPULSE, DUA>.

=cut

sub source_function_shape {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => {
            isa => enum(
                [
                    qw/SIN SQU RAMP PULSE NOISE USER DC SINC EXPR EXPF CARD GAUS HAV LOR ARBPULSE DUA/
                ]
            )
        }
    );

    $self->write(
        command => "SOURCE${channel}:FUNCTION:SHAPE $value",
        %args
    );
}

sub source_function_shape_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:FUNCTION:SHAPE?",
        %args
    );
}

=head2 source_function_ramp_symmetry/source_function_ramp_symmetry_query

 $rigol->source_function_ramp_symmetry(value => 100);
 say $rigol->source_function_ramp_symmetry_query();

=cut

sub source_function_ramp_symmetry {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write(
        command => "SOURCE${channel}:FUNCTION:RAMP:SYMMETRY $value",
        %args
    );
}

sub source_function_ramp_symmetry_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:FUNCTION:RAMP:SYMMETRY?", %args );
}

#
# SOURCE PERIOD
#

=head2 source_period_fixed/source_period_fixed_query

 $rigol->source_period_fixed(value => 1e-3);
 say $rigol->source_period_fixed_query();

=cut

sub source_period_fixed {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write( command => "SOURCE${channel}:PERIOD:FIXED $value", %args );
}

sub source_period_fixed_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:PERIOD:FIXED?", %args );
}

#
# TRACE
#

=head2 trace_data_data

 my $values = [-0.6,-0.5,-0.4,-0.3,-0.2,-0.1,0,0.1,0.2,0.3,0.4,0.5,0.6];
 $rigol->trace_data_data(data => $values);

=cut

sub trace_data_data {
    my ( $self, %args ) = validated_getter(
        \@_,
        data => { isa => 'ArrayRef[Num]' }
    );

    my $data = delete $args{data};
    my @data = @{$data};
    if ( @data < 1 ) {
        croak("empty data argument");
    }

    $data = join( ',', @data );

    $self->write( command => "TRACE:DATA:DATA VOLATILE,$data", %args );
}

=head2 trace_data_value, trace_data_value_query

 $rigol->trace_data_value(point => 2, data => 8192);

Modify the second point to the decimal number 8192.

 $rigol->trace_data_value_query(point => 2);

=cut

sub trace_data_value {
    my ( $self, %args ) = validated_getter(
        \@_,
        point => { isa => 'Lab::Moose::PosInt' },
        data  => { isa => 'Num' }
    );
    my $point = delete $args{point};
    my $data  = delete $args{data};

    $self->write(
        command => "TRACE:DATA:VALUE VOLATILE,$point,$data",
        %args
    );
}

sub trace_data_value_query {
    my ( $self, %args ) = validated_getter(
        \@_,
        point => { isa => 'Lab::Moose::PosInt' },
    );
    my $point = delete $args{point};

    return $self->query(
        command => "TRACE:DATA:VALUE? VOLATILE,$point",
        %args
    );
}

=head2 trace_data_points, trace_data_points_query

 $rigol->trace_data_points(value => 3);
 say $rigol->trace_data_points_query();

=cut

sub trace_data_points {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );

    if ( $value < 2 ) {
        croak("The minimum number of inital data points is 2");
    }

    $self->write( command => "TRACE:DATA:POINTS VOLATILE,$value", %args );
}

sub trace_data_points_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "TRACE:DATA:POINTS? VOLATILE", %args );
}

=head2 trace_data_points_interpolate, trace_data_points_interpolate_query

 $rigol->trace_data_points_interpolate(value => 'LIN');
 say $rigol->trace_data_points_interpolate_query();

Allowed values: C<LIN, SINC, OFF>.

=cut

sub trace_data_points_interpolate {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/LIN SINC OFF/] ) },
    );
    $self->write( command => "TRACE:DATA:POINTS:INTERPOLATE $value", %args );
}

sub trace_data_points_interpolate_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "TRACE:DATA:POINTS:INTERPOLATE?", %args );
}

=head2 trace_data_points_interpolate, trace_data_points_interpolate_query

 $rigol->trace_data_dac(value => '16383,8192,0,0,8192,8192,6345,0');

Input a string of comma-seperated integers ranging from 0 to 16383 (14Bit). If
there are less than 16384 data points given, the Rigol will automatically
interpolate.

=cut

sub trace_data_dac {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Str' }
    );
    if ( substr( $value, 0, 1 ) eq ',' ) {
        $self->write( command => "TRACE:DATA:DAC VOLATILE$value", %args );
    }
    else {
        $self->write( command => "TRACE:DATA:DAC VOLATILE,$value", %args );
    }
}

with qw(
    Lab::Moose::Instrument::Common
);

__PACKAGE__->meta()->make_immutable();

1;
