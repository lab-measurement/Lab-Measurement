#!/usr/bin/perl -w
# POD

package Lab::Instrument::Keithley236;

use strict;

use Lab::Instrument;
use Time::HiRes qw(usleep sleep);

our @ISA = qw( Lab::Instrument );


sub new {
    my $object=shift;
    my %args = @_;
    $args{'InterfaceDelay'} = 0.1 if (not(exists  $args{'InterfaceDelay'}));

    my $self = $object->SUPER::new(%args);

    if (defined $self) {
                $self->{'CommandRules'} = {
                                  'preCommand'        => '',
                                  'inCommand'         => '',
                                  'betweenCmdAndData' => '',
				  'postData'	      => 'X'
                                };
               return $self;
    }
    return undef;
}


sub DCvoltageSource {
    my $self = shift;

    $self->Write("F0,0X");
}

sub DCcurrentSource {
    my $self = shift;

    $self->Write("F1,0X");
}

sub setCompliance {
  my $self = shift;

  my $level = shift;
  my $range = 0;
  $range = shift if (@_ > 0);

  $self->Write("L$level,$range"."X");
}

sub setOutputLevel {

  my $self = shift;

  my $level = shift;
  my $range = 0;
  $range = shift if (@_ > 0);
  my $delay = 0;
  $delay = shift if (@_ > 0);

  $self->Write("B$level,$range,$delay"."X");


}

sub setTriggerMode {
    my $self = shift;

    $self->Write("R1T0,0,0,0X");
}

sub operate {

	my $object = shift;
	$object->Write("N1X");

}

sub standby {

	my $object = shift;
	$object->Write("N0X");
	
}


# return value
1;

=pod

=head1 NAME

Lab::Instrument::Keithley236

=head1 SYNOPSIS

 my $smu =  Lab::Instrument::Keithley236->new ( Interface => 'TCPIP::Prologix',
                                                PeerAddr  => 'cs025',
                                                GPIBAddr  => 12 );
 $smu->operate();

=head1 DESCRIPTION

C<Lab::Instrument::Keithley> is a control package for the Keithely Source Measurement Unit 236.

=head1 CONSTRUCTOR

=head2 new

Nothing special. Inherited from C<Lab::Instrument>

=head1 METHODS

=head2 DCvoltageSource

Select voltage source and current measurement mode (DC)

=head2 DCcurrentSource

Select current source and voltage measurement mode (DC)

=head2 setCompliance 

Set teh compliance levels - please refer to Quick Manual Page 62

setCompliance(level [,range])

Auto range is selected if no range is given

=head2 setOutputLevel

Sets the output voltage or current 

setOutputLevel(level[, range [, delay]])

level = voltage or current
range = refer to quick guide page 56 (default = auto)
delay = DC delay in ms (default = 0)

=head2 setTriggerMode

Sets trigger mode for internal self triggering. Has to be extended for 
external trigger functions.

=head2 operate

Select operate Mode -> operate

Call: operate

=head2 standby

standby Select standby Mode to run after get_measdata;

Call: standby

=head1 CAVEATS/BUGS

Unkown, so far.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2010      Matthias Voelker <mvoelker@cpan.org>     

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

