package Lab::Moose::Sweep::Continuous::Voltage;

#ABSTRACT: Continuous sweep of voltage

=head1 SYNOPSIS

 use Lab::Moose;

 # FIXME

=cut

use 5.010;
use Moose;
use Carp;
use Time::HiRes 'time';

extends 'Lab::Moose::Sweep::Continuous';

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Voltage=' );

# level value for filename extensions.
# Only used if separate datafiles are produces for different fields.
# Should use 'step' sweep for this in most cases.
sub get_value {
    my $self = shift;
    return "FIXME";

    # my $from = $self->from;
    # my $to   = $self->to;
    # my $rate = abs( $self->rate );
    # my $sign = $to > $from ? 1 : -1;

    # # Only estimate field.
    # # Do not query field for performance reasons.
    # # Will give wrong results, if the sweep slowly saturates to the setpoint.

    # my $t0 = $self->start_time();
    # if ( not defined $t0 ) {
    #     croak "sweep not started";
    # }
    # my $t = time();
    # return $from + ( $t - $to ) * $sign * $rate / 60;
}

__PACKAGE__->meta->make_immutable();
1;
