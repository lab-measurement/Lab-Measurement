#!/usr/bin/perl

use Lab::Instrument::HP83732A;
use Lab::Instrument::U2000;
use Time::HiRes qw(usleep);

my $signal=new Lab::Instrument::HP83732A(
    connection_type=>'LinuxGPIB',
    gpib_address => 19,
);

my $powermeter=new Lab::Instrument::U2000(
    connection_type=>'USBtmc',
    tmc_address => 0,
);

sub set_freq
{
    my $freq = shift;
    $signal->set_cw($freq);
    $powermeter->set_frequency($freq);
    usleep(200000);
}

my $error = $powermeter->get_error();
if ($error)
{
    print "Device reported error: $error\nPress Enter to continue";
    <STDIN>
}

$signal->power_on();
set_freq(10e6);
$powermeter->set_average("4");
$powermeter->set_sample_rate("40");
$powermeter->set_trigger("AUTO");


$signal->set_power(0);

for (my $freq=10e6; $freq < 18e9; $freq *= 1.01)
{
    set_freq($freq);
    $read_power = $powermeter->read();
    printf("%10.0f %6.2f\n", $freq, $read_power);

}


1;
