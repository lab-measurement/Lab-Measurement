package Lab::Moose::Instrument::SpectrumAnalyzer;

#ABSTRACT: Role of Generic Spectrum Analyzer for Lab::Moose::Instrument

use 5.010;

use Moose::Role;

requires qw(
    sense_frequency_start_query 
    sense_frequency_start
    sense_frequency_stop_query
    sense_frequency_stop
    sense_sweep_points_query
    sense_sweep_points
    sense_sweep_count_query
    sense_sweep_count
    sense_bandwidth_resolution_query
    sense_bandwidth_resolution
    sense_bandwidth_video_query
    sense_bandwidth_video
    sense_sweep_time_query
    sense_sweep_time
    display_window_trace_y_scale_rlevel_query
    display_window_trace_y_scale_rlevel
    unit_power_query
    unit_power
    get_spectrum
);

1;

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SpectrumAnalyzer - Role of Generic Spectrum Analyzer

=head1 DESCRIPTION

Basic commands to make functional basic spectrum analyzer

=head1 METHODS

Driver assuming this role must implements the following high-level method:

=head2 get_spectrum

 $data = $sa->get_spectrum(timeout => 10, trace => 2);

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

number of the trace (1..3). Defaults to 1.

=back

=cut

