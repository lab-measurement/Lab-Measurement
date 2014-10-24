use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::OI_IPS;
use Lab::Instrument::HP34401A;
use Lab::Instrument::SR830;
use Lab::Measurement;

# measurement range and resolution
my $Vbiasstart = -0.0036;	# V, after divider
my $Vbiasstop = 0.0036;		# V, after divider
my $Vbiasstep = 0.00002;	# V, after divider
my $Bstart=0.1;			# T
my $Bstop=0;			# T
my $Bstep=0.01;			# T

# general measurement settings and constants
my $Vbiasdivider = 0.01;	# <1, voltage divider value
my $currentamp = 1e-9;		# A/V
my $sample = "nanotube";
my @starttime = localtime(time);
my $startstring=sprintf("%04u-%02u-%02u_%02u-%02u-%02u",
                         $starttime[5]+1900,$starttime[4]+1,$starttime[3],
                         $starttime[2],$starttime[1],$starttime[0]);
my $title = "Bias versus magnetic field";
my $filename = $startstring."_biasfield";

# the bias voltage source
my $YokBias=new Lab::Instrument::Yokogawa7651({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'    => 0,   'gpib_address'  => 3,
    'gate_protect'  => $Vbiasprotect,
    'gp_max_unit_per_second' => 0.05/$Vbiasdivider,
    'gp_max_step_per_second' => 10,
    'gp_max_unit_per_step' => 0.005/$Vbiasdivider,
    'fast_set' => 1,
});

# the lock-in: ac measurement         
my $SRS = new Lab::Instrument::SR830({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'    => 0,   'gpib_address'  => 8,
});
	  
# the multimeter: dc measurement
my $HP = new Lab::Instrument::HP34401A({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'    => 0,   'gpib_address'  => 12,
});

# the superconducting magnet control
my $magnet=new Lab::Instrument::IPS12010({
    'connection_type' => 'LinuxGPIB',
    'gpib_board'    => 0,   'gpib_address'  => 24,
});

# general comments for the log 
my $comment=<<COMMENT;
Bias sweeps versus magnetic field; gate voltage -3.74 V
B from $Bstart to $Bstop step size $Bstep
Bias voltage from $Vbiasstart to $Vbiasstop step size $Vbiasstep
Current preamp $currentamp A/V
SRS lock-in: integrate 100ms, freq 117.25Hz, sensit. 10mV
COMMENT

# the "measurement": things like filename, live plot, etc, 
# plus all the metadata (data file columns, axes, plots, ...)
my $measurement=new Lab::Measurement(
    sample          => $sample,        title           => $title,
    filename_base   => $filename,      description     => $comment,
    live_plot       => 'currentacx',   live_refresh    => '200',
    constants       => [
        {   'name'          => 'currentamp',
            'value'         => $currentamp,
        },
    ],
    columns         => [ # documentation of the data file columns
        {   'unit'          => 'T',   'label'         => 'B',
            'description'   => 'magnetic field perpendicular to nanotube',
        },
	{   'unit'          => 'V',   'label'         => 'Vbias',
            'description'   => "dc bias voltage",
        },
	{   'unit'          => 'A',   'label'         => 'Idc',
            'description'   => "measured dc current",
        },
	{   'unit'          => 'A',   'label'         => 'Iac,x',
            'description'   => "measured ac current, x component",
        },
	{   'unit'          => 'A',   'label'         => 'Iac,y',
            'description'   => "measured ac current, y component",
        },
    ],
    axes            => [ # possible axes for plotting, and their data columns
        {   'unit'          => 'T',   'label'         => 'B',
            'expression'    => '$C0',
            'description'   => 'magnetic field perpendicular to nanotube',
        },
	{   'unit'          => 'V',   'label'         => 'Vbias',
            'expression'    => '$C1',
            'description'   => 'dc bias voltage',
        },
	{   'unit'          => 'A',   'label'         => 'Idc',
            'expression'    => '$C2',
            'description'   => 'measured dc current',
        },
	{   'unit'          => 'I',   'label'         => 'Iac,x',
            'expression'    => '$C3',
            'description'   => 'measured ac current, x component',
        },
	{   'unit'          => 'I',   'label'         => 'Iac,y',
            'expression'    => '$C4',
            'description'   => 'measured ac current, y component',
        },
    ],
    plots           => { # plots that can be made using the axes above
        'currentdc'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,   'yaxis'         => 1,
            'cbaxis'        => 2,   'grid'          => 'xtics ytics',
        },
        'currentacx'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,   'yaxis'         => 1,
            'cbaxis'        => 3,   'grid'          => 'xtics ytics',
        },
    },
);

# correct the sign of the step sizes if required
unless (($Bstop-$Bstart)/$Bstep > 0) { $Bstep = -$Bstep; }
unless (($Vbiasstop-$Vbiasstart)/$Vbiasstep > 0) { $Vbiasstep = -$Vbiasstep; }
my $Bstepsign=$Bstep/abs($Bstep);
my $Vbiasstepsign=$Vbiasstep/abs($Vbiasstep);

## ENOUGH PREPARATION, NOW THE MEASUREMENT STARTS :) 

# go to start field
print "Ramping magnet to starting field... ";
$magnet->set_field($Bstart);
print " done!\n";

# here you could eg. check the temperature

# the outer measurement loop: magnetic field
for (my $B=$Bstart;$Bstepsign*$B<=$Bstepsign*$Bstop;$B+=$Bstep)	{

	$measurement->start_block();
	
	# set the field 
	$magnet->set_field($B);
	
	# the inner measurement loop: bias voltage
	for (my $Vbias=$Vbiasstart; 
		$Vbiasstepsign*$Vbias<=$Vbiasstepsign*$Vbiasstop;
		$Vbias+=$Vbiasstep) {

	     # set the bias voltage
	     $YokBias->set_voltage($Vbias/$Vbiasdivider);

	     # read dc signal from multimeter
             my $Vdc = $HP->get_value();
 
	     # read the ac signal from the lock-in
             my ($Vacx,$Vacy)=$SRS->get_xy();

             # we multiply with (-1)*$currentamp (inverting amplifier)
	     my $Idc = -$Vdc*$currentamp;
             my $Iacx=-$Vacx*$currentamp;
             my $Iacy=-$Vacy*$currentamp;

             # write the values into the data file
	     $measurement->log_line($B, $Vbias, $Idc, $Iacx, $Iacy);
	}
};

# all done
$measurement->finish_measurement();
print "End of Measurement!\n";
