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

=head1 CONSTRUCTORS

=head2 new($default_config,$config)

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_value($value)

=head2 get_value()

=head2 get_number()

=head2 get_full_range()

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item VISA::Instrument::Source

The VISA::Instrument::SafeSource class uses the L<VISA::Instrument::Source> module.

=item Time::HiRes

The VISA::Instrument::SafeSource class uses the L<Time::HiRes> module.

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
