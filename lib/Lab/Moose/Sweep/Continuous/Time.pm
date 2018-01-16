package Lab::Moose::Sweep::Continuous::Time;

#ABSTRACT: Time sweep

=head1 SYNOPSIS

 use Lab::Moose;

 my $sweep = sweep(
     type => 'Continuous::Time',
     interval => 0.5,
     duration => 60
 );



=cut
    
use 5.010;
use Moose;
use Time::HiRes qw/time sleep/;

extends 'Lab::Moose::Sweep::Continuous';

#
# Public attributes
#

has [qw/+from +to +rate/] => (required => 0);
has interval => (is => 'ro', isa => 'Num', default => 0);
has duration => (is => 'ro', isa => 'Num');


# use go_to_next_point from parent

sub go_to_sweep_start {
    my $self = shift;
    $self->_index(0);
}

sub start_sweep {
    my $self = shift;
    $self->_start_time(time());
}

sub sweep_finished {
    my $self = shift;
    my $duration = $self->duration;
    if (defined $duration) {
        my $start_time = $self->start_time;
        if (time() - $start_time > $duration) {
            return 1;
        }
    }
    return 0;
}

sub get_value {
    my $self = shift;
    return time();
}

__PACKAGE__->meta->make_immutable();
1;
