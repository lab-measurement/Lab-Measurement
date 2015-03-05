package Lab::Instrument::RSSMB100A;
our $VERSION = '3.40';

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

# inherit the generic code
our @ISA = ("Lab::Instrument");

our %fields = (
	supported_connections => [ 'GPIB', 'TCPraw' ],
	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
	},
	# default device settings
	device_settings => {
	},
);

# [...]

sub set_power {
	my $self=shift;
	my ($power) = $self->_check_args( \@_, ['value'] );
	$self->write("POWer:LEVel $power DBM");
}

sub get_power {
	my $self = shift;
	return $self->query("POWer:LEVel?");
}

sub set_pulselength {
	my $self = shift;
	my ($length) = $self->_check_args( \@_, ['value'] );
	$self->write("PULM:WIDT $length s");
}

sub get_pulselength {
	my $self = shift;
	my $length = $self->query("PULM:WIDT?");
	return $length;
}

# [...]

sub power_on {
    my $self=shift;
    $self->write('OUTP:STATe ON');
}

sub power_off {
    my $self=shift;
    $self->write('OUTP:STATe OFF');
}

1;

# the documentation, will be converted to HTML
=pod
=encoding utf-8

=head1 NAME

Lab::Instrument::RSSMB100A - Rohde & Schwarz SMB100A Signal Generator

=head1 AUTHOR/COPYRIGHT

  Copyright 2005 Daniel Schroeer (<schroeer@cpan.org>)
            2011 Andreas K. Huettel
            2014 Andreas K. Huettel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
