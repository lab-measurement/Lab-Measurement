# Read out SR830 Lock In Amplifier at GPIB address 13
use warnings;
use strict;
use 5.010;
use Lab::Measurement;

my $lia = Instrument(
    'SR830',
    {
        connection_type => 'LinuxGPIB',
        gpib_address    => 13,
    }
);

my $amp = $lia->get_amplitude();
say "Reference output amplitude: $amp V";

my $freq = $lia->get_frequency();
say "Reference frequency: $freq Hz";

my ( $r, $phi ) = $lia->get_rphi();
say "Signal: r=$r V   phi=$phi degree";
