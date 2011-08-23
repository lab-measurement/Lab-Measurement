#!/usr/bin/perl

use strict;
#use Lab::Instrument::KnickS252;
use Lab::Instrument::IPS12010new;
use Lab::Instrument::Yokogawa7651;
use Lab::Instrument::HP34401A;
use Lab::Instrument::TRMC2;
use Time::HiRes qw/sleep/;
use Time::HiRes qw/usleep/;
use Time::HiRes qw/tv_interval/;
use Time::HiRes qw/gettimeofday/;
use Lab::Measurement;

#################################################

my $start_sd=-1.000;
my $stop_sd=1.002;
my $step_sd=0.002;

my $gate_v=2.044;

my $gpib_sd=5;
my $type_sd="Lab::Instrument::Yokogawa7651";

my $gpib_hp=12;

my $amp=1e-8;    # Ithaco amplification
my $Vdiv=1e-3;

my $name_gate = "Backgate";

my $sample="Sample BA - Structure 22C";
my $title="1D Biassweep";
my $filename="B=2p5Tto6T_MC_T=100mK_Vg=2p044V";

#my $start_outer = $start_sd*1000;
#my $end_outer = $stop_sd*1000;

# Sweep rates for different temperature ranges
my $T_sweep_slow=0.005;         #K/min
my $T_sweep_medium=0.010;       #K/min
my $T_sweep_fast=0.020;         #K/min
my $T_sweep=$T_sweep_slow;      #K/min
my $T_sweep_rate_switch_slow=0.080; #K
my $T_sweep_rate_switch_medium=0.300;   #K

# Thermalization times for different temperature ranges
my $T_wait_sp_hot=120;          #sec
my $T_wait_sp_cold=900;                 #sec
my $T_wait_sp=$T_wait_sp_hot;       #sec
my $T_wait_sp_cold_switch=0.080;    #K

# Thermometer channel numbers
my $T_channel_sample=3;
my $T_channel_mc=5;

my $TRMC= new Lab::Instrument::TRMC2(0,0);

# initialize the temperature part

printf "Init TRMC2... ";
$TRMC->TRMC2init;
printf "done.\n";

$TRMC->TRMC2_Start_Sweep(0);            # dont sweep for now
$TRMC->TRMC2_Set_T(0.100);  # set temperature to 0.03mK ??? what is set here ???
$TRMC->TRMC2_Heater_Control_On(1);

my @allmeas=$TRMC->TRMC2_AllMEAS();     # read out all channels?
printf "ALLMEAS=@allmeas\n";
my $RT_now=0;
my $T_now=0;
my $startwait = 0;

my $B_sweep=30e-3;#T/min

my @B= linspace(2.5,6.0,350);#,0.2,0.8,1.0,1.1,1.5,1.7,2.0,2.5,3.0];

print "setting up Magnet...";
my $magnet=new Lab::Instrument::IPS12010new({
    'GPIB_board'    => 0,
    
    'GPIB_address'  => 28,
});
$magnet->{config}->{field_constant}=0.1190;
$magnet->{config}->{max_current}=50;
$magnet->{config}->{max_sweeprate}=0.0166;
$magnet->{config}->{can_reverse}=1;
$magnet->{config}->{can_use_negative_current}=1;
print " done!\n";

$magnet->_init_magnet();
$magnet->ips_set_communications_protocol(4);#5 digits
$magnet->ips_set_field_sweep_rate(sprintf("%.4f",$B_sweep));#<------Setting Sweep Rate
my $SweeprateT= $magnet->ips_read_parameter(9);
printf "Sweep rate:$SweeprateT T/min \n";

$magnet->ips_set_switch_heater(1); #-----------Switch Heater On-------------
my $b_now=$magnet->ips_read_parameter(7);
##-----------------Setting up Starting Field------------------
if (abs($b_now-$B[0])<1e-4){
    print "Starting Field ok!\n"
}else{
    print "Running to Starting field B $B[0]\t B now= $b_now...\n";
    $magnet->ips_set_target_field(sprintf("%.5f", $B[0]));
    $magnet->ips_set_activity(1);
    print "done!\n";
    #my $count=0;
    #my $count_max=int(abs($B[0]-$b_now)/$b_sampling_step+0.5);
    #for( $count,$count_max*1.2){
    my $stepsign=($B[-1]-$B[0])/abs($B[-1]-$B[0]);
    for(my $j=0; ($stepsign*$b_now)<=($stepsign*$B[-1]) ;$j++){
        $b_now=$magnet->ips_read_parameter(7);
        my $DeltaB=abs($b_now-$B[0]);
        printf "Bnow=$b_now\tB_set=$B[0]\tDeltaB=$DeltaB T\n";
        if ($DeltaB<2e-5){printf "exit waiting loop\n";last;}
        sleep(my $sampling_rate = 1.);
    };    
    print "Starting Field Reached B:", $magnet->ips_read_parameter(7), "T\n";
};

print "Starting Value B=", $magnet->ips_read_parameter (7)," reached!\n";

my $comment=<<COMMENT;
V_{SD}=$start_sd..$stop_sd mV an 3; Ithaco: Amplification $amp an 9, Rise Time 300 ms;
$name_gate = $gate_v V;
T = 24 mK; Spannungsteiler Vsd = 1000:1; Gatevorwiderstand = 10 MOhm
COMMENT

#################################################

unless (($stop_sd-$start_sd)/$step_sd > 0) {
    $step_sd = -$step_sd;
}

my $source_sd=new $type_sd({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gpib_sd,
    'gate_protect'  => 0,

    'gp_max_volt_per_second' => 10,
    'gp_max_volt_per_step' => 1,
    'gp_min_volt' => -10, 
    'gp_max_volt'  => 10,
});

my $hp=new Lab::Instrument::HP34401A(0,$gpib_hp);

my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => $filename,
    description     => $comment,

    live_plot       => 'Current 2D',
    live_refresh    => '200',

    constants       => [
        {
            'name'          => 'AMP',
            'value'         => $amp,
        },
      {
            'name'          => 'OFFSET',
            #'value'         => $gateoffset,
        },
    ],
    columns         => [
        {
            'unit'          => 'T',
            'label'         => 'Magnetic Field',
            'description'   => 'External magnetic field',
        },
        {
            'unit'          => 'V',
            'label'         => 'Source-drain voltage',
            'description'   => 'Applied via 1000:1 divider',
        },
        {
            'unit'          => 'V',
            'label'         => 'Amplifier output',
            'description'   => "Voltage output by current amplifier set to $amp.",
        }
    ],
    axes            => [
        {
            'unit'          => 'T',
            'expression'    => '$C0',
            'label'         => 'magnetic field',
            'min'           => $B[0],
            'max'           => $B[-1],
            'description'   => 'Applied via magnet coil.',
        },
        {
            'unit'          => 'V',
            'expression'    => '$C1',
            'label'         => 'source-drain voltage',
            'min'           => ($start_sd < $stop_sd) ? $start_sd : $stop_sd,
            'max'           => ($start_sd < $stop_sd) ? $stop_sd : $start_sd,
            'description'   => 'Applied via 1000:1 divider',
        },
        {
            'unit'          => 'A',
            'expression'    => "\$C2*AMP",
            'label'         => 'current',
            'description'   => 'Current through dot',
#            'min'           =>  0,
        },
        
    ],
    plots           => {
        'Current 2D'    => {
            'type'          => 'pm3d',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'cbaxis'         => 2,
            'grid'          => 'xtics ytics',
        },
    },
);

my $stepsign_sd=$step_sd/abs($step_sd);

$measurement->start_block();
$measurement->log_line("# BField (T)","TResistance","Temperature","Vbias_raw","Current_raw","Vbias","Current");

for my $b_set(@B)
    {

    $measurement->start_block();

    my $b_now=$magnet->ips_read_parameter(7);
    ##-----------------Setting up Starting Field------------------
    if (abs($b_now-$b_set)<1e-4){
        print "Starting Field ok!\n"
    }else{
        print "Running to set field B $b_set\t B now= $b_now...\n";
        $magnet->ips_set_target_field(sprintf("%.5f", $b_set));
        $magnet->ips_set_activity(1);
        print "done!\n";
        #my $count=0;
        #my $count_max=int(abs($B[0]-$b_now)/$b_sampling_step+0.5);
        #for( $count,$count_max*1.2){
        my $stepsign=($B[-1]-$B[0])/abs($B[-1]-$B[0]);
        for(my $j=0; ($stepsign*$b_now)<=($stepsign*$B[-1]) ;$j++){
            $b_now=$magnet->ips_read_parameter(7);
            my $DeltaB=abs($b_now-$b_set);
            printf "Bnow=$b_now\tB_set=$b_set\tDeltaB=$DeltaB T\n";
            if ($DeltaB<2e-5){printf "exit waiting loop\n";last;}
            sleep(my $sampling_rate = 1.);
        };    
    print "Set Field Reached B:", $magnet->ips_read_parameter(7), "T\n";
        };

    print "Starting Measurement B=", $magnet->ips_read_parameter (7),"\n";
    
    my $t_start_wait=[gettimeofday()];
  
  #if ($T_set<=$T_wait_sp_cold_switch){ $T_wait_sp=$T_wait_sp_cold;printf "Using cold waiting time $T_wait_sp\n"; }
    #else{ $T_wait_sp=$T_wait_sp_hot; printf "Using hot waiting time $T_wait_sp\n"; };
    
  while(1){
    my $t_T=tv_interval($t_start_wait);
    if ($t_T>=$T_wait_sp) { last }; # end loop after waiting correct time
    if ($startwait == 0) {$startwait = 1; last};
    
    printf ("t_T=%d sec\tt_wait=%d sec\n",$t_T,$T_wait_sp); # debug output
    sleep(1);
  };
    
    $b_now = $magnet->ips_read_parameter(7);
    ($RT_now,$T_now)=$TRMC->TRMC2_get_RT($T_channel_sample);
    print("RT=$RT_now\tT=$T_now\n");
  for (my $volt_sd=$start_sd;$stepsign_sd*$volt_sd<=$stepsign_sd*$stop_sd;$volt_sd+=$step_sd) {

    $source_sd->set_voltage($volt_sd);
#    usleep(0.05E6);

    my $meas=$hp->read_voltage_dc(10,0.0001);

    my $realinner=$volt_sd;


    $measurement->log_line($b_now,$RT_now,$T_now,$realinner,$meas,$realinner*$Vdiv,$meas*$amp);
  }
}

my $meta=$measurement->finish_measurement();


sub linspace{
    my $min=shift;
    my $max=shift;
    my $points=shift;
    my @L=(0..$points);
    my @L_return;
    foreach (@L){
        my $tmp=($max-$min)/$points*$_+$min;
        push(@L_return,$tmp);
    }
    return @L_return;
}