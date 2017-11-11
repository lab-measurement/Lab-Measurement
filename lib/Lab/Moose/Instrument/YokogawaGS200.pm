package Lab::Moose::Instrument::YokogawaGS200;

#ABSTRACT: YokogawaGS200 voltage/current source.

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
    $self->cls();

    # FIXME: check protect params
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 my $yoko = instrument(
     type => 'YokogawaGS200',
     connection_type => 'LinuxGPIB',
     connection_options => {gpib_address => 15},
     instrument_options => {
         # mandatory protection settings
         max_units_per_step => 0.001, # max step is 1mV/1mA
         max_units_per_second => 0.01,
         min_units => -10,
         max_units => 10,
     }
 );

 # Step-sweep to new level.
 # Stepsize and speed is given by (max|min)_units* settings.
 $yoko->set_level(value => 9);

 # Get current level from device cache (without sending a query to the
 # instrument):
 my $level = $yoko->cached_level();

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>
=item L<Lab::Moose::Instrument::SCPI::Source::Function>
=item L<Lab::Moose::Instrument::SCPI::Source::Range>

=back
    
=cut

cache source_level => ( getter => 'source_level_query' );

sub source_level_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_source_level(
        $self->query( command => ":SOUR:LEV?", %args ) );
}

sub source_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write(
        command => sprintf( "SOUR:LEV %.17g", $value ),
        %args
    );
    $self->cached_source_level($value);
}

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

=head2 set_level

 $yoko->set_level(value => $new_level);

Go to new level. Sweep with multiple steps if the distance between current and
new level is larger than C<max_units_per_step>.

=cut

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

=head2 cached_level

 my $current_level = $yoko->cached_level();

Get current value from device cache.

=cut

sub cached_level {
    my $self = shift;
    return $self->cached_source_level(@_);
}

=head2 get_level

 my $current_level = $yoko->get_level();

Query current level.

=cut

sub get_level {
    my $self = shift;
    return $self->source_level_query(@_);
}

=head2 set_voltage

 $yoko->set_voltage($value);

For XPRESS voltage sweep. Equivalent to C<< set_level(value => $value) >>.

=cut

sub set_voltage {
    my $self  = shift;
    my $value = shift;
    return $self->set_level( value => $value );
}

=head2 sweep_to_level

 $yoko->sweep_to_level($value);

For XPRESS voltage sweep. Equivalent to C<set_voltage>.

=cut

sub sweep_to_level {
    my $self = shift;
    return $self->set_voltage(@_);
}

__PACKAGE__->meta()->make_immutable();

1;
