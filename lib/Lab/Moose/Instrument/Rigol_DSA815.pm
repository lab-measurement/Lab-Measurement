package Lab::Moose::Instrument::Rigol_DSA815;

#ABSTRACT: Rigol DSA815 Spectrum Analyzer

use 5.010;

use PDL::Core qw/pdl cat nelem/;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param
    precision_param
    validated_getter
    validated_setter
    validated_channel_getter
    validated_channel_setter
    /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with 'Lab::Moose::Instrument::SpectrumAnalyzer',  qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Sense::Bandwidth
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep
    Lab::Moose::Instrument::SCPI::Display::Window
    Lab::Moose::Instrument::SCPI::Unit

    Lab::Moose::Instrument::SCPI::Initiate

    Lab::Moose::Instrument::SCPIBlock

);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

=head1 SYNOPSIS

 my $data = $fsv->get_spectrum(timeout => 10);

=cut

=head1 METHODS

This driver implements the following high-level method:

=head2 get_spectrum

 $data = $fsv->get_spectrum(timeout => 10, trace => 2, precision => 'double');

Perform a single sweep and return the resulting spectrum as a 2D PDL:

 [
  [freq1,  freq2,  freq3,  ...,  freqN],
  [power1, power2, power3, ..., powerN],
 ]

I.e. the first dimension runs over the sweep points.

This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace (1..6). Defaults to 1.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=cut

### Sense:Sweep:Points emulation
# Rigol DSA815 has no Sense:Sweep:Points implementation
my $hardwired_number_points_in_sweep = 601; # hardwired number of points in sweep

sub sense_sweep_points_from_traceY_query {
    # quite a lot of hardware does not report it, so we deduce it from Y-trace data
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->cached_sense_sweep_points( nelem($self->get_traceY(%args)) );
}

sub sense_sweep_points_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->cached_sense_sweep_points( $self->sense_sweep_points_from_traceY_query(%args) );
}

sub sense_sweep_points {
    # this hardware has not implemented command to set it in hardware
    # so we just updating the cache
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    if ( $value != $hardwired_number_points_in_sweep ) {
        croak "This instrument allows in sweep number of points equal to $hardwired_number_points_in_sweep";
	$value = $hardwired_number_points_in_sweep;
    }

    $self->cached_sense_sweep_points($value);
}


### Trace acquisition implementation
sub get_traceY {
    # grab what is on display for a given trace
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        trace => { isa => 'Int', default => 1 },
    );

    my $trace = delete $args{trace};

    if ( $trace < 1 || $trace > 3 ) {
        croak "trace has to be in (1..3)";
    }

    # Switch to binary trace format
    my $bits_per_point = 32;
    my $precision = 'single';
    $self->format_data( format => 'Real', length => $bits_per_point );

    # Get data.
    my $binary = $self->binary_query(
        command => "TRAC? TRACE$trace",
        %args
    );
    my $traceY = pdl $self->block_to_array(
        binary    => $binary,
        precision => $precision
    );
    return $traceY;
}

sub get_traceX {
    my ( $self, %args ) = @_;
    my $trace = delete $args{trace};

    my $traceX = $self->sense_frequency_linear_array(%args);
    return $traceX;
}

sub get_spectrum {
    my ( $self, %args ) = @_;

    my $traceY = $self->get_traceY( %args );
    # fixme use some sort of switch here
    # number of sweep points is known from the length of traceY
    # so we set it to avoid extra call to get_traceY 
    $self->cached_sense_sweep_points( nelem($traceY) );
    my $traceX = $self->get_traceX( %args );

    return cat( ( pdl $traceX), $traceY );
}

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Format>

=item L<Lab::Moose::Instrument::SCPI::Sense::Bandwidth>

=item L<Lab::Moose::Instrument::SCPI::Sense::Frequency>

=item L<Lab::Moose::Instrument::SCPI::Sense::Sweep>

=item L<Lab::Moose::Instrument::SCPI::Initiate>

=item L<Lab::Moose::Instrument::SCPIBlock>

=back

=cut


__PACKAGE__->meta()->make_immutable();

1;
