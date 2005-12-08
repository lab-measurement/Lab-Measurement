#!/usr/bin/perl
# a2ps --tabsize=4 --columns=1 --font-size=10 --pretty-print=perl --landscape -o code.ps charge-stability.pl

use strict;														# we'll write clean perl

use VISA::Instrument::HP34401A;									# we use these additional modules
use VISA::Instrument::KnickS252;
use VISA::Instrument::Yokogawa7651;
use Time::HiRes (qw/usleep/);									# for high resolution timing

my $left_gate=new VISA::Instrument::KnickS252({					# create objects of instrument classes
	GPIB_address	=> 15										# means: connect to instruments
});
my $right_gate=new VISA::Instrument::Yokogawa7651({
	GPIB_address	=> 100
});
my $dqd_cond=new VISA::Instrument::HP34401A({
	GPIB_address	=> 24
});

for (my $l_volt=-0.4;$l_volt-=0.0005;$l_volt>=-0.5) {			# Sweep left gate from -400mV to -500mV (-0.5mV/step)
	$left_gate->set_voltage($l_volt);							# Set left gate voltage
	for (my $r_volt=-0.75;$r_volt+=0.001;$r_volt=<-0.65) {		# Sweep right gate from -750mV to -650mV (1mV/step)
		$right_gate->set_voltage($r_volt);						# Set right gate voltage
		usleep(500);											# Wait for 500ms
		my $cond=$dqd_cond->read_voltage_dc(10);				# Read data from multimeter
		print "$l_volt\t$r_volt\t$cond\n";						# Log data
	}
	print "\n";													# Insert empty line to separate single traces
}
