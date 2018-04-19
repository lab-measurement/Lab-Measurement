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

    # limitation of hardware
    $self->capable_to_query_sweep_points_in_hardware(0);
    $self->capable_to_set_sweep_points_in_hardware(0);
    $self->hardwired_number_of_points_in_sweep(601);

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
 
sub sense_sweep_points_query {
	confess('sub sense_sweep_points_query is not implemented by hardware, we should not be here');
}

sub sense_sweep_points {
    # this hardware has not implemented command to set it in hardware
    # so we just updating the cache
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    confess( "sub sense_sweep_points cannot be supported by hardware" );
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
    my $precision = 'single';
    my $bits_per_point = 32;
    $self->format_data( format => 'Real', length => $bits_per_point );
    # Fixme: replace above 2 lines with the call to the cache friendly data format setter:
    # $self->set_data_format_precision( precision => $precision );
    # which cannot be used now since `format_data_query` treats the default `ASCii` as error

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
