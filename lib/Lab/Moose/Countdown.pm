package Lab::Moose::Countdown;

#ABSTRACT: Verbose countdown/delay with pretty printing of remaining time

use v5.20;

use warnings;
use strict;

use Exporter 'import';
use Time::HiRes qw/time sleep/;
use Time::Seconds;

our @EXPORT = qw/countdown/;

=head1 SYNOPSIS

 use Lab::Moose::Countdown;

 # Sleep for 23.45678 seconds with pretty countdown
 countdown(23.45678, "Getting ready, Remaining time is ");

=cut

=head1 FUNCTIONS

=head2 countdown

 my $delay = 2 # seconds
 countdown($delay)

 my $prefix = "Some prefix text";
 countdown($delay, $prefix);

Replacement for C<Time::HiRes::sleep>. Pretty print the remaining
hours/minutes/seconds. If the argument is smaller than 0.5 seconds, no
countdown is printed and the function behaves exactly like C<Time::HiRes::sleep>.
Default C<$prefix> is C<"Sleeping for">.

=cut

sub countdown {

    # Do not use MooseX::Params::Validate for performance reasons.
    my $delay = shift;
    my $prefix = shift // "Sleeping for ";

    if ( $delay < 0.5 ) {
        if ( $delay > 0 ) {
            sleep $delay;
        }
        return;
    }

    my $t1 = time();

    my $autoflush = STDOUT->autoflush();

    while () {
        my $remaining = $delay - ( time() - $t1 );
        if ( $remaining < 0.5 ) {
            if ( $remaining > 0 ) {
                sleep $remaining;
            }
            last;
        }
        $remaining = Time::Seconds->new( int($remaining) + 1 );
        sleep 0.1;
        print $prefix, $remaining->pretty, "               \r";
    }
    say " " x 80;
    STDOUT->autoflush($autoflush);
}

