package Lab::Moose::Sweep::Continuous;

#ABSTRACT: Base class for continuous sweeps (time, temperature, magnetic field)

=head1 SYNOPSIS

 use Lab::Moose;

 #
 # 1D sweep of magnetic field
 #
 
 my $ips = instrument(
     type => 'OI_Mercury::Magnet'
     connection_type => ...,
     connection_options => {...}
 );

 my $multimeter = instrument(...);
 
 my $sweep = sweep(
     type => 'Continuous::Magnet',
     instrument => $ips,
     from => -1, # Tesla
     to => 1,
     rate => 0.1, (Tesla/min, always positive)
     start_rate => 1, (optional) rate to approach start point
     interval => 0.5, # one measurement every 0.5 seconds
 );

 my $datafile = sweep_datafile(columns => ['B-field', 'current']);
 $datafile->add_plot(x => 'B-field', y => 'current');
 
 my $meas = sub {
     my $sweep = shift;
     my $field = $ips->get_field();
     my $current = $multimeter->get_value();
     $sweep->log('B-field' => $field, current => $current);
 };

 $sweep->start(
     datafiles => [$datafile],
     measurement => $meas,
 );

=head1 DESCRIPTION

This C<sweep> constructor defines the following arguments

=over

=item * from/to

=item * rate

=item * interval

If C<interval> is C<0>, do as much measurements as possible.

Warn if measurement requires more time than C<interval>.


=back

=cut

use 5.010;
use Moose;
use MooseX::Params::Validate;

# Do not import all functions as they clash with the attribute methods.
use Lab::Moose 'linspace';
use Time::HiRes qw/time sleep/;

use Carp;

extends 'Lab::Moose::Sweep';

#
# Public attributes set by the user
#

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

# has from => ( is => 'ro', isa => 'Num', required => 1, writer => '_from' );
# has to   => ( is => 'ro', isa => 'Num', required => 1, writer => '_to' );
# has rate => ( is => 'ro', isa => 'Lab::Moose::PosNum', required => 1 );

# FIXME: make copy of original array refs
has points => (
    is => 'ro', isa => 'ArrayRef[Num]', traits => ['Array'],
    handles  => { shift_points => 'shift', num_points => 'count' },
    required => 1
);

has intervals => (
    is      => 'ro',
    isa     => 'ArrayRef[Num]',
    traits  => ['Array'],
    handles => {
        shift_intervals => 'shift', get_interval => 'get',
        num_intervals   => 'count'
    },
    required => 1
);

has rates => (
    is => 'ro', isa => 'ArrayRef[Num]', traits => ['Array'],
    handles  => { shift_rates => 'shift', num_rates => 'count' },
    required => 1
);

# has start_rate =>
# ( is => 'ro', isa => 'Lab::Moose::PosNum', writer => '_start_rate' );
#has backsweep => ( is => 'ro', isa => 'Bool', default => 0 );

#
# Private attributes used internally
#

has index => (
    is => 'ro', isa => 'Lab::Moose::PosInt', default => 0, init_arg => undef,
    writer => '_index'
);

has start_time =>
    ( is => 'ro', isa => 'Num', init_arg => undef, writer => '_start_time' );

# has in_backsweep => (
#     is     => 'ro', isa => 'Bool', init_arg => undef,
#     writer => '_in_backsweep'
# );

sub BUILD {
    my $self = shift;

    # check if rate is defined. The Time subclass does not use the rate
    # parameter
    if ( defined $self->points ) {
        my $num_points    = $self->num_points;
        my $num_rates     = $self->num_rates;
        my $num_intervals = $self->num_intervals;

        if ( $num_points < 2 ) {
            croak "need at least two points";
        }
        if ( $num_rates != $num_points or $num_intervals != $num_points - 1 )
        {
            croak "need same number of points and rates and intervals";
        }
    }

    # TODO: handle from, to, rate, start_rate params
    # TODO: fill rates and intervals if too short
    # TODO: handle backsweeps: just add more points ?!

    # check if rate is defined. The Time subclass does not use the rate
    # parameter
    # if ( defined $self->rate ) {
    #     if ( not defined $self->start_rate ) {
    #         $self->_start_rate( $self->rate );
    #     }
    # }
}

sub go_to_next_point {
    my $self     = shift;
    my $index    = $self->index;
    my $interval = $self->get_interval(0);
    if ( $index == 0 or $interval == 0 ) {

        # first point is special
        # don't have to sleep until the level is reached
    }
    else {
        my $t           = time();
        my $target_time = $self->start_time + $index * $interval;
        if ( $t < $target_time ) {
            sleep( $target_time - $t );
        }
        else {
            my $prev_target_time
                = $self->start_time + ( $index - 1 ) * $interval;
            my $required = $t - $prev_target_time;
            carp <<"EOF";
WARNING: Measurement function takes too much time:
required time: $required
interval: $interval
EOF
        }

    }
    $self->_index( ++$index );
}

sub go_to_sweep_start {
    my $self = shift;
    $self->_index(0);
    my $point = $self->shift_points();
    my $rate  = $self->shift_rates();
    carp <<"EOF";
Going to sweep start:
Setpoint: $point
Rate: $rate
EOF
    my $instrument = $self->instrument();
    $instrument->config_sweep(
        points => $point,
        rates  => $rate
    );
    $instrument->trg();
    $instrument->wait();
}

sub start_sweep {
    my $self       = shift;
    my $instrument = $self->instrument();
    my $to         = $self->shift_points();
    my $rate       = $self->shift_rates();
    carp <<"EOF";
Starting sweep
Setpoint: $to
Rate: $rate
EOF
    $instrument->config_sweep(
        points => $to,
        rates  => $rate,
    );
    $instrument->trg();
    $self->_start_time( time() );
    $self->_index(0);
}

sub sweep_finished {
    my $self = shift;
    if ( $self->instrument->active() ) {
        return 0;
    }

    # finished one segment of the sweep
    if ( $self->num_points > 0 ) {

        # continue with next point
        $self->start_sweep();
        $self->shift_intervals();
        return 0;
    }
    else {
        # finished all points!
        return 1;
    }
}

# implement get_value in subclasses.

__PACKAGE__->meta->make_immutable();
1;
