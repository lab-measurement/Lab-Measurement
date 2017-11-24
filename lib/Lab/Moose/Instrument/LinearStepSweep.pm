package Lab::Moose::Instrument::LinearStepSweep;

#ABSTRACT: Role for linear step sweeps used by voltage/current sources.

use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument 'setter_params';

# time() returns floating seconds.
use Time::HiRes qw/time usleep/;

use Carp;

requires qw/max_units_per_second max_units_per_step min_units max_units
    source_level cached_source_level source_level_timestamp/;

sub linspace {
    my ( $from, $to, $step ) = validated_list(
        \@_,
        from => { isa => 'Num' },
        to   => { isa => 'Num' },
        step => { isa => 'Num' },
    );

    $step = abs($step);
    my $sign = $to > $from ? 1 : -1;

    my @steps;
    for ( my $i = 1;; ++$i ) {
        my $point = $from + $i * $sign * $step;
        if ( ( $point - $to ) * $sign >= 0 ) {
            last;
        }
        push @steps, $point;
    }
    return ( @steps, $to );
}

=head1 METHODS

=head2 linear_step_sweep

 $source->linear_step_sweep(
     to => $new_level,
     timeout => $timeout # optional
 );

=cut

sub linear_step_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        to => { isa => 'Num' },
        setter_params(),
    );
    my $to             = delete $args{to};
    my $from           = $self->cached_source_level();
    my $last_timestamp = $self->source_level_timestamp();

    # Enforce max_units/min_units.
    my $min = $self->min_units();
    my $max = $self->max_units();
    if ( $to < $min ) {
        croak "target $to is below minimum allowed value $min";
    }
    elsif ( $to > $max ) {
        croak "target $to is above maximum allowed value $max";
    }

    if ( not defined $last_timestamp ) {
        $last_timestamp = time();
    }

    # Enforce step size and rate.
    my $step = abs( $self->max_units_per_step() );
    my $rate = abs( $self->max_units_per_second() );
    if ( $step < 1e-9 ) {
        croak "step size must be > 0";
    }
    if ( $rate == 1e-9 ) {
        croak "rate must be > 0";
    }

    my @steps         = linspace( from => $from, to => $to, step => $step );
    my $time_per_step = $step / $rate;
    my $time          = time();

    if ( $time < $last_timestamp ) {

        # should never happen
        croak "time error";
    }

    # Do we have to wait to enforce the maximum rate or can we start right now?
    my $waiting_time = $time_per_step - ( $time - $last_timestamp );
    if ( $waiting_time > 0 ) {
        usleep( 1e6 * $waiting_time );
    }
    $self->source_level( value => shift @steps, %args );

    my $autoflush = STDOUT->autoflush();
    for my $step (@steps) {
        usleep( 1e6 * $time_per_step );

        #  YokogawaGS200 has 5 + 1/2 digits precision
        printf(
            "Sweeping to %.5g: Setting level to %.5e          \r", $to,
            $step
        );
        $self->source_level( value => $step, %args );
    }
    print " " x 70 . "\r";
    STDOUT->autoflush($autoflush);
    $self->source_level_timestamp( time() );
}

=head1 REQUIRED METHODS

The following methods are required for role consumption:
C<max_units_per_second, max_units_per_step, min_units, max_units,
source_level, cached_source_level, source_level_timestamp > 

=cut

1;
