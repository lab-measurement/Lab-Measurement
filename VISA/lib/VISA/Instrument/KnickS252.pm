#$Id$

package VISA::Instrument::KnickS252;
use strict;
use VISA::Instrument;
use SafeSource;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

our @ISA=('SafeSource');

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = new SafeSource();
    bless ($self, $class);

	$self->{vi}=new VISA::Instrument(@_);

	return $self
}

sub _set_voltage {
	my $self=shift;
	my $voltage=shift;
	my $cmd=sprintf("X OUT %e",$voltage);
	$self->{vi}->Write($cmd);
}

sub get_voltage {
	my $self=shift;
	my $cmd="R OUT";
	my $result=$self->{vi}->Query($cmd);
	$result=~s/OUT //;
	return $result;
}

sub set_range {
	my $self=shift;
	my $range=shift;
	my $cmd="P RANGE $range";
	$self->{vi}->Write($cmd);
}

sub get_range {
	my $self=shift;
	my $cmd="R RANGE";
		#  5	 5V
		# 20	20V
	my $result=$self->{vi}->Query($cmd);
	$result=~s/RANGE //;
	return $result;
}

1;

=head1 NAME

KnickS252 - a Knick S 252 DC source

=head1 SYNOPSIS

    use KnickS252;
    
    my $gate14=new KnickS252(0,11);
	$gate14->set_range(5);
	$gate14->set_voltage(0.745);
	print $gate14->get_voltage();

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_range($range)

=head2 get_range()

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item VISA

The HP34401A class uses the VISA module (L<VISA>).

=item VISA::Instrument

The KnickS252 class is a VISA::Instrument (L<VISA::Instrument>).

=item SafeSource

Inherits from SafeSource (L<SafeSource>)

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
