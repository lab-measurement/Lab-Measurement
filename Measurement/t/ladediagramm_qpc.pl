#!/usr/bin/perl

# QPC-Messung mit Lock-In

#$Id: ladediagramm.pl 438 2006-05-29 10:41:09Z schroeer $

use strict;
use Lab::Measurement::Ladediagramm;

################################

my $constants     = [
    'voltage_current_factor' => 1e-9,    # $ithaco_amp
    'lock_in_sensitivity'    => 5e-3,    # $lock_in_sensitivity
    'modulation_voltage'     => 0.66e-3, # $v_gate_ac
    'modulation_divider'     => 1,       #
    'bias_divider'           => 1000,    # $divider_dc
    'contact_resistance'     => 1773,    # $R_Kontakt
];

#kann eventuell automatisch gewonnen werden,
#wenn messprogramm beim start alle quellen abfragt
my $bias_voltage = -300e-3/$divider_dc;

#enthält komplette liste
#kann ausgelagert werden
my %quellen = (
    'hf3' = {
        'name'       = 'gate hf3',
        'instrument' = {
            'type'          => 'Yokogawa7651',
            'GPIB_board'    => 0,
            'GPIB_address'  => 9,

            'gate_protect'  => 1,
            'gp_max_volt_per_second' => 0.002,
            'gp_max_step_per_second' => 3,
            'gp_max_step_per_step'   => 0.001,
        },
    },
    'hf4' = {
        'name'       = 'gate hf4';
        'instrument' = {
            'type'          => 'Yokogawa7651',
            'GPIB_address'  => 4,
    
            'gate_protect'  => 1,
            'gp_max_volt_per_second' => 0.002,
            'gp_max_step_per_second' => 3,
            'gp_max_step_per_step'   => 0.001,
        },
    },
    'bias' = {
        'name'       = 'bias';
        'instrument' = {
            'type'          => 'KnickS252',
            'GPIB_address'  => 15,
    
            'gate_protect'  => 1,
            'gp_max_volt_per_second' => 0.02,
            'gp_max_step_per_second' => 3,
            'gp_max_step_per_step'   => 0.01,
        },
    },
);

my @sweeps=(
    {
        'quelle' => 'hf3',
        'start'  => -0.250,
        'end'    => -0.150,
        'step'   => +5e-4,
    },
    {
        'quelle' => 'hf4',
        'start'  => -0.350,
        'end'    => -0.250,
        'step'   => +5e-4,
    },
};

my $multimeter_1 = {
    'GPIB_address' = 24,
    'range'        = 10,
    'resolution'   = 0.001,
};

my $multimeter_2 = {
    'GPIB_address' = 22,
    'range'        = 10,
    'resolution'   = 0.001,
};

my $filename_base = 'rauscheck_mit_bias';
my $sample        = "S5c (81059)";
my $title         = "Tripeldot, gemessen mit QPC links unten";
my $comment       = <<COMMENT;
Rauscheck mit anderen Einstellungen und Bias über Quantenpunkten
Transconductance von 12 nach 14; Auf Gate hf3 gelockt mit ca. $v_gate_ac V bei 33Hz. V_{SD,DC}=$v_sd_dc V; Ca. 25mK.
Lock-In: Sensitivity $lock_in_sensitivity V, 0.3s, Normal, Bandpaß Q=50.
Ithaco: Amplification $ithaco_amp, Supression 10e-10 off, Rise Time 0.3ms.
G11=-0.385 (Manus1); G15=-0.410 (Manus2); G06=-0.455 (Manus3); Ghf1=-0.125 (Manus04); Ghf2=-0.125 (Manus05);
G01=-0.394 (Yoko01); G03=-0.450 (Yoko02); G13=-0.604 (Knick14); G09=-0.604 (Yoko10); 10,02,04 auf GND
Fahre aussen Ghf3 (Yoko09); innen Ghf4 (Yoko04);
COMMENT


################################

