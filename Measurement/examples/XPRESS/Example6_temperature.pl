
die "work in progress";

#-------- 0. Import Lab::Measurement -------

use Lab::Measurement;

#-------- 1. Initialize Instruments --------

my $dilfridge = Instrument(
    'OI_Triton',
    {
        connection_type => 'Socket'
    }
);

#-------- 2. Define the Sweeps -------------

my $temperature_sweep = Sweep(
    'Temperature',
    {
        mode       => 'step',
        instrument => $dilfridge,
        points     => [ 20e-3, 200e-3 ],    # [starting point, target] in K
	stepwidth  => 20e-3
    }
);

#-------- 3. Create a DataFile -------------

my $DataFile = DataFile('tempcurve.dat');

$DataFile->add_column('Temperature');
$DataFile->add_column('Data');

$DataFile->add_plot(
    {
        'x-axis' => 'Temperature',
        'y-axis' => 'Data'
    }
);

#-------- 4. Measurement Instructions -------

my $my_measurement = sub {

    my $sweep = shift;

    my $temperature    = $dilfridge->get_value();

    $sweep->LOG(
        {
            Temperature => $temperature,
            Data        => 0
        }
    );
};

#-------- 5. Put everything together -------

$DataFile->add_measurement($my_measurement);

$voltage_sweep->add_DataFile($DataFile);

$voltage_sweep->start();

1;

=pod

=encoding utf-8

=head1 Name

XPRESS for DUMMIES

=cut
