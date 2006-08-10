#$Id$

package Lab::Instrument::Dummysource;
use strict;
use Lab::Instrument::Source;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

our @ISA=('Lab::Instrument::Source');

my $default_config={
    gate_protect            => 1,
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
    gp_max_step_per_second  => 2,
    gp_min_volt             => -1,
    gp_max_volt             => 1,
    gp_equal_level          => 0.000001,
};

sub new {
    my $proto = shift;
    my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($default_config,@args);
    bless ($self, $class);
    print "DS: Created dummy instrument with config\n";
    while (my ($k,$v)=each %{$self->configure()}) {
        print "DS:   $k -> $v\n";
    }
    $self->{last_volt}=0;
    $self->{last_range}=1;
    return $self
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    $self->{last_volt}=$voltage;
    print "DS: _setting virtual voltage to $voltage\n";
}

sub _get_voltage {
    my $self=shift;
    print "DS: _getting virtual voltage: $$self{last_volt}\n";
    return $self->{last_volt};
}

sub set_range {
    my $self=shift;
    my $range=shift;
    $self->{last_range}=$range;
    print "DS: setting virtual range to $range\n";
}

sub get_range {
    my $self=shift;
    print "DS: getting virtual range: $$self{last_range}\n";
    return $self->{last_range};
}

1;

=head1 NAME

Lab::Instrument::Dummysource - Dummy voltage source

=head1 DESCRIPTION

The Lab::Instrument::Dummysource class implements a dummy voltage source
that does nothing but fullfill testing purposes.

Only developers can make use of this class.

=head1 SEE ALSO

=over 4

=item (L<Lab::Instrument::Source>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2005-2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
