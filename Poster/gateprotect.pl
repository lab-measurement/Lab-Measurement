# declare the gate voltage source
my $YokGate=new Lab::Instrument::Yokogawa7651({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'     => 0,
    'gpib_address'   => 12,
    'gate_protect'   => 1,
    'gp_max_unit_per_second' => 0.05,  # max sweep speed
    'gp_max_step_per_second' => 10,    # max steps per second
    'gp_max_unit_per_step'   => 0.005, # max step size
    'gp_min_unit'            => -2,    # hard negative limit
    'gp_max_unit'            => 0.2,   # hard positive limit
    'fast_set' => 1,
});

# sweep to the start gate voltage -0.5V
$YokGate->set_voltage(-0.5);
