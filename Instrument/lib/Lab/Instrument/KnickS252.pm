#$Id$

package Lab::Instrument::KnickS252;
use strict;
use Lab::Instrument;
use Lab::Instrument::Source;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

our @ISA=('Lab::Instrument::Source');

my $default_config={
    gate_protect            => 0,
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.0005,
    gp_max_step_per_second  => 2,
};

sub new {
    my $proto = shift;
    my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($default_config,@args);
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@args);

    return $self
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    my $cmd=sprintf("X OUT %e\n",$voltage);
    $self->{vi}->Write($cmd);
}

sub _get_voltage {
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
        #  5     5V
        # 20    20V
    my $result=$self->{vi}->Query($cmd);
    ($result)=$result=~/^RANGE\s+((AUTO)|5|(20))/;
    return $result;
}

1;

=head1 NAME

Lab::Instrument::KnickS252 - Knick S 252 DC source

=head1 SYNOPSIS

    use Lab::Instrument::KnickS252;
    
    my $gate14=new Lab::Instrument::KnickS252(0,11);
    $gate14->set_range(5);
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::KnickS252 class implements an interface
to the Knick S 252 dc calibrator. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTOR

    $knick=new Lab::Instrument::KnickS252($gpib_board,$gpib_addr);
    # Or any other type of construction supported by Lab::Instrument.

=head1 METHODS

=head2 set_voltage

    $knick->set_voltage($voltage);

=head2 get_voltage

    $voltage=$knick->get_voltage();

=head2 set_range

    $knick->set_range($range);
    # $range is 5 or 20
    #  5  is 5V
    # 20  is 20V

=head2 get_range

    $range=$knick->get_range();
    # $range is 5 or 20
    #  5  is 5V
    # 20  is 20V

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item VISA

The Lab::Instrument::KnickS252 class uses the VISA module (L<VISA>).

=item Lab::Instrument

The Lab::Instrument::KnickS252 class is a Lab::Instrument (L<Lab::Instrument>).

=item SafeSource

Inherits from SafeSource (L<SafeSource>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004/2005 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
