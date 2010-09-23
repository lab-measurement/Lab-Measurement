#!/usr/bin/perl -w
# POD

package Lab::Instrument::SCPI;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep sleep);

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);
our @ISA = qw( Lab::Instrument );

sub new {
	my $object = shift;
        my $self = $object->SUPER::new(@_);
        
	if (defined $self) {
		$self->{'CommandRules'} = { 
				  'preCommand'        => ':',
                                  'inCommand'         => ':',
                                  'betweenCmdAndData' => ' '
                                };
		
        return $self;
	}

	return undef;
}

# add a ? to each request if not there
sub Query {
    my $self = shift;
    my $string = shift;

    unless ($string =~ /\?$/) {
        $string .='?';
    }
    if (@_ > 0) {
        return $self->SUPER::Query($string,@_);
    } else {
        return $self->SUPER::Query($string);
    }
}

# everything  fine

return 1;


=pod

=head1 NAME

Lab::Instrument::SCPI

=head1 SYNOPSIS

 example:
 my $hp22 =  Lab::Instrument::SCPI->new ( Interface => 'TCPIP',
                                          PeerAddr  => 'cs025' ); # TCPIP interface via LAN to port 5025
 print $hp22->Query('*IDN?');
 $hp22->WriteConfig( 'VOLTAGE' => { 'HIGH' => 1.5,
                                    'LOW'  => 0.5 },
                      'BURST'        => { 'MODE' => 'TRIG',
                                          'NCYCLES' => 1,
                                          'INTERNAL:PERIOD' => '100ms',
                                          'STATE'  => 'ON',
                                          'SOURCE' => 'INT',
                                          'PHASE'  => 0 },
                     'TRIGGER:SOURCE' => 'IMM'
                         );

=head1 DESCRIPTION

C<Lab::Instrument::SCPI> is a basic setup package for all instruemnts using SCPI e.g. Agilent an Tektronix.
The correct command synatx is set up to use WriteConfig for these instruments.

=head1 CONSTRUCTOR

=head2 new

The same as for C<Lab::Instrument>

 $instrument = Lab::Instrument:SCPI->new( Interface => TCPIP|VISA|LANprologix,
                                          parameter name => parameter as require by the Interface,
                                          ... );

=head1 METHODS

Inherited from C<Lab::Instrument>.

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

 Copyright 2004-2006 Daniel Schroer <schroeer@cpan.org>, 
           2009-2010 Daniel Schroer, Andreas K. H¿tel (L<http://www.akhuettel.de/>) and David Kalok
           2010      Matthias Voelker <mvoelker@cpan.org>     

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut



