#$Id$

package Lab::Instrument::HP8360;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our $VERSION = sprintf("0.%04d", q$Revision: 339 $ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{vi}=new Lab::Instrument(@_);
    return $self
}

sub reset {
	my $self=shift;
	$self->{vi}->Write('*RST');
}

sub set_cw {
	my $self=shift;
	my $freq=shift;
	$self->{vi}->Write("FREQ:CW $freq");
	$self->{vi}->Query('*OPC?');
}

sub set_power {
	my $self=shift;
	my $power=shift;

	$self->{vi}->Write("POW:LEV $power");
	$self->{vi}->Query('*OPC?');
}

sub power_on {
	my $self=shift;
	$self->{vi}->Write('POWer:STATe ON');
}

sub power_off {
	my $self=shift;
	$self->{vi}->Write('POWer:STATe OFF');
}
              
1;

=head1 NAME

Lab::Instrument::HP8360 - HP 8360 B-Series Swept Signal Generator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
