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

# Skip modules with special dependencies

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
	'Wx::App' => [qw(Lab/Bus/DEBUG.pm Lab/Bus/DEBUG/HumanInstrument.pm)],
	'PDL' => ['Lab/Data/PDL.pm'],
	'Statistics::LineFit' => ['Lab/XPRESS/Data/XPRESS_dataset.pm'],
	'Statistics::Descriptive' => [qw(Lab/XPRESS/Sweep/Temperature.pm Lab/XPRESS/Sweep/Time.pm)],
	'Device::SerialPort' => [qw(Lab/Bus/RS232.pm Lab/Bus/MODBUS_RS232.pm Lab/Instrument/TemperatureControl/TLK43.pm)],
	'Math::Interpolate' => [qw(Lab/XPRESS/Data/XPRESS_dataset.pm)],
	'LinuxGpib' => [qw(Lab/Bus/LinuxGPIB.pm Lab/Connection/LinuxGPIB.pm)],
	'Lab::VISA' => [qw(VISA Lab/Bus/IsoBus.pm Lab/Connection/DEBUG.pm
	Lab/Connection/IsoBus.pm)],
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
	is(require $file, 1, "load $file");
}
