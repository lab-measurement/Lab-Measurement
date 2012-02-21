package Lab::Instrument::HP83732A;
our $VERSION = '2.95';

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our @ISA = ("Lab::Instrument");

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
	return $self;
}





sub reset {
    my $self=shift;
    $self->write('*RST');
}

sub set_cw {
    my $self=shift;
    my $freq=shift;
	$freq/=1000000;
    $self->write("FREQuency:CW $freq MHZ");
}

sub set_power {
    my $self=shift;
    my $power=shift;

    $self->write("POWer:LEVel $power DBM");
}

sub power_on {
    my $self=shift;
    $self->write('OUTP:STATe ON');
}

sub power_off {
    my $self=shift;
    $self->write('OUTP:STATe OFF');
}

sub selftest {
    my $self=shift;
    return $self->query("*TST?");
}

sub display_on {
    my $self=shift;
    $self->write("DISPlay ON");
}

sub display_off {
    my $self=shift;
    $self->write("DISPlay OFF");
}

sub enable_external_am {
    my $self=shift;
    $self->write("AM:DEPTh MAX");
    $self->write("AM:SENSitivity 70PCT/VOLT");
    $self->write("AM:TYPE LINear");
    $self->write("AM:STATe ON");
}

sub disable_external_am {
    my $self=shift;
    $self->write("AM:STATe OFF");
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::HP83732A - HP 83732A Series Synthesized Signal Generator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item * Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2005 Daniel Schröer (<schroeer@cpan.org>)
            2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
