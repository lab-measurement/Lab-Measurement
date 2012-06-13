#!/usr/bin/perl

use strict;
use Lab::Instrument::U2000;
use Lab::Bus::USBtmc;
use Time::HiRes;

################################


my $powermeter=new Lab::Instrument::U2000(
	connection_type=>'USBtmc',
	tmc_address => 0,
);

print "Error: ".$powermeter->get_error();
print "\nID: " . $powermeter->id();

my $start = Time::HiRes::gettimeofday();
for (my $i=0; ; $i++)
{
    my $start2 = Time::HiRes::gettimeofday();
    my $power = $powermeter->triggered_read();
    my $end = Time::HiRes::gettimeofday();
    printf("\nRead: %.2fdBm Measurements per second: %.2f/%.2f", $power, $i/($start-$end), 1/($start2-$end));
}
1;

=pod

=encoding utf-8

=head1 U2000a.pl

Continuously eads out a power values from U2000A power meter.

=head2 Usage example

  $ perl U2000a.pl

=head2 Author / Copyright

  (c) Hermann Kraus 2012

=cut
