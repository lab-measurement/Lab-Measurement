package Lab::Moose::Instrument::DisplayXY;

#ABSTRACT: Display with y vs x traces Role for Lab::Moose::Instrument

use 5.010;

use PDL::Core qw/pdl cat nelem sclr/;
use PDL::NiceSlice;
use PDL::Graphics::Gnuplot;

use Carp;
use Moose::Role;
use Lab::Moose::Plot;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param
    precision_param
    validated_getter
    validated_setter
    validated_channel_getter
    validated_channel_setter
    /;

requires qw(
    get_StartX
    get_StopX
    get_Xpoints_number
    get_traceX
    get_traceY
    get_traceXY 
    get_NameX
    get_UnitX
    get_NameY
    get_UnitY
    display_trace
);

has plotXY => (
    is       => 'ro',
    isa      => 'Lab::Moose::Plot',
    init_arg => undef,
    writer   => '_plotXY',
    predicate => 'has_plotXY'
);

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::DisplayXY - Role of Generic XY display

=head1 DESCRIPTION

Basic commands to grab and display XY traces


=head1 METHODS

Driver assuming this role must implements the following high-level method:

=head2 C<get_traceXY>

 $data = $sa->traceXY(timeout => 10, trace => 2);

Perform a single sweep and return the resulting spectrum as a 2D PDL:

 [
  [x1, x2, x3, ..., xN],
  [y1, y2, y3, ..., yN],
 ]

I.e. the first dimension runs over the sweep points.

This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace (1..3) and similar.

=back

=cut

sub get_traceXY {
    my ( $self, %args ) = @_;

    my $traceY = $self->get_traceY( %args );
    my $traceX = $self->get_traceX( %args );

    return cat( $traceX, $traceY );
}


=head2 get_traceX

 $data = $sa->traceX(timeout => 10);

Return X points of a trace in a 1D PDL:

=cut

sub get_traceX {
    my ( $self, %args ) = @_;
    my $trace = delete $args{trace};

    my $start      = $self->get_StartX(%args);
    my $stop       = $self->get_StopX(%args);
    my $num_points = $self->get_Xpoints_number(%args);
    my $traceX = pdl linspaced_array( $start, $stop, $num_points );
    return $traceX;
}

sub linspaced_array {
    my ( $start, $stop, $num_points ) = @_;

    my $num_intervals = $num_points - 1;

    if ( $num_intervals == 0 ) {
        # Return a single point.
        return [$start];
    }

    my @result;

    for my $i ( 0 .. $num_intervals ) {
        my $f = $start + ( $stop - $start ) * ( $i / $num_intervals );
        push @result, $f;
    }

    return \@result;
}

=head2 get_traceY

 $data = $inst->get_traceY(timeout => 1, trace => 2, precision => 'single');

Return Y points of a given trace in a 1D PDL:

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

=head2 display_trace

 $inst->display_trace(timeout => 1, trace => 2, precision => 'single');

Displays trace data on a computer screen. It adds a new trace to the plot.

=cut

sub display_trace {
    my ( $self, %args ) = @_;
    my $traceXY = $self->get_traceXY( %args );

    #my $plot = Lab::Moose::Plot->new();
    #my $w = gpwin( 'wxt', enhanced=>1 );                                                                                           
    if ( !$self->has_plotXY ) {
	    my $plotXY = Lab::Moose::Plot->new();
	    $self->_plotXY($plotXY);
    }
    my $plotXY = $self->plotXY();

    my $plot_function='plot';
    if ($plotXY->gpwin->{replottable}) {
	# this makes multiple traces on the same plot possible
	$plot_function='replot';
    }

    my %plot_options = (
	    ylab => $self->get_NameY() . " (" . $self->get_UnitY() . ")",
    );

    my $data=$traceXY;
    if ( $traceXY(0,0) == $traceXY(-1,0) ) {
        # zero span
	$data=[$traceXY(:,1)]; # only Y values
	$plot_options{xlab} = "Counts of zero span around" 
	. " " . $self->get_NameX() . " " . sclr($traceXY(0,0)) 
	. " " . $self->get_UnitX();
    } else {
    	$plot_options{xlab} = $self->get_NameX() . " (" . $self->get_UnitX() . ")",
    }
    print $plot_options{xlab};

    my $trace = $args{trace};
    my $trace_str = "trace"."$trace";
    my %curve_options = (
	    with => 'lines',
	    legend => "$trace_str",
    );
    $plotXY->$plot_function(
	    plot_options => \%plot_options, 
	    curve_options => \%curve_options, 
	    data => $data,
    );
}
   
=head2 get_StartX and get_StopX 

Returns start and stop values of X.

=head2 get_Xpoints_number

Returns number of points in the trace.

=cut

1;

