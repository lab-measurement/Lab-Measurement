#$Id: HP8360.pm 301 2010-05-10 10:12:43Z hua59129 $

package Lab::Instrument::HP83732A;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our $VERSION="1.21";

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
	$freq/=1000000;
    $self->{vi}->Write("FREQuency:CW $freq MHZ");
}

sub set_power {
    my $self=shift;
    my $power=shift;

    $self->{vi}->Write("POWer:LEVel $power DBM");
}

sub power_on {
    my $self=shift;
    $self->{vi}->Write('OUTP:STATe ON');
}

sub power_off {
    my $self=shift;
    $self->{vi}->Write('OUTP:STATe OFF');
}

sub selftest {
    my $self=shift;
    return $self->{vi}->Query("*TST?");
}

sub display_on {
    my $self=shift;
    $self->{vi}->Write("DISPlay ON");
}

sub display_off {
    my $self=shift;
    $self->{vi}->Write("DISPlay OFF");
}

sub enable_external_am {
    my $self=shift;
    $self->{vi}->Write("AM:DEPTh MAX");
    $self->{vi}->Write("AM:SENSitivity 70PCT/VOLT");
    $self->{vi}->Write("AM:TYPE LINear");
    $self->{vi}->Write("AM:STATe ON");
}

sub disable_external_am {
    my $self=shift;
    $self->{vi}->Write("AM:STATe OFF");
}

1;

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

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: HP8360.pm 301 2010-05-10 10:12:43Z hua59129 $

Copyright 2005 Daniel Schröer (<schroeer@cpan.org>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
