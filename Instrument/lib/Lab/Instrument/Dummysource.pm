#$Id$

package Lab::Instrument::Dummysource;
use strict;
use Lab::Instrument::Source;

our $VERSION="1.21";

our @ISA=('Lab::Instrument::Source');
our $maxchannels=16;

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
    for (my $i=1; $i<=$maxchannels; $i++) {
      my $tmp="last_volt_$i";
      $self->{$tmp}=0;
      my $tmp="last_range_$i";
      $self->{$tmp}=1;
    }
    return $self
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;
    my $tmp="last_volt_$channel";
    $self->{$tmp}=$voltage;
    print "DS: _setting virtual voltage $channel to $voltage\n";
}

sub _get_voltage {
    my $self=shift;
    my $channel=shift;
    my $tmp="last_volt_$channel";
    print "DS: _getting virtual voltage $channel: $$self{$tmp}\n";
    return $self->{$tmp};
}

sub set_range {
    my $self=shift;
    my $range=shift;
    my $channel=shift;
    my $tmp="last_range_$channel";
    $self->{$tmp}=$range;
    print "DS: setting virtual range of channel $channel to $range\n";
}

sub get_range {
    my $self=shift;
    my $channel=shift;
    my $tmp="last_range_$channel";
    print "DS: getting virtual range: $$self{$tmp}\n";
    return $self->{$tmp};
}

1;

=head1 NAME

Lab::Instrument::Dummysource - Dummy voltage source

=head1 DESCRIPTION

The Lab::Instrument::Dummysource class implements a dummy voltage source
that does nothing but fullfill testing purposes.

Only developers will ever make use of this class.

=head1 SEE ALSO

=over 4

=item (L<Lab::Instrument::Source>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2005-2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
