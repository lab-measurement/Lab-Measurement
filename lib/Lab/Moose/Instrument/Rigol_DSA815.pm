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
    $self->capable_to_query_number_of_X_points_in_hardware(0);
    $self->capable_to_set_number_of_X_points_in_hardware(0);
    $self->hardwired_number_of_X_points(601);

    $self->clear();
    $self->cls();
}



=head1 Driver for Rigol DSA800 series spectrum analyzers

=head1 METHODS

=head2 get_traceY

 $data = $inst->get_traceY(timeout => 1, trace => 2, precision => 'single');

Trace acquisition implementation. Grabs Y values of displayed trace and returns
them in a 1D pdl.

This implementation is SCPI friendly.

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace 1, 2, 3 and so on. Defaults to 1.
It is hardware depended and validated by C<validate_trace_papam>,
which need to be implemented by a specific instrument driver.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=cut

sub get_traceY {
    # grab what is on display for a given trace
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        precision_param(),
        trace => { isa => 'Int', default => 1 },
    );

    my $precision = delete $args{precision};
    my $trace = delete $args{trace};

    if ( $trace < 1 || $trace > 3 ) {
        croak "trace has to be in (1..3)";
    }

    # Switch to binary trace format
    $self->set_data_format_precision( precision => $precision );
    # above is equivalent to cached call
    # $self->format_data( format => 'Real', length => 32 );

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

=head1 Missing SCPI functionality

Rigol DSA815 has no Sense:Sweep:Points implementation

=head2 sense_sweep_points_query

=head2 sense_sweep_points

=cut
 
sub sense_sweep_points_query {
	confess("sub sense_sweep_points_query is not implemented by hardware, we should not be here");
}

sub sense_sweep_points {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    confess( "sub sense_sweep_points is not implemented by hardware, we should not be here" );
}

=head1 Consumed Roles

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
