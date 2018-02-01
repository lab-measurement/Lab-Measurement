#!/usr/bin/env perl

use Lab::Moose;

# After Oxford Instruments Technical Note
# "Remnant fields in superconducting magnets"

# They use a cycling routine with starting field of 1T.

# The reduction factor is about 0.8 (apparently from the graph).
# I.e. the target field values are 1T, -0.8T, 0.64T, ...

# The reduction factor is also applied on the rate,
# so that the time between zero crossings of the field is roughly constant

# They use a start rate of about 2.4 T/min.
# Our OI Mercury provides a max rate of 1T/min, so we use that as start rate.

my $start_field      = 1;        # Tesla
my $start_rate       = 1;        # Tesla/min
my $reduction_factor = 0.8;
my $stop_field       = 0.001;    # 1mT

my $magnet = instrument(
    type               => 'OI_Mercury::Magnet',
    connection_type    => 'Socket',
    connection_options => { host => '192.168.3.15' },  # use default port 7020
);

my $target = $start_field;
my $rate   = $start_rate;

warn <<"EOF";
Performing cycles with reduction factor $reduction_factor
until field is smaller than $stop_field
EOF

# Start at 0 T
$magnet->sweep_to_field( target => 0, rate => 1 );

while ( $target > $stop_field ) {
    $magnet->sweep_to_field( target => $target, rate => $rate );
    $target *= -$reduction_factor;
    $rate   *= $reduction_factor;
}
