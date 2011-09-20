#!/usr/bin/perl -w

use strict;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::IPS12010;
use Lab::Instrument::HP34401A;
use Lab::Instrument::SR830;
use Lab::Measurement;


##############################

#---gate--- value in V
my $Vgate=-3.74;		# V

#---bias--- values in V, after divider
my $Vbiasstart = -0.0036;	# V
my $Vbiasstop = 0.0036;		# V
my $Vbiasstep = 0.00002;	# V

#---B-field--- Tesla
my $Bstart=0.1;			# T
my $Bstop=0;			# T
my $Bstep=0.01;			# T

##############################


# measurement settings and constants

my $Bsweep = 0.05*60;		# T/sec

my $Vgateprotect = 1;		# 0 off, 1 on
my $Vgatemax = 31;		# Volt

my $Vbiasdivider = 0.01;	# <1, factor of voltage divider
my $Vbiasprotect = 1;
my $Vbiasmax = 0.010;	        # V (after divider)

my $currentamp = 1e-9;		# A/V
my $currenttc = 0.03;		# rise time Ithaco in s

my $lockinsettings="integrate 100ms, freq 117.25Hz, sensit. 10mV";

my $temperature = 280;		# Temperatur in milli-Kelvin!
my $sample = "crazytube";

my @starttime = localtime(time);
my $startstring=sprintf("%04u-%02u-%02u_%02u-%02u-%02u",$starttime[5]+1900,$starttime[4]+1,$starttime[3],$starttime[2],$starttime[1],$starttime[0]);


# all gpib addresses
my $gpib_hp = 12;		# dc voltage output Ithaco
my $gpib_srs = 8;		# ac voltage output Ithaco
my $gpib_yoko_Vgate = 13;
my $gpib_yoko_Vbias = 3;	
my $gpib_magnet = 24;

# title and filename
my $title = "Bias versus magnetic field";
my $filename = $startstring."_biasfield";



####################################################################


print "Inititalizing sources and measurement instruments ...";

# gate voltage
my $YokGate=new Lab::Instrument::Yokogawa7651({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'    => 0,
    'gpib_address'  => $gpib_yoko_Vgate,
    'gate_protect'  => $gateprotect,
    'gp_max_volt_per_second' => 0.05,
    'gp_max_step_per_second' => 10,
    'gp_max_volt_per_step' => 0.005,
    'gp_min_volt' => -$Vgatemax,
    'gp_max_volt'  => $Vgatemax,
});

# bias voltage
my $YokBias=new Lab::Instrument::Yokogawa7651({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'    => 0,
    'gpib_address'  => $gpib_yoko_Vbias,
    'gate_protect'  => $Vbiasprotect,
    'gp_max_volt_per_second' => 0.05/$Vbiasdivider,
    'gp_max_step_per_second' => 10,
    'gp_max_volt_per_step' => 0.005/$Vbiasdivider,
    'gp_min_volt' => - $Vbiasmax/$Vbiasdivider, 	
    'gp_max_volt'  =>  $Vbiasmax/$Vbiasdivider,
    'fast_set' => 1,
});

# ac measurement         
my $SRS = new Lab::Instrument::SR830({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'    => 0,
    'gpib_address'  => $gpib_srs,
});
	  
# dc measurement
my $HP = new Lab::Instrument::HP34401A({
    'connection_type'=> 'LinuxGPIB',
    'gpib_board'    => 0,
    'gpib_address'  => $gpib_hp,
});

print " done.\n";


print "Setting up magnet...";

my $magnet=new Lab::Instrument::IPS12010({
    'connection_type' => 'DEBUG';
    'gpib_board'    => 0,    
    'gpib_address'  => $gpib_magnet,
});

print " done!\n";


my $cur_sweeprate=$magnet->get_sweeprate()*60;
printf "Current sweep rate: $cur_sweeprate T/min\n";
my $cur_B=$magnet->get_field();
printf "Current field     : $cur_B T\n";

##-----------------Setting up Starting Field------------------

print "Ramping magnet to starting field... ";
$magnet->set_field($B_start);
print " done!\n";



###################################################################################

my $comment=<<COMMENT;
Bias sweeps versus magnetic field
Constant gate voltage: $Vgate V
B from $Bstart to $Bstop step size $Bstep
Bias voltage from $Vbiasstart to $Vbiasstop step size $Vbiasstep
Temperature: $temperature mK;

Gate source -> gate
Bias source -> addbox with voltage divider $biasdivider
Lock-in ac source -> addbox with voltage divider 0.0001
Addbox -> Source
Drain -> Ithaco, amplification $currentamp A/V, rise time $currenttc s
Ithaco -> HP multimeter
Ithaco -> SRS lock-in, settings $lockinsettings
COMMENT

####################################################################################



my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => $filename,
    description     => $comment,

    live_plot       => 'currentacx',
    live_refresh    => '200',

constants       => [
        {
            'name'          => 'currentamp',
            'value'         => $currentamp,
        },
    ],
    columns         => [
        {
            'unit'          => 'T',
            'label'         => 'B',
            'description'   => 'magnetic field perpendicular to nanotube',
        },
		{
            'unit'          => 'V',
            'label'         => 'Vbias',
            'description'   => "dc bias voltage",
        },
	{
	    'unit'          => 'A',
            'label'         => 'Idc',
            'description'   => "measured dc current",
        },
	{
	    'unit'          => 'A',
            'label'         => 'Iac,x',
            'description'   => "measured ac current, x component",
        },
	{
	    'unit'          => 'A',
            'label'         => 'Iac,y',
            'description'   => "measured ac current, y component",
        },
	{
	    'unit'          => 'A',
            'label'         => 'Iac,r',
            'description'   => "measured ac current, r value",
        },
	{
            'unit'          => 'sec',
            'label'         => 't',
            'description'   => "time",
        },
    ],
    axes            => [
        {
            'unit'          => 'T',
            'expression'    => '$C0',
            'label'         => 'B',
            'description'   => 'magnetic field perpendicular to nanotube',
        },
		{
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => 'Vbias',
            'description'   => 'dc bias voltage',
        },
	{
	    'unit'          => 'A',
            'expression'    => '$C2',
            'label'         => 'Idc',
            'description'   => 'measured dc current',
        },
	{
	    'unit'          => 'I',
            'expression'    => '$C3',
            'label'         => 'Iac,x',
            'description'   => 'measured ac current, x component',
        },
	{
	    'unit'          => 'I',
            'expression'    => '$C4',
            'label'         => 'Iac,y',
            'description'   => 'measured ac current, y component',
        },
	{
	    'unit'          => 'I',
            'expression'    => '$C5',
            'label'         => 'Iac,r',
            'description'   => 'measured ac current, r value',
        },
	{
            'unit'          => 'sec',
	    'expression'    => '$C6',
            'label'         => 't',
            'description'   => 'timestamp (seconds)',
        },
    ],
    plots           => {
        'currentdc'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'        => 2,
            'grid'          => 'xtics ytics',
        },
        'currentacx'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'        => 3,
            'grid'          => 'xtics ytics',
        },
        'currentacr'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'        => 5,
            'grid'          => 'xtics ytics',
        },
    },
);

###############################################################################

 

# now fix the signs of the step sizes if required

unless (($Bstop-$Bstart)/$Bstep > 0) {
    $Bstep = -$Bstep;
}
my $Bstepsign=$Bstep/abs($Bstep);

unless (($Vbiasstop-$Vbiasstart)/$Vbiasstep > 0) {
    $Vbiasstep = -$Vbiasstep;
}
my $Vbiasstepsign=$Vbiasstep/abs($Vbiasstep);



# set the gate voltage for the whole measurement

my $Vgatereal=$YokGate->set_voltage($Vgate);



# now comes the measurement main loop

for (my $B=$Bstart;$Bstepsign*$B<=$Bstepsign*$Bstop;$B+=$Bstep)	{

	$measurement->start_block();	

	$magnet->set_field($B);
	
	for (my $Vbias=$Vbiasstart; 
		$Vbiasstepsign*$Vbias<=$Vbiasstepsign*$Vbiasstop;
		$Vbias+=$Vbiasstep) {

	     my $Vbiasreal = ($YokBias->set_voltage($Vbias/$biasdivider))*$biasdivider;
		
	     my $t = gettimeofday();

	     # read dc signal from hp multimeter
             my $Vdc = $hp -> read_value();
	     chomp $Vdc;
 
	     # we multiply with (-1)*$currentamp, it's an inverting amplifier
	     my $Idc = -$Vdc*$currentamp;

	     # read the ac signal from the lock-in
             my ($Vacx,$Vacy)=$liIAC->read_xy();
	     my $Vacr=sqrt($Vacx*$Vacx+$Vacy*$Vacy);

             # we multiply with (-1)*$currentamp, it's an inverting amplifier
	     # (except for r, which has to be positive of course)
             my $Iacx=-$Vacx*$currentamp;
             my $Iacy=-$Vacy*$currentamp;
             my $Iacr=$Vacr*$currentamp;

	    $measurement->log_line($B, $Vbias, $Idc, $Iacx, $Iacy, $Iacr, $t);
	}
};
	


# all done

$measurement->finish_measurement();

printf "End of Measurement!\n";



1;

=pod

=encoding utf-8

=head1 biasfield.pl

Script to record Idc(B,Vbias) and the lock-in output Iac(B,Vbias) in a 
Coulomb blockade measurement.

=head2 Measurement setup

=head2 Script: configuration section

=head2 Script: metadata section

=head2 Script: actual measurement loop

=head2 Author / Copyright

  (c) Daniel Schmid, Markus Gaass, David Kalok, Andreas K. Hüttel 2011

=cut
