#$Id$

package VISA::Instrument::IPS120_10;

use strict;
use VISA::Instrument;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

	$self->{vi}=new VISA::Instrument(@_);

	return $self
}

sub set_control {
# 0 Local & Locked
# 1 Remote & Locked
# 2 Local & Unlocked
# 3 Remote & Unlocked
	my $self=shift;
	my $mode=shift;
	$self->{vi}->Write("C$mode\n");
}

sub set_communications_protocol {
# 0 "Normal" (default)
# 2 Sends <LF> after each <CR>
# 4 Extended Resolution
# 6 Extended Resolution. Sends <LF> after each <CR>.
	my $self=shift;
	my $mode=shift;
	$self->{vi}->Write("Q$mode\n");
}

sub read_parameter {
# 0 Demand current (output current)		amp
# 1 Measured power supply voltage		volt
# 2 Measured magnet current				amp
# 3 -
# 4 -
# 5 Set point (target current)			amp
# 6 Current sweep rate					amp/min
# 7 Demand field (output field)			tesla
# 8 Set point (target field)			tesla
# 9 Field sweep rate					tesla/minute
#10 - 14 -
#15 Software voltage limit				volt
#16 Persistent magnet current			amp
#17 Trip current						amp
#18 Persistent magnet field				tesla
#19 Trip field							tesla
#20 Switch heater current				milliamp
#21 Safe current limit, most negative	amp
#22 Safe current limit, most positive	amp
#23 Lead resistance						milliohm
#24 Magnet inductance					henry
	my $self=shift;
	my $parameter=shift;
	my $result=$self->{vi}->Query("R$parameter\n");
	return $result;
}

# Hier spezialisierte read-Methoden einführen (read_set_point())

sub set_activity {
# 0 Hold
# 1 To Set Point
# 2 To Zero
# 4 Clamp (clamp the power supply output)
	my $self=shift;
	my $mode=shift;
	$self->{vi}->Write("A$mode\n");
}	

sub set_switch_heater {
# 0 Heater Off					(close switch)
# 1 Heater On if PSU=Magnet		(open switch)
#  (only perform operation
#   if recorded magnet current==present power supply output current)
# 2 Heater On, no Checks		(open switch)
	my $self=shift;
	my $mode=shift;
	$self->{vi}->Write("H$mode\n");
}

sub set_target_current {
	my $self=shift;
	my $current=shift;
	$self->{vi}->Write("I$current\n");
}

sub set_target_field {
	my $self=shift;
	my $field=shift;
	$self->{vi}->Write("J$field\n");
}

sub set_mode {
#		Display		Magnet Sweep
# 0 	Amps		Fast
# 1		Tesla		Fast
# 4		Amps		Slow
# 5		Tesla		Slow
# 8		Amps		Unaffected
# 9		Tesla		Unaffected
	my $self=shift;
	my $mode=shift;
	$self->{vi}->Write("M$mode\n");
}

sub set_polarity {
# 0 No action
# 1 Set positive current
# 2 Set negative current
# 3 Swap polarity
	my $self=shift;
	my $mode=shift;
	$self->{vi}->Write("P$mode\n");
}

sub set_current_sweep_rate {
# amps/min
	my $self=shift;
	my $rate=shift;
	$self->{vi}->Write("S$rate\n");
}

sub set_field_sweep_rate {
# tesla/min
	my $self=shift;
	my $rate=shift;
	$self->{vi}->Write("T$rate\n");
}

1;

=head1 NAME

VISA::Instrument::IPS120_10 - an IPS120-10 superconducting magnet power supply

=head1 SYNOPSIS

    use VISA::Instrument::IPS120_10;
    
    my $hp22=new VISA::Instrument::IPS120_10(0,22);

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 set_control($mode)

 # 0 Local & Locked
 # 1 Remote & Locked
 # 2 Local & Unlocked
 # 3 Remote & Unlocked

=head2 set_communications_protocol($mode)

 # 0 "Normal" (default)
 # 2 Sends <LF> after each <CR>
 # 4 Extended Resolution
 # 6 Extended Resolution. Sends <LF> after each <CR>.

=head2 read_parameter($parameter)

 # 0 Demand current (output current)    amp
 # 1 Measured power supply voltage      volt
 # 2 Measured magnet current            amp
 # 3 -
 # 4 -
 # 5 Set point (target current)         amp
 # 6 Current sweep rate                 amp/min
 # 7 Demand field (output field)        tesla
 # 8 Set point (target field)           tesla
 # 9 Field sweep rate                   tesla/minute
 #10 - 14 -
 #15 Software voltage limit             volt
 #16 Persistent magnet current          amp
 #17 Trip current                       amp
 #18 Persistent magnet field            tesla
 #19 Trip field                         tesla
 #20 Switch heater current              milliamp
 #21 Safe current limit, most negative  amp
 #22 Safe current limit, most positive  amp
 #23 Lead resistance                    milliohm
 #24 Magnet inductance                  henry

=head2 set_activity($activity)

 # 0 Hold
 # 1 To Set Point
 # 2 To Zero
 # 4 Clamp (clamp the power supply output)

=head2 set_switch_heater($mode)

 # 0 Heater Off                     (close switch)
 # 1 Heater On if PSU=Magnet        (open switch)
 #  (only perform operation
 #   if recorded magnet current==present power supply output current)
 # 2 Heater On, no Checks           (open switch)

=head2 set_target_current($current)

=head2 set_target_field($field)

=head2 set_mode($mode)

 #      Display     Magnet Sweep
 # 0    Amps        Fast
 # 1    Tesla       Fast
 # 4    Amps        Slow
 # 5    Tesla       Slow
 # 8    Amps        Unaffected
 # 9    Tesla       Unaffected

=head2 set_polarity($polarity)

 # 0 No action
 # 1 Set positive current
 # 2 Set negative current
 # 3 Swap polarity

=head2 set_current_sweep_rate($rate)

 amps/min

=head2 set_field_sweep_rate($rate)

 testa/min

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item VISA::Instrument

The IPS120_10 uses the VISA::Instrument class (L<VISA::Instrument>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
