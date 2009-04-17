#$Id$
package Lab::Instrument::TemperatureControl;
use strict;

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    %{$self->{default_config}}=%{shift @_};
    %{$self->{config}}=%{$self->{default_config}};
    $self->configure(@_);

	# preset some sane values for device protection
    $self->{config}->{min_temp}=0.05;
    $self->{config}->{max_temp}=1;
    $self->{config}->{temp_tolerance}=5;

    return $self;
}

sub configure {
    my $self=shift;

    #supported config options are (so far)
    #   max_temp		maximum safe temperature
    #   min_temp		minumim reachable temperature
	#   temp_tolerance	temperature tolerance in percent

    my $config=shift;
    if ((ref $config) =~ /HASH/) {
        for my $conf_name (keys %{$self->{default_config}}) {
            #print "Key: $conf_name, default: ",$self->{default_config}->{$conf_name},", old config: ",$self->{config}->{$conf_name},", new config: ",$config->{$conf_name},"\n";
            unless ((defined($self->{config}->{$conf_name})) || (defined($config->{$conf_name}))) {
                $self->{config}->{$conf_name}=$self->{default_config}->{$conf_name};
            } elsif (defined($config->{$conf_name})) {
                $self->{config}->{$conf_name}=$config->{$conf_name};
            }
        }
        return $self;
    } elsif($config) {
        return $self->{config}->{$config};
    } else {
        return $self->{config};
    }
}

sub set_temp {
    my $self=shift;
	my $temp=shift;
	
	if ($temp>$self->{config}->{max_temp}) {$temp=$self->{config}->{max_temp}; };
	if ($temp<0) {$temp=0; };
	
	$temp=$self->_set_tmp(@_);
    return $temp;
}

sub set_temp_wait {
	my $self=shift;

	my $target=$self->set_temp(@_);
	
	do {
		# and now wait for the temperature...
	
		sleep(10);
		$now=$self->get_temp();

		if (($target < $self->{config}->{min_temp}) {$target=$self->{config}->{min_temp}; };
		$diff=(abs($now-$target)/$target*100);
		
	} until ($diff <= $self->{config}->{temp_tolerance});
}

sub _set_temp {
    warn '_set_temp not implemented for this instrument';
}

sub get_temp
    my $self=shift;
    my $temp=$self->_get_temp(@_);
    return $temp;
}

sub _get_temp {
    warn '_get_temp not implemented for this instrument';
}



1;

=head1 NAME

Lab::Instrument::Source - Base class for voltage source instruments

=head1 SYNOPSIS

=head1 DESCRIPTION

This class implements a general voltage source. It is meant to be
inherited by instrument classes (virtual instruments), that implement
real voltage sources (e.g. the
L<Lab::Instrument::Yokogawa7651|Lab::Instrument::Yokogawa7651> class).

The class provides a unified user interface for those virtual voltage sources
to support the exchangeability of instruments.

Additionally, this class provides a safety mechanism called C<gate_protect>
to protect delicate samples. It includes automatic limitations of sweep rates,
voltage step sizes, minimal and maximal voltages.

As a user you are NOT supposed to create instances of this class, but rather
instances of instrument classes that internally use this module!

=head1 CONSTRUCTOR

  $self=new Lab::Instrument::SafeSource(\%default_config,\%config);

The constructor will only be used by instrument drivers that inherit this class,
not by the user.

The instrument driver (e.g. L<Lab::Instrument::KnickS252|Lab::Instrument::KnickS252>)
has a constructor like this:

  $knick=new Lab::Instrument::KnickS252({
    GPIB_board      => $board,
    GPIB_address    => $address,
    
    gate_protect    => $gp,
    [...]
  });

=head1 METHODS

=head2 configure

  $self->configure(\%config);

Supported configure options are all related to the safety mechanism:

=over 2

=item gate_protect

Whether to use the automatic sweep speed limitation. Can be set to 0 (off) or 1 (on).
If it is turned on, the output voltage will not be changed faster than allowed
by the C<gp_max_volt_per_second>, C<gp_max_volt_per_step> and C<gp_max_step_per_second>
values. These three parameters overdefine the allowed speed. Only two
parameters are necessary. If all three are set, the smalles allowed sweep rate
is chosen.

Additionally the maximal and minimal output voltages are limited.

This mechanism is useful to protect sensible samples, that are destroyed by
abrupt voltage changes. One example is gate electrodes on semiconductor electronics
samples, hence the name.

=item gp_max_volt_per_second

How much the output voltage is allowed to change per second.

=item gp_max_volt_per_step

How much the output voltage is allowed to change per step.

=item gp_max_step_per_second

How many steps are allowed per second.

=item gp_min_volt

The smallest allowed output voltage.

=item gp_max_volt

The largest allowed output voltage.

=item qp_equal_level

Voltages with a difference less than this value are considered equal.

=back

=head2 set_voltage

  $new_volt=$self->set_voltage($voltage);

Sets the output to C<$voltage> (in Volts). If the configure option C<gate_protect> is set
to a true value, the safety mechanism takes into account the C<gp_max_volt_per_step>,
C<gp_max_volt_per_second> etc. settings, by employing the C<sweep_to_voltage> method.

Returns the actually set output voltage. This can be different from C<$voltage>, due
to the C<gp_max_volt>, C<gp_min_volt> settings.

=head2 step_to_voltage

  $new_volt=$self->step_to_voltage($voltage);

Makes one safe step in direction to C<$voltage>. The output voltage is not changed by more
than C<gp_max_volt_per_step>. Before the voltage is changed, the methods waits if not
enough times has passed since the last voltage change. For step voltage and waiting time
calculation, the larger of C<gp_max_volt_per_second> or C<gp_max_step_per_second> is ignored
(see code).

Returns the actually set output voltage. This can be different from C<$voltage>, due
to the C<gp_max_volt>, C<gp_min_volt> settings.

=head2 sweep_to_voltage

  $new_volt=$self->sweep_to_voltage($voltage);

This method sweeps the output voltage to the desired value and only returns then.
Uses the L</step_to_voltage> method internally, so all discussions of config options
from there apply too.

Returns the actually set output voltage. This can be different from C<$voltage>, due
to the C<gp_max_volt>, C<gp_min_volt> settings.

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item L<Time::HiRes>

Used internally for the sweep timing.

=item L<Lab::Instrument::KnickS252>

This class inherits the gate protection mechanism.

=item L<Lab::Instrument::Yokogawa7651>

This class inherits the gate protection mechanism.

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004-2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
