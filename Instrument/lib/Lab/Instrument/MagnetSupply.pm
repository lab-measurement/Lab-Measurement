#$Id$
package Lab::Instrument::MagnetSupply;
use strict;

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $default_config = shift;

    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;

    warn "WARNING: Using MagnetSupply.pl version $VERSION, still in testing phase!!!\n";

    $self->{default_config}->{has_teslamode}=0;
    $self->{default_config}->{use_teslamode}=0;
    $self->{default_config}->{hse_persistentmode}=0;
    $self->{default_config}->{use_persistentmode}=0;
    $self->{default_config}->{heater_delaytime}=60;
    $self->{default_config}->{can_reverse}=0;
    $self->{default_config}->{can_use_negative_current}=0;
    $self->{default_config}->{field_constant}=0;
    $self->{default_config}->{max_current}=1;
    $self->{default_config}->{max_field}=0.1;
    $self->{default_config}->{max_sweeprate}=0.001;
    $self->{default_config}->{max_sweeprate_persistent}=0.001;

    for (keys %{$default_config}) {
        $self->{default_config}->{$_}=$default_config->{$_};
    }

    %{$self->{config}}=%{$self->{default_config}};

    $self->configure(@_);

    return $self;
}

sub configure {
    my $self=shift;

    #supported config options are (so far)
	#	has_teslamode (0/1)
	#	use_teslamode (0/1)
	#	has_persistentmode (0/1)
	#	use_persistentmode (0/1)
	#	heater_delaytime (s)
	#	can_reverse (0/1)
	#	can_use_negative_current (0/1)
	#	field_constant (T/A)
	#	max_current (A)
	#	max_field (T)
	#	max_sweeprate (A/s)
	#	max_sweeprate_persistent (A/s)

    #   
    my $config=shift;
    if ((ref $config) =~ /HASH/) {
        for my $conf_name (keys %{$self->{default_config}}) { # only parameters in default_config are allowed
            # print "Key: $conf_name, default: ",$self->{default_config}->{$conf_name},", old config: ",$self->{config}->{$conf_name},", new config: ",$config->{$conf_name},"\n";
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

sub postinit {
    my $self=shift;

    # this has to be called after the complete initialization of the sub-class, in its constructor
    print "running postinit\n";

    # if a feature is not present, it can not be used
    $self->{config}->{use_teslamode}*=$self->{config}->{has_teslamode};
    $self->{config}->{use_persistentmode}*=$self->{config}->{has_persistentmode};

    if ($self->{config}->{use_teslamode}) {

	# we are using tesla commands and trusting the PSU field constant

    } else {

        # we are using ampere commands and the user-supplied field constant


    };

};



sub ItoB {
	my $self=shift;
	my $current=shift;

	my $fconst=$self->{config}->{field_constant};

	if ($fconst==0) { 
	  die "Field constant not defined!!!\n";
	};
	
	return($fconst*$current);
}


sub BtoI {
	my $self=shift;
	my $field=shift;

	my $fconst=$self->{config}->{field_constant};

	if ($fconst==0) { 
	  die "Field constant not defined!!!\n";
	};
	
	return($field/$fconst);
}

	
sub set_field {
    my $self=shift;
    my $field=shift;
	
    my $current=$self->BtoI($field);

    $field=$self->ItoB($self->set_current($current));
    return $field;
}


sub set_current {
    my $self=shift;
    my $current=shift;

    if ($current>$self->{config}->{max_current}) {
		$current=$self->{config}->{max_current};
    };
	
    if ($current<0) {
	if ($self->{config}->{can_reverse}) {

	    if ($self->{config}->{can_use_negative_current}) {
		
		    if ($current<-$self->{config}->{max_current}) {
			$current=-$self->{config}->{max_current};
		    };
		
	    } else {

        	   die "reverse current not supported yet\n";
		
    	    };
	    
		
	    
	    
	} else {
    	   die "reverse current not supported\n";
	}
	
    };

    $self->_set_sweeprate($self->{config}->{max_sweeprate});
	

    if ($self->{config}->{can_use_negative_current}) {
	
	$self->_set_sweep_target_current($current);
	
    } else {
	
	die "not supported yet\n";
	
    }
    
    $self->_set_hold(0);
    
    while (abs($self->get_current()-$current)>0.2) {
       sleep(10);
    };    
}


sub start_sweep_to_field {
    my $self=shift;
    my $field=shift;
    $self->start_sweep_to_current($self->BtoI($field));
}




sub start_sweep_to_current {
    my $self=shift;
    my $current=shift;

    if ($current>$self->{config}->{max_current}) {
		$current=$self->{config}->{max_current};
    };
	
    if ($current<0) {
	if ($self->{config}->{can_reverse}) {

	    if ($self->{config}->{can_use_negative_current}) {
		
		    if ($current<-$self->{config}->{max_current}) {
			$current=-$self->{config}->{max_current};
		    };
		
	    } else {

        	   die "reverse current not supported yet\n";
		
    	    };
	    
		
	    
	    
	} else {
    	   die "reverse current not supported\n";
	}
	
    };

    $self->_set_sweeprate($self->{config}->{max_sweeprate});
	

    if ($self->{config}->{can_use_negative_current}) {
	
	$self->_set_sweep_target_current($current);
	
    } else {
	
	die "not supported yet\n";
	
    }
    
    $self->_set_hold(0);
    
}




sub get_field {
    my $self=shift;
    return $self->ItoB($self->_get_current());
}


sub get_current {
    my $self=shift;
    return $self->_get_current();
}









sub _get_current {
    die '_get_current not implemented for this instrument';
}

sub _set_sweep_target_current {
    die '_set_sweep_target_current not implemented for this instrument';
}

sub _set_hold {
    die '_set_hold not implemented for this instrument';
}

sub _get_hold {
    die '_get_hold not implemented for this instrument';
}

sub _set_heater {
    die '_set_heater not implemented for this instrument';
}

sub _get_heater {
    die '_get_heater not implemented for this instrument';
}

sub _set_sweeprate {
    die '_set_sweeprate not implemented for this instrument';
}

sub _get_sweeprate {
    die '_get_sweeprate not implemented for this instrument';
}



1;




=head1 NAME

Lab::Instrument::MagnetSupply - Base class for superconducting magnet power supplies

=head1 SYNOPSIS

=head1 DESCRIPTION

This class implements a general superconducting magnet current supply unit.
It is meant to be inherited by instrument classes (virtual instruments) that 
implement access to real hardware (i.e. the IPS 120-10).

The class provides a unified user interface for those power supply units
to support the exchangeability of instruments.

Additionally, it supplies the generic progamming logic to handle Ampere/Tesla
conversion, sweeping and setting the magnetic field, reversing the field direction
and (with a few safety measures) handling a persistent mode switch. 

As a user you are NOT supposed to create instances of this class, but rather
instances of instrument classes that internally use this module!

=head1 CONSTRUCTOR

  $self=new Lab::Instrument::MagnetSupply(\%default_config,\%config);

The constructor will only be used by instrument drivers that inherit this class,
not by the user.

The instrument driver has a constructor like this:

  $magnet=new Lab::Instrument::IPS12010new({
    GPIB_board      => $board,
    GPIB_address    => $address,
    [...]
  });

=head1 METHODS

=head2 configure

  $self->configure(\%config);

Supported configure options define generic characteristics of the power supply unit and the magnet.

=over 2

=item has_teslamode

Defines whether the power supply unit can handle Ampere to Tesla conversion in itself, i.e. 
persistently store the field constant and accept/output Tesla values instead of Ampere values
in commands and on the panel. Defaults to 0, and should be set by the instrument driver, 
not by the user.

=item use_teslamode

Sets whether the device should be controlled using Tesla or Ampere values, and (if possible) whether
it should display Tesla or Ampere on the front panel. use_teslamode=1 obviously requires has_teslamode=1. 

(Not implemented yet.) This configuration setting influences many code paths. 

For use_teslamode=0, the user has to supply a field constant value. Field values are converted to
current values in software, and the power supply unit is controlled using these current values alone. 

For use_teslamode=1, the power supply unit is on initialization queried for the field constant. If
this succeeds, all control and query commands will directly use Tesla values. The field constant 
is implicitly trusted; remember this if you switch magnets!

=item has_persistentmode

Defines whether a persistent mode switch and heater is installed. 

=item use_persistentmode

(Not implemented yet.)

=item heater_delaytime

Defines how much settling time is required after activating or deactivating the persistent mode
switch heater. A very conservative default value is provided; better values can be set by the user. 

=item can_reverse

Defines whether the power supply unit can in principle reverse the current direction. 
This should be set by the instrument driver. 

=item can_use_negative_current

Defines whether the command set of the power supply unit accepts negative current or field
values as "reverse current", and handles the required sweep internally. If the power supply unit 
can supply a reverse current, but can NOT handle negative current/field values, the current will
be ramped to zero, a polarity switch command will be issued, and the current will be ramped 
to the new value. (This case is not implemented yet.)

=item field_constant

Field constant in Tesla/Ampere. For use_teslamode=0, this has to be supplied by the user on 
initialization. For use_teslamode=1, the value is queried from the power supply unit. 

=item max_current

Maximum allowed current in Ampere for the magnet. For use_teslamode=1, this is calculated from max_field. 
Otherwise, the value should be set by the user.

=item max_field

Maximum allowed field in Tesla for the magnet. For use_teslamode=0, this is calculated from max_current. 
Otherwise, the value should be set by the user. 

=item max_sweeprate

Maximum allowed sweep rate for the magnet current, in Ampere/second. This should be set by the user; if
not the pre-set sweep rate will remain unchanged.

=item max_sweeprate_persistent

Maximum allowed sweep rate for the lead current, in Ampere/second, while the magnet is in persistent
mode. This should be set by the user; if not, the pre-set sweep rate will remain unchanged.


=back

=head2 set_field

  $new_field=$self->set_field($field);

Sets the magnet field to C<$field> (in Tesla). This means starting a sweep to this value
and waiting until the target is reached. In case current reversal is supported, an opposite
field direction can be specified by a negative field value. 

Not implemented yet for use_persistent_mode=1.

Returns the reached field value, which can differ from the target value due to safety 
limitations or rounding errors. 

=head2 set_current

  $new_current=$self->set_current($current);

Sets the magnet current to C<$current> (in Ampere). This means starting a sweep to this value
and waiting until the target is reached. In case current reversal is supported, an opposite
current direction can be specified by a negative current value. 

Not implemented yet for use_persistent_mode=1.

Returns the reached current value, which can differ from the target value due to safety 
limitations or rounding errors. 

=head2 start_sweep_to_field

  $self->start_sweep_to_field($field);

Sets the sweep target to C<$field> (in Tesla), and starts the sweep with the currently set 
sweep speed. In case current reversal is supported, an opposite
field direction can be specified by a negative field value. 

=head2 start_sweep_to_current

  $self->start_sweep_to_current($current);

Sets the sweep target to C<$current> (in Ampere), and starts the sweep with the currently set 
sweep speed. In case current reversal is supported, an opposite
current direction can be specified by a negative current value. 

=head2 get_field

  $field=$self->get_field();

Returns the current magnet field. A negative value indicates reversed field polarity.

=head2 get_current

  $current=$self->get_current();

Returns the current magnet current. A negative value indicates reversed current direction.


=head1 CAVEATS/BUGS

Probably many. This is still heavily work in progress, and features are added on a day-to-day basis. 
Many possible safety checks are not implemented yet. In particular right now we are assuming that the 
persistent mode switch heater is continuously on!!!

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument::IPS12010new>

The first real device driver based on this class. 

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$
Based on Source.pm

Copyright 2004-2009 Daniel Schröer (L<http://www.danielschroeer.de>)
          2009      Andreas K Hüttel (L<http://www.akhuettel.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
