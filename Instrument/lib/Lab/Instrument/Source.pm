package Lab::Instrument::Source;
use strict;
use Time::HiRes qw(usleep gettimeofday);
use Lab::Exception;
use Lab::Instrument;
use Data::Dumper;
#use diagnostics;

our $maxchannels = 16;

our @ISA=('Lab::Instrument');

my %fields = (
	supported_connections => [],

	parent_source => undef,
	child_sources => [],

	# supported config options
	device_settings => {
		gate_protect => undef,
		gp_max_volt_per_second => undef,
		gp_max_volt_per_step => undef,
		gp_max_step_per_second => undef,
		gp_min_volt => undef,
		gp_max_volt => undef,
		gp_equal_level => undef,
		fast_set => undef,
	},

	# Config hash passed to subchannel objects, or to $self->configure()
	default_device_settings => {},

	gpData => {},

	default_channel => 1,
	max_channels => 1,
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);	# sets $self->config
	$self->_construct(__PACKAGE__, \%fields); 	# this sets up all the object fields out of the inheritance tree.
												# also, it does generic bus setup.

	#
	# Parameter parsing
	#

	# checking and saving the default config hash, if any
	if(defined($self->config('default_device_settings'))) {
		if( ref($self->config('default_device_settings')) !~ /HASH/ ) {
			Lab::Exception::CorruptParameter->throw('Given default config is not a hash.' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));
		}
		$self->default_device_settings($self->config('default_device_settings'));
	}
	else {
		$self->default_device_settings($self->config());
	}

	# check max channels
	if(defined($self->config('max_channels'))) {
		if( $self->config('max_channels') !~ /^[0-9]*$/ ) {
			Lab::Exception::CorruptParameter->throw('Parameter max_channels has to be an Integer' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));
		}
		else { $self->max_channels($self->config('max_channels')); }
	}

	# checking default channel number
	if( defined($self->config('default_channel')) && ( $self->config('default_channel') > $self->max_channels() || $self->config('default_channel') < 1 )) {
		Lab::Exception::CorruptParameter->throw('Default channel number is not within the available channels.' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));
	}

	$self->configure($self->config());

	$self->default_channel($self->config('default_channel')) if defined($self->config('default_channel'));

	if(defined($self->config('parent_source'))) {
		if( !UNIVERSAL::isa($self->config('parent_source'),"Lab::Instrument::Source" ) ) {
			Lab::Exception::CorruptParameter->throw('Given parent_source object is not a valid Lab::Instrument::Source.' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));
		}
		# instead of maintaining our own one, use a reference to the gpData from the parent object
		if( !defined($self->config('gpData')) || ! ref($self->config('gpData')) =~ /HASH/ )  {
			Lab::Exception::CorruptParameter->throw('Given gpData from parent_source is invalid.' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));
		}
	
		$self->parent_source($self->config('parent_source'));
		$self->gpData($self->config('gpData'));
	}
	else {
		# fill gpData
		for (my $i=1; $i<=$self->max_channels(); $i++) {
			$self->gpData()->{$i} = { LastVoltage => undef, LastSettimeMus => undef };
		}
	}

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
    #   qp_equal_level
    #   fast_set
	#
	#   ... and, in general, all parameters which can be changed by access methods of the objects
	#   (in fact this is what happens, and the config hash given to configure() ist just a shorthand for e.g.
	#   $source->gate_protect(1);
	#   $source->gp_max_volt_per_second(0.1);
	#   ...
	#   equivalent: $source->configure({ gate_protect=>1, gp_max_volt_per_second=>0.1, ...)
    my $config=shift;
	if( ref($config) !~ /HASH/ ) {
		Lab::Exception::CorruptParameter->throw('Given Configuration is not a hash.' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__));
	}
	else {
        for my $conf_name (keys %{$self->device_settings()}) {
            #print "Key: $conf_name, default: ",$self->{default_config}->{$conf_name},", old config: ",$self->{config}->{$conf_name},", new config: ",$config->{$conf_name},"\n";
			if( defined($config->{$conf_name}) ) {		# in given config? => set value
				print "Setting $conf_name to $config->{$conf_name}\n";
				$self->device_settings()->{$conf_name} = $config->{$conf_name};
			}
			elsif( defined($self->default_device_settings()->{$conf_name}) ) {	# or in default config? => set value
				print "Setting $conf_name to " . $self->default_device_settings()->{$conf_name} ."\n";
				$self->device_settings()->{$conf_name} = $self->default_device_settings()->{$conf_name};
			}
		}
    }
	return $self; # what for? let's not break something...
}

sub GetSubSource { #{ Channel=>2, config1=>fasl, config2=>foo };
	my $self=shift;
	my $class = ref($self);
	my $constructor = "${class}::new";
	my $subsource = &$constructor({ Bus=>$self->Bus(), parent_source=>$self, gpData=>$self->gpData(), %{$self->default_device_settings()} });
	$self->child_sources([ @{$self->child_sources}, $subsource ]);
	return $subsource;
}




sub set_voltage {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    if ($self->device_settings()->{gate_protect}) {
        $voltage=$self->sweep_to_voltage($voltage,$channel);
    } else {
        $self->_set_voltage($voltage,$channel);
    }
 
    my $result;
    if ($self->device_settings()->{fast_set}) {
        $result=$voltage;
    } else {
        $result=$self->get_voltage($channel);
    }

    $self->gpData()->{$channel}->{LastVoltage}=$result;
    return $result;
}

sub set_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel ) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    if ($self->device_settings()->{gate_protect}) {
        $voltage=$self->sweep_to_voltage_auto($voltage,$channel);
    } else {
        $self->_set_voltage_auto($voltage,$channel);
    }
    
    my $result;
    if ($self->device_settings()->{fast_set}) {
        $result=$voltage;
    } else {
        $result=$self->get_voltage($channel);
    }

    $self->gpData()->{$channel}->{LastVoltage}=$result;
    return $result;
}


sub step_to_voltage {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    my $voltpersec=abs($self->device_settings()->{gp_max_volt_per_second});
    my $voltperstep=abs($self->device_settings()->{gp_max_volt_per_step});
    my $steppersec=abs($self->device_settings()->{gp_max_step_per_second});

    #read output voltage from instrument (only at the beginning)

    my $last_v=$self->gpData()->{$channel}->{LastVoltage};
    unless (defined $last_v) {
        $last_v=$self->get_voltage($channel);
        $self->gpData()->{$channel}->{LastVoltage}=$last_v;
    }

    if (defined($self->device_settings()->{gp_max_volt}) && ($voltage > $self->device_settings()->{gp_max_volt})) {
        $voltage = $self->device_settings()->{gp_max_volt};
    }
    if (defined($self->device_settings()->{gp_min_volt}) && ($voltage < $self->device_settings()->{gp_min_volt})) {
        $voltage = $self->device_settings()->{gp_min_volt};
    }

    #already there
    return $voltage if (abs($voltage - $last_v) < $self->device_settings()->{gp_equal_level});

    #are we already close enough? if so, screw the waiting time...
    if ((defined $voltperstep) && (abs($voltage - $last_v) < $voltperstep)) {
        $self->_set_voltage($voltage,$channel);
        $self->gpData()->{$channel}->{LastVoltage}=$voltage;
       return $voltage;       
    }    

    #do the magic step calculation
    my $wait = ($voltpersec < $voltperstep * $steppersec) ?
        $voltperstep/$voltpersec : # ignore $steppersec
        1/$steppersec;             # ignore $voltpersec
    my $step=$voltperstep * ($voltage <=> $last_v);
    #wait if necessary
    my ($ns,$nmu)=gettimeofday();
    my $now=$ns*1e6+$nmu;

    unless (defined (my $last_t=$self->gpData()->{$channel}->{LastSettimeMus})) {
        $self->gpData()->{$channel}->{LastSettimeMus}=$now;
    } elsif ( $now-$last_t < 1e6*$wait ) {
        usleep ( ( 1e6*$wait+$last_t-$now ) );
        ($ns,$nmu)=gettimeofday();
        $now=$ns*1e6+$nmu;
    } 
    $self->gpData()->{$channel}->{LastSettimeMus}=$now;
    
    #do one step
    if (abs($voltage-$last_v) > abs($step)) {
        $voltage=$last_v+$step;
    }
    $voltage=0+sprintf("%.10f",$voltage);
    
    $self->_set_voltage($voltage,$channel);
    $self->gpData()->{$channel}->{LastVoltage}=$voltage;
    return $voltage;
}

sub step_to_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    my $voltpersec=abs($self->device_settings()->{gp_max_volt_per_second});
    my $voltperstep=abs($self->device_settings()->{gp_max_volt_per_step});
    my $steppersec=abs($self->device_settings()->{gp_max_step_per_second});

    my $last_v=$self->gpData()->{$channel}->{LastVoltage};
    unless (defined $last_v) {
        $last_v=$self->get_voltage($channel);
        $self->gpData()->{$channel}->{LastVoltage}=$last_v;
    }

    if (defined($self->device_settings()->{gp_max_volt}) && ($voltage > $self->device_settings()->{gp_max_volt})) {
        $voltage = $self->device_settings()->{gp_max_volt};
    }
    if (defined($self->device_settings()->{gp_min_volt}) && ($voltage < $self->device_settings()->{gp_min_volt})) {
        $voltage = $self->device_settings()->{gp_min_volt};
    }

    #already there
    return $voltage if (abs($voltage - $last_v) < $self->device_settings()->{gp_equal_level});

    #do the magic step calculation
    my $wait = ($voltpersec < $voltperstep * $steppersec) ?
        $voltperstep/$voltpersec : # ignore $steppersec
        1/$steppersec;             # ignore $voltpersec
    my $step=$voltperstep * ($voltage <=> $last_v);
    
    #wait if necessary
    my ($ns,$nmu)=gettimeofday();
    my $now=$ns*1e6+$nmu;

    unless (defined (my $last_t=$self->gpData()->{$channel}->{LastSettimeMus})) {
        $self->gpData()->{$channel}->{LastSettimeMus}=$now;
    } elsif ( $now-$last_t < 1e6*$wait ) {
        usleep ( ( 1e6*$wait+$last_t-$now ) );
        ($ns,$nmu)=gettimeofday();
        $now=$ns*1e6+$nmu;
    } 
    $self->gpData()->{$channel}->{LastSettimeMus}=$now;
    
    #do one step
    if (abs($voltage-$last_v) > abs($step)) {
        $voltage=$last_v+$step;
    }
    $voltage=0+sprintf("%.10f",$voltage);
    
    $self->_set_voltage_auto($voltage,$channel);
    $self->gpData()->{$channel}->{LastVoltage}=$voltage;
    return $voltage;
}


sub sweep_to_voltage {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    my $last;
    my $cont=1;
    while($cont) {
        $cont=0;
        my $this=$self->step_to_voltage($voltage,$channel);
        unless ((defined $last) && (abs($last-$this) < $self->device_settings()->{gp_equal_level})) {
            $last=$this;
            $cont++;
        }
    }; #ugly
    return $voltage;
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    if ($self->parent_source()) {
        return $self->parent_source()->_set_voltage($voltage, $channel);
    } else {
    warn '_set_voltage not implemented for this instrument';
    };
}

sub _set_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    if ($self->parent_source()) {
        return $self->parent_source()->_set_voltage_auto($voltage, $channel);
    } else {
    warn '_set_voltage_auto not implemented for this instrument';
    };
}

sub get_voltage {
    my $self=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    my $voltage=$self->_get_voltage($channel);
    $self->gpData()->{$channel}->{LastVoltage}=$voltage;
    return $voltage;
}

sub _get_voltage {
    my $self=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    if ($self->parent_source()) {
        return $self->parent_source()->_get_voltage($channel);
    } else {
    warn '_get_voltage not implemented for this instrument';
    };
}

sub get_range() {
    my $self=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    if ($self->parent_source()) {
        return $self->parent_source()->get_range($channel);
    } else {
    warn 'get_range not implemented for this instrument';
    };
}

sub set_range() {
    my $self=shift;
    my $range=shift;
    my $channel=shift;

    $channel = $self->default_channel() unless defined($channel);
	if ($channel < 0) { Lab::Exception::CorruptParameter->throw('Channel must not be negative! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }
	if (int($channel) != $channel) { Lab::Exception::CorruptParameter->throw('Channel must be an integer! Did you swap voltage and channel number?' . Lab::Exception::Base::Appendix(__LINE__, __PACKAGE__, __FILE__)); }

    if ($self->parent_source()) {
        return $self->parent_source()->set_range($range, $channel);
    } else {
    warn 'set_range not implemented for this instrument';
    };
}

1;

=head1 NAME

Lab::Instrument::Source - Base class for voltage source instruments

=head1 SYNOPSIS

=head1 DESCRIPTION

This class implements a general voltage source, if necessary with several channels. 
It is meant to be inherited by instrument classes (virtual instruments) that implement
real voltage sources (e.g. the L<Lab::Instrument::Source::Yokogawa7651|Lab::Instrument::Source::Yokogawa7651> class).

The class provides a unified user interface for those virtual voltage sources
to support the exchangeability of instruments.

Additionally, this class provides a safety mechanism called C<gate_protect>
to protect delicate samples. It includes automatic limitations of sweep rates,
voltage step sizes, minimal and maximal voltages.

The only user application of this class is to define a voltage source object
which represents a single channel of a multi-channel voltage source. 
Otherwise, you will always have to instantiate classes derived from Lab::Instrument::Source. 

=head1 CONSTRUCTOR

  $self=new Lab::Instrument::Source({ MultiSource=><SourceObject>, Channel=><int>, ...configuration parameters, see below... });

This constructor can be used to create a source object which represents
channel C<$channel> of the multi-channel voltage source C<$multisource>.
The default configuration of this source is the configuration of C<$multisource>;
it can be partially or entirely overridden by just adding the changed config parameters.


  $self=new Lab::Instrument::Source(\%default_config,\%config);

This constructor will only be used by instrument drivers that inherit this class,
not by the user. It accepts an additional configuration hash. The first hash contains the parameters
used by default for this device and its subchannels, if any. The second hash can be used to override
options for this instance while still using the defaults for derived objects. If \%config is missing,
\%default_config is used.

The instrument driver (e.g. L<Lab::Instrument::Source::Yokogawa7651|Lab::Instrument::Source::Yokogawa7651>)
has a constructor like this:

  $yoko=new Lab::Instrument::Source::Yokogawa7651({
    GPIB_board      => $board,
    GPIB_address    => $address,
    
    gate_protect    => $gp,
    [...]
  });

=head1 METHODS

=head2 configure

  $self->configure(\%config);

Supported configure options:

In general, all parameters which can be changed by access methods of the class/object can be used.
In fact this is what happens, and the config hash given to configure() ist just a shorthand for this.
The following are equivalent:

  $source->gate_protect(1);
  $source->gp_max_volt_per_second(0.1);
  ...

  $source->configure({ gate_protect=>1, gp_max_volt_per_second=>0.1, ...)


Options in detail:

=over 2

=item fast_set

This parameter controls the return value of the set_voltage function and can be set to 0 (off, 
default) or 1 (on). For fast_set off, set_voltage first requests the hardware to set the voltage, 
and then reads out the actually set voltage via get_voltage. The resulting number is returned. 
For fast_set on, set_voltage requests the hardware to set the voltage and returns without double-check
the requested value. This, albeit less secure, may speed up measurements a lot. 

=item gate_protect

Whether to use the automatic sweep speed limitation. Can be set to 0 (off) or 1 (on).
If it is turned on, the output voltage will not be changed faster than allowed
by the C<gp_max_volt_per_second>, C<gp_max_volt_per_step> and C<gp_max_step_per_second>
values. These three parameters overdefine the allowed speed. Only two
parameters are necessary. If all three are set, the smallest allowed sweep rate
is chosen.

Additionally the maximal and minimal output voltages are limited.

This mechanism is useful to protect sensible samples that are destroyed by
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

Returns for C<fast_set> off the actually set output voltage. This can be different 
from C<$voltage>, due to the C<gp_max_volt>, C<gp_min_volt> settings. For C<fast_set> on,
C<set_voltage> returns always C<$voltage>.

For a multi-channel device, add the channel number as a parameter:

  $new_volt=$self->set_voltage($voltage,$channel);


=head2 step_to_voltage

  $new_volt=$self->step_to_voltage($voltage);
  $new_volt=$self->step_to_voltage($voltage,$channel);

Makes one safe step in direction to C<$voltage>. The output voltage is not changed by more
than C<gp_max_volt_per_step>. Before the voltage is changed, the methods waits if not
enough times has passed since the last voltage change. For step voltage and waiting time
calculation, the larger of C<gp_max_volt_per_second> or C<gp_max_step_per_second> is ignored
(see code).

Returns the actually set output voltage. This can be different from C<$voltage>, due
to the C<gp_max_volt>, C<gp_min_volt> settings.

=head2 sweep_to_voltage

  $new_volt=$self->sweep_to_voltage($voltage);
  $new_volt=$self->sweep_to_voltage($voltage,$channel);

This method sweeps the output voltage to the desired value and only returns then.
Uses the L</step_to_voltage> method internally, so all discussions of config options
from there apply too.

Returns the actually set output voltage. This can be different from C<$voltage>, due
to the C<gp_max_volt>, C<gp_min_volt> settings.

=head2 get_voltage

  $new_volt=$self->get_voltage();
  $new_volt=$self->get_voltage($channel);

Returns the voltage currently set.

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

 Copyright 2004-2008 Daniel Schr�er (<schroeer@cpan.org>)
           2009-2010 Daniel Schr�er, Andreas K. H�ttel (L<http://www.akhuettel.de/>) and Daniela Taubert

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
