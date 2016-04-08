#!perl
use 5.010;
use strict;
use warnings ;#FATAL => 'all';
use Test::More tests => 8;

BEGIN {
	my @modules = qw/Lab::Generic Lab::Measurement Lab::Instrument
	Lab::Instrument::SR830 Lab::Instrument::Agilent34410A
	Lab::Instrument::Yokogawa7651 Lab::Instrument::OI_ITC503
	Lab::Instrument::TemperatureControl::TLK43/; 
	for my $module (@modules) {
		use_ok($module) || print "Bail out!\n";
	}
}

