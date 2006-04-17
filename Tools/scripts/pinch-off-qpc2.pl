#!/usr/bin/perl
#$Id$

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $start_voltage=-0.6;
my $end_voltage=0;
my $step=5e-4;

my $knick_gpib=14;
my $hp_gpib=24;

my $v_sd=780e-3/1563;
my $amp=1e-7;    # Ithaco amplification

my $U_Kontakt=2.10;

my $sample="S5a-III (81059)";
my $title="QPC rechts unten";
my $comment=<<COMMENT;
Abgekuehlt mit +150mV.
Strom von 8 nach 1, Ithaco amp $amp, supr 10e-10, rise 0.3ms, V_{SD}=$v_sd V.
Gates 7 und 9.
Hi und Lo der Kabel aufgetrennt; Tuer zu, Deckel zu, Licht aus; nur Rotary, ca. 85mK.
COMMENT

################################

unless (($end_voltage-$start_voltage)/$step > 0) {
    warn "This will not work: start=$start_voltage, end=$end_voltage, step=$step.\n";
    exit;
}

my $knick=new Lab::Instrument::KnickS252({
    'GPIB_board'    => 0,
    'GPIB_address'  => $knick_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
});

my $hp=new Lab::Instrument::HP34401A({
    'GPIB_address'  => $hp_gpib,
});


my $measurement=new Lab::Measurement(
    sample          => $sample,
    title           => $title,
    filename_base   => 'qpc_pinch_off',
    description     => $comment,

    live_plot       => 'QPC current',
    
	constants		=> [
		{
			'name'			=> 'G0',
			'value'			=> '7.748091733e-5',
		},
		{
			'name'			=> 'UKontakt',
			'value'			=> $U_Kontakt,
		},
		{
			'name'			=> 'V_SD',
			'value'			=> $v_sd,
		},
		{
			'name'			=> 'AMP',
			'value'			=> $amp,
		},
	],
	columns         => [
        {
            'unit'          => 'V',
            'label'         => 'Gate voltage',
            'description'   => 'Applied to gates via low path filter.',
        },
        {
            'unit'          => 'V',
            'label'         => 'Amplifier output',
            'description'   => "Voltage output by current amplifier set to $amp.",
        }
    ],
    axes            => [
        {
            'unit'          => 'V',
            'expression'    => '$C0',
            'label'         => 'Gate voltage',
            'min'           => ($start_voltage < $end_voltage) ? $start_voltage : $end_voltage,
            'max'           => ($start_voltage < $end_voltage) ? $end_voltage : $start_voltage,
            'description'   => 'Applied to gates via low path filter.',
        },
        {
            'unit'          => 'A',
            'expression'    => "abs(\$C1)*AMP",
            'label'         => 'QPC current',
            'description'   => 'Current through QPC',
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(\$A1/V_SD)/G0)",
            'label'         => "Total conductance",
        },
        {
            'unit'          => '2e^2/h',
            'expression'    => "(1/(1/abs(\$C1)-1/UKontakt)) * (AMP/(V_SD*G0))",
            'label'         => "QPC conductance",
            'min'           => -0.1,
            'max'           => 5
        },
        
    ],
    plots           => {
        'QPC current'    => {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 1,
            'grid'          => 'xtics ytics',
        },
        'QPC conductance'=> {
            'type'          => 'line',
            'xaxis'         => 0,
            'yaxis'         => 3,
            'grid'          => 'ytics',
        }
    },
);

$measurement->start_block();

my $stepsign=$step/abs($step);
for (my $volt=$start_voltage;$stepsign*$volt<=$stepsign*$end_voltage;$volt+=$step) {
    $knick->set_voltage($volt);
    usleep(500000);
    my $meas=$hp->read_voltage_dc(10,0.0001);
    $measurement->log_line($volt,$meas);
}

my $meta=$measurement->finish_measurement();

my $plotter=new Lab::Data::Plotter($meta);

$plotter->plot('QPC conductance');

my $a=<stdin>;

