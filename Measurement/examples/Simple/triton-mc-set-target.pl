#!/usr/bin/perl

use strict;
use Lab::Instrument::OI_Triton;

################################

my $t = Lab::Instrument::OI_Triton->new( connection_type => 'Socket', );

my $temp = $t->get_T();
print "MC temperature is $temp K\n";

print $t->enable_control();

print $t->enable_temp_pid();
print $t->set_T(0.035);

1;

=pod

=encoding utf-8

=head1 triton-mc.pl

Sets an OI dilution refrigerator to regulate the temperature to 30mK
(using sensor 5 and heater 1, as per default in OI_Triton.pm)

=head2 Usage example

  $ perl triton-mc-set-target.pl
  
=head2 Author / Copyright

  (c) Andreas K. Hüttel 2016

=cut
