#$Id$

package VISA::Instrument::KnickS252;
use strict;
use VISA::Instrument;
use VISA::Instrument::SafeSource;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

our @ISA=('VISA::Instrument::SafeSource');

my $default_config={
	gate_protect			=> 0,
	gp_max_volt_per_step	=> 0.0005,
	gp_max_volt_per_second	=> 0.002
};

sub new {
	my $proto = shift;
	my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = new $class->SUPER($default_config,@args);
    bless ($self, $class);

	$self->{vi}=new VISA::Instrument(@args);

	return $self
}

sub _set_voltage {
	my $self=shift;
	my $voltage=shift;
	my $cmd=sprintf("X OUT %e\n",$voltage);
	$self->{vi}->Write($cmd);
}

sub get_voltage {
	my $self=shift;
	my $cmd="R OUT\n";
	my $result=$self->{vi}->Query($cmd);
	$result=~/^OUT\s+([\d\.E\+\-]+)V/;
	return $1;
}

sub set_range {
	my $self=shift;
	my $range=shift;
	my $cmd="P RANGE $range\n";
	$self->{vi}->Write($cmd);
}

sub get_range {
	my $self=shift;
	my $cmd="R RANGE\n";
		#  5	 5V
		# 20	20V
	my $result=$self->{vi}->Query($cmd);
	($result)=$result=~/^RANGE\s+((AUTO)|5|(20))/;
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

Copyright 2004 Daniel Schr�er (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
