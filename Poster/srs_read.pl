# Read out SR830 lock-in at GPIB address 13
use Lab::Instrument::SR830;

my $sr=new Lab::Instrument::SR830(
	connection_type=>'LinuxGPIB',
	gpib_address => 13,
	gpib_board=>0,
);

my $amp=$sr->get_amplitude();
print "Reference amplitude: $amp V\n";

my $freq=$sr->get_frequency();
print "Reference frequency: $freq Hz\n";

my ($r,$phi)=$sr->get_rphi();
print "Signal             : r=$r V   phi=$phi\n";
