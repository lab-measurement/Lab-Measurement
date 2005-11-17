#$Id$
package Lab::Instrument::Source;
use strict;
use Time::HiRes qw(usleep gettimeofday);

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    %{$self->{default_config}}=%{shift @_};
    $self->configure(@_);

    $self->{_gp}->{last_voltage}=undef;
    $self->{_gp}->{last_settime_mus}=undef;
    
    return $self;
}

sub configure {
    my $self=shift;
    
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
        # DIESES VERHALTEN IST FALSCH!
        # so kann man nie einfach selbst einen (sicheren) Schritt tun
        # ?vielleicht auch nicht? Angelegenheit von sweep
        $self->sweep_to_voltage($voltage);
    } else {
        $self->_set_voltage($voltage);
    }
}

sub step_to_voltage {
    my $self=shift;
    my $voltage=shift;
    
    my $mpsec=$self->{config}->{gp_max_volt_per_second};
    my $mpstep=$self->{config}->{gp_max_volt_per_step};

    my $last_v=$self->{_gp}->{last_voltage};
    my $last_t=$self->{_gp}->{last_settime_mus};
    
    unless (defined $last_v) {
        $last_v=$self->get_voltage();
        $self->{_gp}->{last_voltage}=$last_v;
    }

    my ($ns,$nmu)=gettimeofday();
    my $now=$ns*1e6+$nmu;
    
    #wait if necessary
    unless (defined $last_t) {
        $self->{_gp}->{last_settime_mus}=$now;
        $last_t=$now;
    } elsif (($last_t-$now)<(1e6*($mpstep/$mpsec))) {
        usleep ( ( 1e6*($mpstep/$mpsec) - ($last_t-$now) ));
    }
    
    ($ns,$nmu)=gettimeofday();
    $now=$ns*1e6+$nmu;
    $self->{_gp}->{last_settime_mus}=$now;
    $last_t=$now;

    #do one step
    if (abs($voltage-$last_v) > $mpstep) {
        my $next_voltage=$last_v+$mpstep*(($voltage>$last_v) ? 1 : -1);
        $self->_set_voltage($next_voltage);
        $self->{_gp}->{last_voltage}=$next_voltage;
        return "not arrived";
    } else {
        $self->_set_voltage($voltage);
        $self->{_gp}->{last_voltage}=$voltage;
        return "arrived";
    }
}

sub sweep_to_voltage {
    my $self=shift;
    my $voltage=shift;

    while ($self->step_to_voltage($voltage) !~ /^arrived/) {};
}

sub _set_voltage {
    warn '_set_voltage not implemented for this instrument';
}

sub get_voltage {
    warn 'get_voltage not implemented for this instrument';
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

OUTDATED: This class extends the L<Lab::Instrument::Source> class. It is meant to be
inherited by instrument classes (virtual instruments), that implement voltage
sources (e.g. the L<Lab::Instrument::Yokogawa7651> class).

OUTDATED: The Lab::Instrument::SafeSource class extends the L<Lab::Instrument::Source>
class to provide a sweep rate limitation mechanism, to protect sensible samples.
Blabla.

OUTDATED: From the view of an author of new instruments classes, there is no difference
between inheriting from Lab::Instrument::Source and Lab::Instrument::SafeSource.
The same methods have to be implemented. See Lab::Instrument::Source for details.
The only difference is the additional protection mechanism, which can also be
turned off.

=head1 CONSTRUCTORS

    $self=new Lab::Instrument::SafeSource($default_config,\%options);

=head1 METHODS

=head2 configure

    $self->configure(\%config);

The available options and default settings look like this:

    $default_config={
        gate_protect           => 1,
        gp_max_volt_per_step   => 0.001,
        gp_max_volt_per_second => 0.002
    };

=head2 set_voltage

    $self->set_voltage($voltage);

This is the protected version of the set_voltage() method. It takes into account the
gp_max_volt_per_step and gp_max_volt_per_second settings, by employing the sweep_to_voltage()
method.

=head2 sweep_to_voltage

    $self->sweep_to_voltage($voltage);

This method sweeps the output voltage to the desired value. The voltage is changed with
the maximum speed and granularity, that the gp_max_volt_per_step and
gp_max_volt_per_second settings allow.

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item Lab::Instrument::Source

The Lab::Instrument::SafeSource class inherits from the L<Lab::Instrument::Source> module.

=item Time::HiRes

The Lab::Instrument::SafeSource class uses the L<Time::HiRes> module.

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
