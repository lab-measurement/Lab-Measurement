#$Id$

package Lab::Instrument::ILM;

use strict;
use Lab::Instrument::IsoBus;
use Lab::Instrument;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{vi}=new Lab::Instrument(@_);
    return $self;
}

sub get_level {
  my $self = shift;

  my $level=$self->{vi}->{IsoBus}->IsoBus_Query($self->{isoaddress}, "R1");
  $level=~s/^R//;
  $level/=10;
  return $level;  
};

1;

=head1 NAME

Lab::Instrument::ILM - Oxford Instruments ILM Intelligent level meter

=head1 SYNOPSIS

    use Lab::Instrument::ILM;
    
    my $ilm=new Lab::Instrument::ILM($isobus,3);
    print $ilm->get_level();

=head1 DESCRIPTION

The Lab::Instrument::ILM class implements an interface to the Oxford Instruments 
ILM helium level meter (tested with the ILM210).


=head1 CONSTRUCTOR

    my $ilm=new Lab::Instrument::ILM($isobus,$addr);

Instantiates a new ILM object, attached to the IsoBus device (of type C<Lab::Instrument::IsoBus>) C<$IsoBus>, 
with IsoBus address C<$addr>.

=head1 METHODS

=head2 get_level

    $perc=$ilm->get_level();

Reads out the current helium level in percent. Note that this command does NOT trigger a measurement, but 
only reads out the last value measured by the ILM. This means that in slow mode values may remain constant
for several minutes.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>
=item L<Lab::Instrument::IsoBus>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2010 Andreas K. Hüttel (L<http://www.akhuettel.de/>)

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
