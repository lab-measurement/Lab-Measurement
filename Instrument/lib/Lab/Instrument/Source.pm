#$Id$
package Lab::Instrument::Source;
use strict;
use Time::HiRes qw(usleep gettimeofday);

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    %{$self->{default_config}}=%{shift @_};
    %{$self->{config}}=%{$self->{default_config}};
    $self->configure(@_);

    $self->{_gp}->{last_voltage}=undef;
    $self->{_gp}->{last_settime_mus}=undef;
    
    return $self;
}

sub configure {
    my $self=shift;
    #supported config options are (so far)
    #   gate_protect
    #   gp_max_volt_per_second
    #   gp_max_volt_per_step
    #   gp_max_step_per_second
    #   gp_min_volt
    #   gp_max_volt
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

sub set_voltage {
    my $self=shift;
    my $voltage=shift;
    
    if ($self->{config}->{gate_protect}) {
        $voltage=$self->sweep_to_voltage($voltage);
    } else {
        $self->_set_voltage($voltage);
    }
    $self->{_gp}->{last_voltage}=$voltage;
    return $voltage;
}

sub step_to_voltage {
    my $self=shift;
    my $voltage=shift;

    my $voltpersec=abs($self->{config}->{gp_max_volt_per_second});
    my $voltperstep=abs($self->{config}->{gp_max_volt_per_step});
    my $steppersec=abs($self->{config}->{gp_max_step_per_second});

    #read output voltage from instrument (only at the beginning)
    my $last_v=$self->{_gp}->{last_voltage};
    unless (defined $last_v) {
        $last_v=$self->get_voltage();
        $self->{_gp}->{last_voltage}=$last_v;
    }

    if (defined($self->{config}->{gp_max_volt}) && ($voltage > $self->{config}->{gp_max_volt})) {
        $voltage = $self->{config}->{gp_max_volt};
    }
    if (defined($self->{config}->{gp_min_volt}) && ($voltage < $self->{config}->{gp_min_volt})) {
        $voltage = $self->{config}->{gp_min_volt};
    }

    #already there
    return $voltage if (abs($voltage - $last_v) < 1e-5);

    #do the magic step calculation
    my $wait = ($voltpersec < $voltperstep * $steppersec) ?
        $voltperstep/$voltpersec : # ignore $steppersec
        1/$steppersec;             # ignore $voltpersec
    my $step=$voltperstep * ($voltage <=> $last_v);
    
    #wait if necessary
    my ($ns,$nmu)=gettimeofday();
    my $now=$ns*1e6+$nmu;
    unless (defined (my $last_t=$self->{_gp}->{last_settime_mus})) {
        $self->{_gp}->{last_settime_mus}=$now;
    } elsif ( $now-$last_t < 1e6*$wait ) {
        usleep ( ( 1e6*$wait+$last_t-$now ) );
        ($ns,$nmu)=gettimeofday();
        $now=$ns*1e6+$nmu;
    } 
    $self->{_gp}->{last_settime_mus}=$now;
    
    #do one step
    if (abs($voltage-$last_v) > abs($step)) {
        $voltage=$last_v+$step;
    }
    $voltage=0+sprintf("%.10f",$voltage);
    
    $self->_set_voltage($voltage);
    $self->{_gp}->{last_voltage}=$voltage;
    return $voltage;
}

sub sweep_to_voltage {
    my $self=shift;
    my $voltage=shift;

    my $last;
    my $cont=1;
    while($cont) {
        $cont=0;
        my $this=$self->step_to_voltage($voltage);
        if (!(defined $last) || (abs($last-$this) > 1e-5)) {
            $last=$this;
            $cont++;
        }
    }; #ugly
    return $voltage;
}

sub _set_voltage {
    warn '_set_voltage not implemented for this instrument';
}

sub get_voltage {
    my $self=shift;
    my $voltage=$self->_get_voltage(@_);
    $self->{_gp}->{last_voltage}=$voltage;
    return $voltage;
}

sub _get_voltage {
    warn '_get_voltage not implemented for this instrument';
}

sub get_range() {
    warn 'get_range not implemented for this instrument';
}

sub set_range() {
    warn 'set_range not implemented for this instrument';
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
