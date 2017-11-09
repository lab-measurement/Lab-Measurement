package Lab::Moose::Instrument::DummySource;

#ABSTRACT: Dummy YokogawaGS200 source. Use with Debug connection

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Carp;
use Lab::Moose::Instrument::Cache;

use namespace::autoclean;
use Time::Monotonic 'monotonic_time';
use Time::HiRes 'usleep';

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Source::Function
    Lab::Moose::Instrument::SCPI::Source::Level
    Lab::Moose::Instrument::SCPI::Source::Range
);

has [
    qw/
        max_units_per_second
        max_units_per_step
        min_units
        max_units
        /
] => ( is => 'ro', isa => 'Num', required => 1 );

has source_level_timestamp => (
    is       => 'ro',
    isa      => 'Num',
    writer   => '_source_level_timestamp',
    init_arg => undef,
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cached_source_level(0);
    $self->cached_source_function('VOLT');

    #    $self->cls();

    # FIXME: check protect params
}

=head1 SYNOPSIS


=head1 METHODS

    
=cut

# FIXME: move into role
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

sub linear_step_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        to     => { isa => 'Num' },
        setter => { isa => 'Str|CodeRef' },
        setter_params(),
    );
    my $to             = delete $args{to};
    my $setter         = delete $args{setter};
    my $from           = $self->cached_source_level();
    my $last_timestamp = $self->source_level_timestamp();
    if ( not defined $last_timestamp ) {
        $last_timestamp = monotonic_time();
    }

    my $step = abs( $self->max_units_per_step() );
    my $rate = abs( $self->max_units_per_second() );

    my @steps         = linspace( from => $from, to => $to, step => $step );
    my $time_per_step = $step / $rate;
    my $time          = monotonic_time();

    if ( $time < $last_timestamp ) {

        # should never happen
        croak "time error";
    }

    # When was the last time this function was called?
    if ( $time - $last_timestamp < $time_per_step ) {
        usleep( 1e6 * ( $time_per_step - ( $time - $last_timestamp ) ) );
    }
    $self->$setter( value => shift @steps );

    for my $step (@steps) {
        usleep( 1e6 * $time_per_step );
        $self->$setter( value => $step );
    }
    $self->_source_level_timestamp( monotonic_time() );
}

sub set_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    my $min = $self->min_units();
    my $max = $self->max_units();

    if ( $value < $min ) {
        croak "value $value is below minimum allowed value $min";
    }
    elsif ( $value > $max ) {
        croak "value $value is above maximum allowed value $max";
    }

    return $self->linear_step_sweep(
        to => $value, setter => 'source_level',
        %args
    );
}

#
# Aliases for Lab::XPRESS::Sweep API
#

sub get_level {
    my $self = shift;

    # Dummy Source: do not query!
    return $self->cached_source_level();
}

sub set_voltage {
    my $self  = shift;
    my $value = shift;
    return $self->set_level( value => $value );
}

sub sweep_to_level {
    my $self = shift;
    return $self->set_voltage(@_);
}

1;
