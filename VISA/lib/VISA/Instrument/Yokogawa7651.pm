#$Id$

package VISA::Instrument::Yokogawa7651;
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
	$self->_set($voltage);
}

sub set_current {
	my $self=shift;
	my $voltage=shift;
	$self->_set($voltage);
}

sub _set {
	my $self=shift;
	my $value=shift;
	my $cmd=sprintf("S%e",$value);
	$self->{vi}->Write($cmd);
	$cmd="E";
	$self->{vi}->Write($cmd);
}

sub get_voltage {
	my $self=shift;
	return $self->_get();
}

sub get_current {
	my $self=shift;
	return $self->_get();
}

sub _get {
	my $self=shift;
	my $cmd="OD";
	my $result=$self->{vi}->Query($cmd);
	$result=~s/OUT //;
	return $result;
}

sub set_current_mode {
	my $self=shift;
	my $cmd="F5";
	$self->{vi}->Write($cmd);
}

sub set_voltage_mode {
	my $self=shift;
	my $cmd="F1";
	$self->{vi}->Write($cmd);
}

sub set_range {
	my $self=shift;
	my $range=shift;
	my $cmd="R$range";
	  #fixed voltage mode
	  #	2	10mV
	  # 3	100mV
	  # 4	1V
	  # 5	10V
	  # 6	30V
	  #fixed current mode
	  # 4	1mA
	  # 5	10mA
	  # 6	100mA
	$self->{vi}->Write($cmd);
}

sub get_range {
	my $self=shift;
	my $cmd="OS";
	my $result=$self->{vi}->Query($cmd);
	$result=~s/RANGE //;
	return $result;
}

1;

=head1 NAME

Yokogawa7651 - a Yokogawa 7651 DC source

=head1 SYNOPSIS

    use Yokogawa7651;
    
    my $gate14=new Yokogawa7651(0,11);
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

The Yokogawa7651 class uses the VISA module (L<VISA>).

=item VISA::Instrument

The Yokogawa7651 class is a VISA::Instrument (L<VISA::Instrument>).

=item SafeSource

The Yokogawa7651 class is a SafeSource (L<SafeSource>)

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
