#$Id$
package Lab::Instrument::TemperatureControl;
use strict;

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    %{$self->{default_config}}=%{shift @_};
    %{$self->{config}}=%{$self->{default_config}};
    $self->configure(@_);

	# preset some sane values for device protection
    $self->{config}->{min_temp}=0.05;
    $self->{config}->{max_temp}=1;
    $self->{config}->{temp_tolerance}=5;

	print "The TemperatureControl module is still heavily under development and does not work at all so far.\n";
    return $self;
}

sub configure {
    my $self=shift;

    #supported config options are (so far)
    #   max_temp		maximum safe temperature
    #   min_temp		minumim reachable temperature
	#   temp_tolerance	temperature tolerance in percent

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

sub set_temp {
    my $self=shift;
	my $temp=shift;
	
	if ($temp>$self->{config}->{max_temp}) {$temp=$self->{config}->{max_temp}; };
	if ($temp<0) {$temp=0; };
	
	$temp=$self->_set_tmp(@_);
    return $temp;
}

sub set_temp_wait {
	my $self=shift;

	my $target=$self->set_temp(@_);
	
	do {
		# and now wait for the temperature...
	
		sleep(10);
		$now=$self->get_temp();

		if (($target < $self->{config}->{min_temp}) {$target=$self->{config}->{min_temp}; };
		$diff=(abs($now-$target)/$target*100);
		
	} until ($diff <= $self->{config}->{temp_tolerance});
}

sub _set_temp {
    warn '_set_temp not implemented for this instrument';
}

sub get_temp
    my $self=shift;
    my $temp=$self->_get_temp(@_);
    return $temp;
}

sub _get_temp {
    warn '_get_temp not implemented for this instrument';
}



1;

