#!perl

# Check that our perl modules compile without error.

use 5.010;
use strict;
use warnings;
use File::Find;
use Test::More;
# Create file list

my @files;

sub installed {
	my $module = shift;
	return eval "use $module; 1";
}

File::Find::find({
	wanted => sub {-f $_ && /\.pm$/ and push @files, $_},
	no_chdir => 1
		  }, 'lib');

s/^lib.// for @files;

# Skip modules with special dependencies.

sub skip_modules {
	for my $skip(@_) {
		@files = grep {
			tr/\\/\//;
			index($_, $skip) == -1;
		} @files;
	}
}

diag("checking installed modules");

my %depencencies = (
	'PDL' => ['Lab/Data/PDL.pm'],
	
	'Statistics::LineFit' => ['Lab/XPRESS/Data/XPRESS_dataset.pm'],
	
	'Statistics::Descriptive' => ['Lab/XPRESS/Sweep/Temperature.pm',
				      'Lab/XPRESS/Sweep/Time.pm',
				      'Lab/XPRESS/Sweep/Temperature.pm',
				      'Lab/XPRESS/Sweep/Time.pm'],
	
	'Device::SerialPort' => ['Lab/Bus/RS232.pm Lab/Bus/MODBUS_RS232.pm',
				 'Lab/Instrument/TemperatureControl/TLK43.pm',
				 'Lab/Bus/RS232.pm', 'Lab/Bus/MODBUS_RS232.pm'
	],
	
	'Math::Interpolate' => ['Lab/XPRESS/Data/XPRESS_dataset.pm'],
	
	'IPC::Run' => ['Lab/XPRESS/Xpression/PlotterGUI_bidirectional.pm', 
		       'Lab/XPRESS/Xpression/bidirectional_gnuplot_pipe.pm'],
	
	'LinuxGpib' => ['Lab/Bus/LinuxGPIB.pm', 'Lab/Connection/LinuxGPIB.pm'],
	
	'Lab::VISA' => ['VISA', 'Lab/Bus/IsoBus.pm', 'Lab/Connection/IsoBus.pm'],
    );

for my $module (keys %depencencies) {
	if (installed($module)) {
		diag("using $module");
	}
	else {
		diag("not using $module");
		skip_modules(@{$depencencies{$module}});
	}
}


# FIXME! these do not compile
skip_modules('Lab/Measurement/Ladediagramm.pm',
	      'Lab/Instrument/KnickS252.pm');

if (! eval "require 'sys/ioctl.ph'; 1") {
	skip_modules('Lab/Bus/USBtmc.pm');
}

plan tests => scalar @files;

for my $file (@files) {
	diag ("trying to load $file ...");
	is(require $file, 1, "load $file");
}
