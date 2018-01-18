package Lab::Moose::Sweep::Continuous;

#ABSTRACT: Base class for continuous sweeps (temperature, magnetic field)

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
     rate => 1, (Tesla/min)
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
use Moose::Util::TypeConstraints 'enum';
use MooseX::Params::Validate;

# Do not import all functions as they clash with the attribute methods.
use Lab::Moose 'linspace';
use Time::HiRes 'time';

use Carp;

extends 'Lab::Moose::Sweep';

#
# Public attributes set by the user
#

has from     => ( is => 'ro', isa => 'Num', required => 1 );
has to       => ( is => 'ro', isa => 'Num', required => 1 );
has rate     => ( is => 'ro', isa => 'Num', required => 1 );
has interval => ( is => 'ro', isa => 'Num', default  => 0 );

#
# Private attributes used internally
#

has index => (
    is     => 'ro', isa => 'Int', default => 0, init_arg => undef,
    writer => '_index'
);

has current_value => (
    is     => 'ro', isa => 'Num', init_arg => undef,
    writer => '_current_value'
    );

has last_time => (
    is => 'ro', isa => 'Num', init_arg => undef, writer => '_last_time');

sub go_to_next_point {
    my $index  = $self->index();
    if ($index == 0) {
        # first point is special
        # don't have to sleep until the level is reached
    }
    else {
        my $t0 = time();
        
    }

    $self->_index( ++$index );
    # start loop on first point
    # check times, compare with interval, sleep or warn
}

sub go_to_sweep_start {
    my $self = shift;
    $self->_index(0);
    
    my $instrument = $self->instrument();
    $instrument->config_sweep(
        points => $self->from,
        rates => $self->rate
        );
    $instrument->trg();
    $instrument->wait();
}

sub start_sweep {
    my $self = shift;
    my $instrument = $self->instrument();
    $instrument->config_sweep(
        points => $self->to,
        rates => $self->rate
        );
    $instrument->trg();
    $self->_last_time(time());
}

sub sweep_finished {
    my $self   = shift;
    my $index  = $self->index();
    my @points = @{ $self->points };
    if ( $index >= @points ) {
        return 1;
    }
    return 0;
}

sub get_value {
    my $self = shift;
    if ( not defined $self->current_value() ) {
        croak "sweep not yet started";
    }
    return $self->current_value();
}

__PACKAGE__->meta->make_immutable();
1;
