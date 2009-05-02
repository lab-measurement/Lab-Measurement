#$Id$
package Lab::Instrument::MagnetSupply;
use strict;

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    %{$self->{default_config}}=%{shift @_};

    $self->{default_config}->{field_constant}=0;
    $self->{default_config}->{max_current}=1;
    $self->{default_config}->{max_sweeprate}=0.001;
    $self->{default_config}->{max_sweeprate_persistent}=0.001;
    $self->{default_config}->{has_heater}=1;
    $self->{default_config}->{heater_delaytime}=20;
    $self->{default_config}->{can_reverse}=0;
    $self->{default_config}->{can_use_negative_current}=0;
    $self->{default_config}->{use_persistentmode}=0;

    %{$self->{config}}=%{$self->{default_config}};

    $self->configure(@_);

    return $self;
}

sub configure {
    my $self=shift;
    #supported config options are (so far)
	#	field_constant (T/A)
	#	max_current (A)
	#	max_sweeprate (A/s)
	#	max_sweeprate_persistent (A/s)
	#	has_heater (0/1)
	#	heater_delaytime (s)
	#	can_reverse (0/1)
	#	can_use_negative_current (0/1)
	#	use_persistentmode (0/1)
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

