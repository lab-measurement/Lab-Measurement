package Lab::Instrument::DummySource;
our $VERSION = '2.93';

use strict;
use Lab::Instrument::Source;

our @ISA=('Lab::Instrument::Source');
our $maxchannels=16;

my %fields = (
	supported_connections => [ 'none' ],

	device_settings => {
		gate_protect            => 1,
		gp_equal_level          => 1e-5,
		gp_max_volt_per_second  => 0.002,
		gp_max_volt_per_step    => 0.001,
		gp_max_step_per_second  => 2,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
	},
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	# already called in Lab::Instrument::Source, but call it again to respect default values in local channel_defaultconfig
	$self->configure($self->config());
	$self->device_settings($self->config('device_settings')) if defined $self->config('device_settings') && ref($self->config('device_settings')) eq 'HASH';

    print "DS: Created dummy instrument with config\n";
    while (my ($k,$v)=each %{$self->device_settings}) {
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
    my $args={@_};
    my $channel = $args->{'channel'} || $self->default_channel();

    my $tmp="last_volt_$channel";
    $self->{$tmp}=$voltage;
    print "DS: _setting virtual voltage $channel to $voltage\n";
    return $voltage;
}

sub _get_voltage {
    my $self=shift;
    my $args={@_};
    my $channel = $args->{'channel'} || $self->default_channel();

    my $tmp="last_volt_$channel";
    print "DS: _getting virtual voltage $channel: $$self{$tmp}\n";
    return $self->{$tmp};
}

sub set_range {
    my $self=shift;
    my $range=shift;
    my $args={@_};
    my $channel = $args->{'channel'} || $self->default_channel();

    my $tmp="last_range_$channel";
    $self->{$tmp}=$range;
    print "DS: setting virtual range of channel $channel to $range\n";
}

sub get_range {
    my $self=shift;
    my $args={@_};
    my $channel = $args->{'channel'} || $self->default_channel();

    my $tmp="last_range_$channel";
    print "DS: getting virtual range: $$self{$tmp}\n";
    return $self->{$tmp};
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::DummySource - Dummy voltage source

=head1 DESCRIPTION

The Lab::Instrument::DummySource class implements a dummy voltage source
that does nothing but can be used for testing purposes.

Only developers will ever make use of this class.

=head1 SEE ALSO

=over 4

=item (L<Lab::Instrument::Source>).

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2005-2006 Daniel Schröer (L<http://www.danielschroeer.de>)
            2011      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
