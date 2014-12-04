#-------- 0. Import Lab::Measurement -------

use Lab::Measurement;

#-------- 1. Initialize Instruments --------

my $bias = Instrument('Yokogawa7651', 
	{
	connection_type => 'VISA_GPIB',
	gpib_address => 3,
	gate_protect => 0
	});

my $multimeter = Instrument('Agilent34410A', 
	{
	connection_type => 'VISA_GPIB',
	gpib_address => 17,
	nplc => 10			# integration time in number of 
					# powerline cylces [10*(1/50)]
	});

my $gate = Instrument('Yokogawa7651', 
	{
	connection_type => 'VISA_GPIB',
	gpib_address => 6,

	gate_protect => 1,
	gp_min_units => -10,
	gp_max_units => 15,
	gp_max_units_per_second => 10e-3
	});

#-------- 2. Define the Sweeps -------------
my $gate_sweep = Sweep('Voltage', 
	{
	mode => 'step',
	instrument => $gate,
	points => [-5, 5],		# [starting point, target] in Volt
	stepwidth => [0.1],
	rate => [5e-3],			# [rate to approach start, sweeping 
					# rate for measurement] in Volt/s
	});

my $bias_sweep = Sweep('Voltage', 
	{
	instrument => $bias,
	points => [-5e-3, 5e-3],	# [starting point, target] in Volt
	rate => [0.1, 0.5e-3],		# [rate to approach start, sweeping 
					# rate for measurement] in Volt/s
	interval => 1, 			# measurement interval in s

	delay_before_loop => 10 	# delay before sweep begins in s
	});

#-------- 3. Create a DataFile -------------

my $DataFile = DataFile('Gate_IV_sample1.dat');

$DataFile->add_column('GateVoltage');
$DataFile->add_column('BiasVoltage');
$DataFile->add_column('Current');
$DataFile->add_column('Resistance');

$DataFile->add_plot({
	'type'	  => 'pm3d'
	'x-axis'  => 'GateVoltage',
	'y-axis'  => 'BiasVoltage',
	'cb-axis' => 'Current'
	});

#-------- 4. Measurement Instructions -------

my $my_measurement = sub {

	my $sweep = shift;

	my $gate_voltage = $gate->get_value();		# gate voltage source
	my $bias_voltage = $bias->get_value();		# bias voltage source
	my $current = $multimeter->get_value()*1e-7;	# I/V converter output
	my $resistance = ($current != 0) ? $voltage/$current : '?';

	$sweep->LOG({
		GateVoltage => $gate_voltage,
		Voltage => $bias_voltage,
		Current => $current,
		Resistance => $resistance
		});
};

#-------- 5. Put everything together -------

$DataFile->add_measurement($my_measurement);

$voltage_sweep->add_DataFile($DataFile);

my $frame = Frame();
$frame->add_master($gate_sweep);			# the outer, slow loop
$frame->add_slave($bias_sweep);				# the inner, fast loop

$frame->start();

1;
