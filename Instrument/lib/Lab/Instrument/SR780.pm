#$Id$

package Lab::Instrument::SR780;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self
}

sub read_display_data {
    my ($self,$display)=shift;
    my $display=(ord(uc $display)-65) & 1;
    
    $self->{vi}->Write('DSPY? 0');
    my @res=split ",",$self->{vi}->Read(30000);
    return @res;
}

sub id {
    my $self=shift;
    $self->{vi}->Query('*IDN?');
}

sub tone {
    my ($self,$tone,$duration)=@_;
    
    $self->{vi}->Write("TONE $duration,$tone");
}

sub play {
    my ($self,$sound)=@_;
    
    $self->{vi}->Write("PLAY $sound");
}

sub play_song {
    my $self=shift;
    
    for (([4, 20],[5, 20],[6, 20],[7, 20],[8, 40],[8, 40],
          [9, 20],[9, 20],[9, 20],[9, 20],[8, 40],[-1, 20],
          [9, 20],[9, 20],[9, 20],[9, 20],[8, 40],[-1, 20],
          [7, 20],[7, 20],[7, 20],[7, 20],[6, 40],[6, 40],
          [5, 20],[5, 20],[5, 20],[5, 20],[4, 40])) {
        $self->tone(@$_) if ($_->[0] > 0);
        usleep($_->[1]*15000);
    }
}
              
1;

=head1 NAME

Lab::Instrument::SR780 - Stanford Research SR780 Network Signal Analyzer

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head2 read_display_data

=head2 id

=head2 play

=head2 tone

=head2 play_song

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
