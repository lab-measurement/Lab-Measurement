#!/usr/bin/perl

# Transportmessung mit Lock-In

#$Id$

use strict;
use Lab::Instrument::KnickS252;
use Lab::Instrument::HP34401A;
use Lab::Instrument::Yokogawa7651;
use Time::HiRes qw/usleep/;
use Lab::Measurement;

################################

my $divider_dc    = 1000;
my $ithaco_amp    = 1e-9;    # Ithaco amplification
my $lock_in_sensitivity = 100e-3;

my $v_sd_ac       = 20e-6;
my $v_sd_dc       = 0e-3/$divider_dc;

my $gate_0_gpib   = 1;
my $gate_0_type   = 'Yokogawa7651';
my $gate_0_name   = 'Gate 01';  
my $gate_0_start  = -0.390;
my $gate_0_end    = -0.410;
my $gate_0_step   = -2e-3;

my $gate_1_gpib   = 4;
my $gate_1_type   = 'Yokogawa7651';
my $gate_1_name   = 'Gate hf4';
my $gate_1_start  = -0.260;
my $gate_1_end    = -0.130;
my $gate_1_step   = +1e-3;

my $gate_2_gpib   = 9;
my $gate_2_type   = 'Yokogawa7651';
my $gate_2_name   = 'Gate hf3';  
my $gate_2_start  = -0.270;
my $gate_2_end    = -0.100;
my $gate_2_step   = +1e-3;

my $hp_gpib       = 24;
my $hp_range      = 10;
my $hp_resolution = 0.00001;

my $R_Kontakt     = 1773;

my $filename_base = 'triple_lade_transport';

my $sample        = "S5c (81059)";
my $title         = "Alle drei Quantenpunkte";
my $comment       = <<COMMENT;
Differentielle Leitfähigkeit von 12 nach 10; V_{SD,DC}=$v_sd_dc V; Lüftung an; Ca. 25mK.
Lock-In: Sensitivity $lock_in_sensitivity V, V_{SD,AC}=$v_sd_ac V bei 33Hz, 300ms, Normal, Bandpaß 50.
Ithaco: Amplification $ithaco_amp, Supression 10e-10 off, Rise Time 0.3ms.
G11=-0.385 (Manus1); G15=-0.410 (Manus2); G06=-0.455 (Manus3); Ghf1=-0.110 (Manus04); Ghf2=-0.120 (Manus05);
G03=-0.450 (Yoko02); G13=-0.606 (Knick14); G09=-0.606 (Yoko10); 14 offen; 02,04 auf GND
Fahre aussen Ghf4 (Yoko04); innen Ghf3 (Yoko09)
COMMENT

################################

unless (($gate_0_end-$gate_0_start)/$gate_0_step > 0) {
    warn "Loop on gate 0 will not work: start=$gate_0_start, end=$gate_0_end, step=$gate_0_step.\n";
    exit;
}

unless (($gate_1_end-$gate_1_start)/$gate_1_step > 0) {
    warn "Loop on gate 1 will not work: start=$gate_1_start, end=$gate_1_end, step=$gate_1_step.\n";
    exit;
}

unless (($gate_2_end-$gate_2_start)/$gate_2_step > 0) {
    warn "Loop on gate 2 will not work: start=$gate_2_start, end=$gate_2_end, step=$gate_2_step.\n";
    exit;
}

my $g0type="Lab::Instrument::$gate_0_type";
my $g1type="Lab::Instrument::$gate_1_type";
my $g2type="Lab::Instrument::$gate_2_type";

my $gate0=new $g1type({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_0_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});
    
my $gate1=new $g1type({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_1_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});
    
my $gate2=new $g2type({
    'GPIB_board'    => 0,
    'GPIB_address'  => $gate_2_gpib,
    'gate_protect'  => 1,

    'gp_max_volt_per_second' => 0.002,
    'gp_max_step_per_second' => 3,
    'gp_max_step_per_step'   => 0.001,
});

my $hp=new Lab::Instrument::HP34401A(0,$hp_gpib);

my $gate_0_stepsign=$gate_0_step/abs($gate_0_step);

for (my $g0=$gate_0_start;$gate_0_stepsign*$g0<=$gate_0_stepsign*$gate_0_end;$g0+=$gate_0_step) {

    $gate0->set_voltage($g0);

    my $measurement=new Lab::Measurement(
        sample          => $sample,
        title           => $title,
        filename_base   => $filename_base,
        description     => $comment."G01=$g0 (Yoko01)\n",

        live_plot       => 'Differential Conductance',
        live_refresh    => 120,
    #    live_latest     => 8,

        constants       => [
            {
                'name'          => 'G0',
                'value'         => '7.748091733e-5',
            },
            {
                'name'          => 'RKontakt',
                'value'         => $R_Kontakt,
            },
            {
                'name'          => 'AMP',
                'value'         => $ithaco_amp,
            },
            {
                'name'          => 'divider',
                'value'         => $divider_dc,
            },
            {
                'name'          => 'V_AC',
                'value'         => $v_sd_ac,
            },
            {
                'name'          => 'SENS',
                'value'         => $lock_in_sensitivity,
            },
        ],
        columns         => [
            {
                'unit'          => 'V',
                'label'         => "Voltage $gate_1_name",
                'description'   => "Set voltage on source $gate_1_type$gate_1_gpib connected to $gate_1_name.",
            },
            {
                'unit'          => 'V',
                'label'         => "Voltage $gate_2_name",
                'description'   => "Set voltage on source $gate_2_type$gate_2_gpib connected to $gate_2_name.",
            },
            {
                'unit'          => 'V',
                'label'         => "Lock-In output",
                'description'   => 'Differential current (Lock-In output)',
            }
        ],
        axes            => [
            {
                'unit'          => 'V',
                'expression'    => '$C0',
                'label'         => "Voltage $gate_1_name",
                'min'           => ($gate_1_start < $gate_1_end) ? $gate_1_start : $gate_1_end,
                'max'           => ($gate_1_start < $gate_1_end) ? $gate_1_end : $gate_1_start,
                'description'   => "Voltage applied to $gate_1_name.",
            },
            {
                'unit'          => 'V',
                'expression'    => '$C1',
                'label'         => "Voltage $gate_2_name",
                'min'           => ($gate_2_start < $gate_2_end) ? $gate_2_start : $gate_2_end,
                'max'           => ($gate_2_start < $gate_2_end) ? $gate_2_end : $gate_2_start,
                'description'   => "Voltage applied to $gate_2_name.",
            },
            {
                'unit'          => 'A',
                'expression'    => "((\$C2/10)*SENS*AMP)",
                'label'         => 'Differential current',
                'description'   => 'Differential current',
            },
            {
                'unit'          => '2e^2/h',
                'expression'    => "(\$A2/V_AC)/G0",
                'label'         => 'Differential conductance',
                'description'   => 'Differential conductance',
            },
        ],
        plots           => {
            'Differential Conductance'    => {
                'type'          => 'line',
                'xaxis'         => 1,
                'yaxis'         => 3,
                'grid'          => 'xtics ytics',
    #            'logscale'      => 'y',
            },
            'Ladediagramm'=> {
                'type'          => 'pm3d',
                'xaxis'         => 1,
                'yaxis'         => 0,
                'cbaxis'        => 3,
                'grid'          => 'xtics ytics',
            },
        },
    );

    my $gate_1_stepsign=$gate_1_step/abs($gate_1_step);
    my $gate_2_stepsign=$gate_2_step/abs($gate_2_step);

    for (my $g1=$gate_1_start;$gate_1_stepsign*$g1<=$gate_1_stepsign*$gate_1_end;$g1+=$gate_1_step) {
        $measurement->start_block("$gate_0_name = $g0 V; $gate_1_name = $g1 V");
        print "Started block $gate_0_name = $g0 V; $gate_1_name = $g1 V\n";
        $gate1->set_voltage($g1);
        sleep(10);
        for (my $g2=$gate_2_start;$gate_2_stepsign*$g2<=$gate_2_stepsign*$gate_2_end;$g2+=$gate_2_step) {
            $gate2->set_voltage($g2);
            my $meas=$hp->read_voltage_dc($hp_range,$hp_resolution);
            $measurement->log_line($g1,$g2,$meas);
        }
    }
    my $meta=$measurement->finish_measurement();

}
