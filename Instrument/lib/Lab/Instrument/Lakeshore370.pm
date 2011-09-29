package Lab::Instrument::Lakeshore370;

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


sub set_channel {
    my ($self,$chan)=@_;
    $self->{vi}->Write("SCAN $chan,0"); # "0" fuer autoscan = off
    my $realchan=$self->{vi}->Query("SCAN?");
    chomp $realchan;
    return "$realchan";
}

sub read_t {

    my ($self,$chan)= @_;
    my $temp=$self->{vi}->Query("RDGK? $chan");
    chomp $temp;
    $temp =~ s/\n//;
    $temp =~ s/\r//;
    return $temp;
}

sub read_r {

    my ($self,$chan)= @_;
    my $r=$self->{vi}->Query("RDGR? $chan");
    chomp $r;
    $r =~ s/\n//;
    $r =~ s/\r//;
    return $r;
}


sub id {
    my $self=shift;
    $self->{vi}->Query('*IDN?');
}

              
1;

=head1 NAME

Lab::Instrument::Lakeshore370 - Lakeshore 370 AC Resistance Bridge

=head1 SYNOPSIS

    use Lab::Instrument::Lakeshore370;
    
    my $lake=new Lab::Instrument::Lakeshore370(0,10);

    $temp = $lake->read_t();
    $r = $lake->read_r();
    
=head1 DESCRIPTION

The Lab::Instrument::Lakeshore370 class implements an interface to the
Lakeshore 370 AC Resistance Bridge.

=head1 CONSTRUCTOR

  $lake=new Lab::Instrument::Lakeshore370($board,$gpib);

=head1 METHODS

=head2 read_t

  $t = $lake->read_t();

Reads temperature in Kelvin (only possible if temperature curve is available, otherwise returns zero).

=head2 read_r

  $r = $lake->read_r();

Reads resistance in ohms.

=head2 set_channel

  $lake->set_channel(4);

Sets channel to scan (with autoscan = off); returns channel the bridge was set to.

=head2 id

  $id=$lake->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
