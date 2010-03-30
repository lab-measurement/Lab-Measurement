package Lab::Instrument::Lakeshore336;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our $VERSION = sprintf("0.%04d", q$Revision: 119 $ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{vi}=new Lab::Instrument(@_);
    return $self
}


sub read_t {

    my ($self,$chan)= @_;
    my $temp=$self->{vi}->Query("KRDG? $chan");
    chomp $temp;
    $temp =~ s/\n//;
    $temp =~ s/\r//;
    return $temp;
}

sub read_r {

    my ($self,$chan)= @_;
    my $r=$self->{vi}->Query("SRDG? $chan");
    chomp $r;
    $r =~ s/\n//;
    $r =~ s/\r//;
    return $r;
}

sub get_setp {

    my ($self,$output)= @_;
    my $temp=$self->{vi}->Query("SETP? $output");
    chomp $temp;
    $temp =~ s/\n//;
    $temp =~ s/\r//;
    return $temp;
}

sub set_setp {

    my ($self,$output,$t)= @_;
    $self->{vi}->WRITE("SETP $output,$t");
}


sub id {
    my $self=shift;
    $self->{vi}->Query('*IDN?');
}

              
1;

=head1 NAME

Lab::Instrument::Lakeshore336 - Lakeshore 336 Temperature controller

UNGETESTET

=head1 SYNOPSIS

    use Lab::Instrument::Lakeshore336;
    
    my $lake=new Lab::Instrument::Lakeshore336(0,10);

    $temp = $lake->read_t();
    $r = $lake->read_r();
    
=head1 DESCRIPTION

The Lab::Instrument::Lakeshore336 class implements an interface to the
Lakeshore 336 AC Resistance Bridge.

=head1 CONSTRUCTOR

  $lake=new Lab::Instrument::Lakeshore370($board,$gpib);

=head1 METHODS

=head2 read_t

  $t = $lake->read_t();

Reads temperature in Kelvin (only possible if temperature curve is available, otherwise returns zero).

=head2 read_r

  $r = $lake->read_r();

Reads resistance in ohms.

=head2 id

  $id=$sr780->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: Lakeshore336.pm 119 2010-01-13 19:03:49Z hua59129 $

#Copyright 2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
