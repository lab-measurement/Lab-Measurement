package Lab::Instrument::HP83732A;
our $VERSION = '3.10';

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

# Programming manual: 
# http://www.anritsu.com/en-GB/Downloads/Manuals/Programming-Manual/DWL2029.aspx

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


sub id {
    my $self=shift;
    return $self->query('*IDN?');
}


sub reset {
    my $self=shift;
    $self->write('*RST');
}

sub set_cw {
    my $self=shift;
    my $freq=shift;
    $freq/=1000000;
    $self->write("F0 $freq MH ACW");
}

sub set_power {
    my $self=shift;
    my $power=shift;

    $self->write("L0 $power DM");
}

sub power_on {
    my $self=shift;
    $self->write('RF 1');
}

sub power_off {
    my $self=shift;
    $self->write('RF 0');
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::MG369xB - MG369xB Series Signal Generator

IMPORTANT: Only works for B series devices. MG369xA use SCPI commands and are 
supported by HP83732A driver.

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

  Copyright 2012 Hermann Kraus

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
