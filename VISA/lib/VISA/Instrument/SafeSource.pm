#$Id$
package VISA::Instrument::SafeSource;
use strict;
use VISA::Instrument::Source;
use Time::HiRes;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
our @ISA=('VISA::Instrument::Source');

my $default_config={
	gate_protect			=> 1,
	gp_max_volt_per_step	=> 0.001,
	gp_max_volt_per_second	=> 0.002
};

sub new {
	my $proto = shift;
	my $def_conf=shift;
	my @args=@_;
	for my $conf_name (keys %{$def_conf}) {
		$default_config->{$conf_name}=$def_conf->{$conf_name};
	}
	
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($default_config,@_);
    bless ($self, $class);

    $self->{_gp}->{last_voltage}=undef;
    $self->{_gp}->{last_settime}=undef;
	
	return $self
}

sub set_voltage {
	my $self=shift;
	my $voltage=shift;
	
	if ($self->{config}->{gate_protect}) {
		$self->sweep_to_voltage($voltage);
	} else {
		$self->_set_voltage($voltage);
	}
}

sub sweep_to_voltage {
	my $self=shift;
	my $voltage=shift;
	
	my $mpsec=$self->{config}->{gp_max_volt_per_second};
	my $mpstep=$self->{config}->{gp_max_volt_per_step};

	unless (defined $self->{_gp}->{last_voltage}) {
		$self->{_gp}->{last_voltage}=$self->get_voltage();
	}
	unless (defined $self->{_gp}->{last_settime}) {
		my ($ns,$nmu)=Time::HiRes::gettimeofday();
		$self->{_gp}->{last_settime}=$ns*1000000+$nmu;
	}
	my ($ns,$nmu)=Time::HiRes::gettimeofday();
	my $now=$ns*1000000+$nmu;
	unless (($self->{_gp}->{last_settime}-$now)<(1000000*($mpstep/$mpsec))) {
		usleep ((1000000*($mpstep/$mpsec)-($self->{_gp}->{last_settime}-$now)));
	}
	($ns,$nmu)=Time::HiRes::gettimeofday();
	$self->{_gp}->{last_settime}=$ns*1000000+$nmu;
	
	if (abs($voltage-$self->{_gp}->{last_voltage}) > $self->{config}->{gp_max_volt_per_step}) {
		my $next_voltage=$self->{_gp}->{last_voltage}+$mpstep*($voltage>$self->{_gp}->{last_voltage}) ? 1 : -1;
		$self->_set_voltage($next_voltage);
		$self->sweep_to_voltage($voltage);
	} else {
		$self->_set_voltage($voltage);
	}
}

1;

=head1 NAME

VISA::Instrument::SafeSource - a generalised voltage source with sweep rate limitations

=head1 SYNOPSIS

=head1 DESCRIPTION

This class extends the L<VISA::Instrument::Source> class. It is meant to be
inherited by instrument classes (virtual instruments), that implement voltage
sources (e.g. the L<VISA::Instrument::Yokogawa7651> class).

The VISA::Instrument::SafeSource class extends the L<VISA::Instrument::Source>
class to provide a sweep rate limitation mechanism, to protect sensible samples.
Blabla.

From the view of an author of new instruments classes, there is no difference
between inheriting from VISA::Instrument::Source and VISA::Instrument::SafeSource.
The same methods have to be implemented. See VISA::Instrument::Source for details.
The only difference is the additional protection mechanism, which can also be
turned off.

=head1 CONSTRUCTORS

    $self=new VISA::Instrument::SafeSource($default_config,\%options);

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

=item VISA::Instrument::Source

The VISA::Instrument::SafeSource class inherits from the L<VISA::Instrument::Source> module.

=item Time::HiRes

The VISA::Instrument::SafeSource class uses the L<Time::HiRes> module.

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
