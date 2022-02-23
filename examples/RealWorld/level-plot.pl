#
# plot Helium and Nitrogen levels using Mercury IPS
# 

use Lab::Moose;
use 5.010;
use Time::Local;


my $magnet = instrument(
    type => 'OI_Mercury::Magnet',
    connection_type => 'Socket',
    connection_options => {host => '192.168.1.42'},
    magnet => 'Z',    # 'X', 'Y' or 'Z'. default is 'Z'
    );

my $datafolder = datafolder();

my $datafile = datafile(folder => $datafolder, filename => "levels.dat", columns => [qw/utc local he n2/]);
$datafile->add_plot(
    curves => [{x => 'local', y => 'he', curve_options => {legend => 'He'}}, {x => 'local', y => 'n2', curve_options => {legend => 'N2'}}],
    hard_copy => 'levels.png',
    plot_options => {
	title => "Liquid levels in Dewar",
	xlabel => 'date',
	ylabel => 'level (%)',
	xdata => 'time'
    },
    );

say $magnet->query(command => "*IDN?");

while (1) {
    $datafile->log(
	utc => time(),
	local => timegm(localtime()), # fool gnuplot: first get local time, then convert to Unix timestamp
	he => $magnet->get_he_level(channel => 'DB3.L1'),
	n2 =>  $magnet->get_n2_level(channel => 'DB3.L1'),
	);
    sleep 60;
}
