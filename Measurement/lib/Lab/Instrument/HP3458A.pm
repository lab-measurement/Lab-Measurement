#!/usr/bin/perl

package Lab::Instrument::HP3458A;
our $VERSION = '2.93';

use strict;
use Lab::Instrument;
use Lab::Instrument::Multimeter;


our @ISA = ("Lab::Instrument::Multimeter");

our %fields = (
	supported_connections => [ 'GPIB', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
	},

	device_settings => {
	},

);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	$self->write("END 1");
	return $self;
}




sub _configure_voltage_measurement{
    my $self=shift;
    my $range=shift; # in V, or "AUTO"
    my $tint=shift;  # in sec
    my $cmd="";

	# check range for positive numerical value or "AUTO"
	if($range !~ /^[0-9]*\.[0-9]*$/ && $range !~ /^[0-9]*[eE][+-]?[0-9]*$/ && $range ne "AUTO") {
		Lab::Exception::CorruptParameter->throw (
			error => "No valid rage address given to " . __PACKAGE__ . "::_configure_voltage_measurement()\n" . Lab::Exception::Base::Appendix(),
		);
	}

    if($range ne "AUTO") {
		if($range <= 0.1)    { $range=0.1 }
		elsif($range <= 1)   { $range=1 }
		elsif($range <= 10)  { $range=10 }
		elsif($range <= 100) { $range=100 }
		else                 { $range=1000 }
    }

    #die "configure_voltage_measurement not implemented for this instrument\n";

    if($range eq "AUTO") {
        $cmd="DCV AUTO";
    }
    else {
        $cmd=sprintf("DCV %.1f",$range);
    }
    $self->write($cmd); 

    if(defined $tint) {
        $cmd = sprintf("APER%f",$tint);
    }
}


sub get_voltage_dc {
    my $self=shift;
    return $self->query("DCV");
}

sub set_nplc {
    my $self=shift;
    my $n=shift;   
    $self->write("NPLC $n");
}

sub _selftest {
    my $self=shift;
    $self->write("TEST");
}

sub autocalibration {
    # Warning... this procedure takes 11 minutes!
    my $self=shift;
    $self->write("ACAL ALL");
}

sub reset {
    my $self=shift;
    $self->write("PRESET NORM");
}


sub _display_text {
    my $self=shift;
    my $text=shift;
    
    $self->write("DISP MSG,\"$text\"");
}

sub _display_on {
    my $self=shift;
    $self->write("DISP ON");
}

sub _display_off {
    my $self=shift;
    $self->write("DISP OFF");
}

sub _display_clear {
    my $self=shift;
    $self->write("DISP CLR");
}

sub beep {
    # It beeps!
    my $self=shift;
    $self->write("BEEP");
}

sub get_error {
    my $self=shift;
    chomp(my $err=$self->query("SYSTem:ERRor?"));
    my ($err_num,$err_msg)=split ",",$err;
    $err_msg=~s/\"//g;
    return ($err_num,$err_msg);
}

sub preset {
    # Sets HP3458A into predefined configurations
    # 0 Fast
    # 1 Norm
    # 2 DIG 
    my $self=shift;
    my $preset=shift;
    my $cmd=sprintf("PRESET %u",$preset);
    $self->write($cmd);
}

sub _id {
    my $self=shift;
    return $self->query('*IDN?');
}


sub _get_value {
    # Triggers one Measurement and Reads it
    my $self=shift;
    my $val=$self->query("TRIG SGL");
    chomp $val;
    return $val;
}


1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::HP3458A - Agilent 3458A Multimeter

=head1 SYNOPSIS

    use Lab::Instrument::HP3458A;
    
    my $dmm=new Lab::Instrument::HP3458A({
        gpib_board   => 0,
        gpib_address => 11,
    });
    print $dmm->read_voltage_dc();

=head1 DESCRIPTION

The Lab::Instrument::HP3458A class implements an interface to the Agilent / HP 
3458A digital multimeter. 

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head2 read_voltage_dc

    $datum=$hp->read_voltage_dc();

Make a dc voltage measurement.

=head2 display_on

    $hp->display_on();

Turn the front-panel display on.

=head2 display_off

    $hp->display_off();

Turn the front-panel display off.

=head2 display_text

    $hp->display_text($text);
    print $hp->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.

=head2 display_clear

    $hp->display_clear();

Clear the message displayed on the front panel.

=head2 beep

    $hp->beep();

Issue a single beep immediately.

=head2 get_error

    ($err_num,$err_msg)=$hp->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 set_nlpc

    $hp->set_nlcp($number);

Sets the integration time in power line cycles.

=head2 reset

    $hp->reset();

Reset the multimeter to its power-on configuration.

=head2 preset

    $hp->preset($config);

Choose one of several configuration presets (0: fast, 1: norm, 2: DIG).

=head2 selftest

    $hp->selftest();

Starts the internal self-test routine.

=head2 autocalibration

    $hp->autocalibration();

Starts the internal autocalibration. Warning... this procedure takes 11 minutes!


=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item * L<Lab::Instrument>

=item * L<Lab::Instrument::Multimeter>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2009-2011 David Kalok, Andreas K. Hüttel
            2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
