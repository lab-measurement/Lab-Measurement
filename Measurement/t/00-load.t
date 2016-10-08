#!perl

# Check that our perl modules compile without error.

use 5.010;
use strict;
use warnings;
use File::Find;
use Module::Load;
use Test::More;
use File::Spec::Functions 'abs2rel';

# Create file list

my @files;

sub installed {
    my $module = shift;
    eval {
        autoload $module;
        1;
    } or return;

    return 1;
}

File::Find::find(
    {
        wanted => sub { -f $_ && /\.pm$/ and push @files, $_ },
        no_chdir => 1
    },
    'lib'
);

@files = map { abs2rel( $_, 'lib' ) } @files;

# Skip modules with special dependencies.

sub skip_modules {
    my @to_be_skipped = @_;
    for my $skip (@to_be_skipped) {
        @files = grep {
            my $file = $_;
            $file =~ tr/\\/\//;
            index( $file, $skip ) == -1;
        } @files;
    }
}

diag("checking installed modules");

my $rs232_stuff = [
    'Lab/Bus/RS232.pm Lab/Bus/MODBUS_RS232.pm',
    'Lab/Instrument/TemperatureControl/TLK43.pm',
    'Lab/Bus/RS232.pm',
    'Lab/Bus/MODBUS_RS232.pm'
];

my %depencencies = (
    'PDL' => ['Lab/Data/PDL.pm'],

    'Statistics::LineFit' => ['Lab/XPRESS/Data/XPRESS_dataset.pm'],

    'Statistics::Descriptive' => [
        'Lab/XPRESS/Sweep/Temperature.pm', 'Lab/XPRESS/Sweep/Time.pm',
        'Lab/XPRESS/Sweep/Temperature.pm', 'Lab/XPRESS/Sweep/Time.pm'
    ],

    'Device::SerialPort' => $rs232_stuff,
    'threads'            => $rs232_stuff,
    'Thread::Semaphore'  => $rs232_stuff,

    'Math::Interpolate' => ['Lab/XPRESS/Data/XPRESS_dataset.pm'],

    'IPC::Run' => [
        'Lab/XPRESS/Xpression/PlotterGUI_bidirectional.pm',
        'Lab/XPRESS/Xpression/bidirectional_gnuplot_pipe.pm'
    ],

    'LinuxGpib' => ['LinuxGPIB'],

    'Lab::VISA' =>
        [ 'VISA', 'Lab/Bus/IsoBus.pm', 'Lab/Connection/IsoBus.pm' ],
);

for my $module ( keys %depencencies ) {
    if ( installed($module) ) {
        diag("using $module");
    }
    else {
        diag("not using $module");
        skip_modules( @{ $depencencies{$module} } );
    }
}

eval {
    load 'sys/ioctl.ph';
    diag("using sys/ioctl.ph");
    1;

} or do {
    diag("not using sys/ioctl.ph");
    skip_modules('Lab/Bus/USBtmc.pm');
};

plan tests => scalar @files;

for my $file (@files) {
    diag("trying to load $file ...");
    is( require $file, 1, "load $file" );
}
