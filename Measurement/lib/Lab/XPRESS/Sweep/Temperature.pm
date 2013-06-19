package Lab::XPRESS::Sweep::Temperature;

use Lab::XPRESS::Sweep::Sweep;
use Statistics::Descriptive;
use Time::HiRes qw/usleep/;
use strict;

our @ISA=('Lab::XPRESS::Sweep::Sweep');



sub new {
    my $proto = shift;
	my @args=@_;
    my $class = ref($proto) || $proto; 
	
	# define default values for the config parameters:
	my $self->{default_config} = {
		id => 'Temperature_sweep',
		filename_extension => 'T=',
		interval	=> 1,
		points	=>	[0,10],
		duration	=> [1],
		stepwidth => 1,
		mode	=> 'continuous',
		allowed_instruments => ['Lab::Instrument::ITC'],
		allowed_sweep_modes => ['continuous', 'step', 'list'],
		
		sensor => undef,
		stabilize_measurement_interval => 1,
		stabilize_observation_time => 3*60,
		tolerance_setpoint => 0.2,
		std_dev_instrument => 0.15,
		std_dev_sensor => 0.15
		
		};
	
	
	# create self from Sweep basic class:
	$self = $class->SUPER::new($self->{default_config},@args);	
	bless ($self, $class);
	
	
	# check and adjust config values if necessary:
	$self->check_config_paramters();
	
	# init mandatory parameters:		
	$self->{DataFile_counter} = 0;	
	$self->{DataFiles} = ();
	
	
			
    return $self;
}

sub check_config_paramters {
	my $self = shift;
	
		
	# No Backsweep allowed; adjust number of Repetitions if Backsweep is 1:
	if ($self->{config}->{mode} eq 'continuous') {
		if ( $self->{config}->{backsweep} == 1 )
			{
			$self->{config}->{repetitions} /= 2;
			$self->{config}->{backsweep} = 0;
			}
		}
	
	# Set loop-Interval to Measurement-Interval:
	$self->{loop}->{interval} = $self->{config}->{interval};

}

sub start_continuous_sweep {
	my $self = shift;
	
	print "Stabilize Temperature at upper limit (@{$self->{config}->{points}}[1] K) \n";
	$self->stabilize(@{$self->{config}->{points}}[1]);
	print "Reached upper limit -> start cooling ... \n";
	$self->{config}->{instrument}->set_heatercontrol('MAN');
	$self->{config}->{instrument}->set_heateroutput(0);
}

sub go_to_next_step {
	my $self = shift;
	
	$self->stabilize(@{$self->{config}->{points}}[$self->{iterator}]);

	}

sub exit_loop {
	my $self = shift;
	
	my $TEMPERATURE;
	
	if ( $self->{config}->{mode} =~ /step|list/ )
		{	
		if (not defined @{$self->{config}->{points}}[$self->{iterator}+1])
			{
			return 1;
			}
		}
	elsif ($self->{config}->{mode} =~ /continuous/ )
		{
			if (defined $self->{config}->{sensor}) {
				$TEMPERATURE = $self->{config}->{sensor}->get_value();
			}
			else {
				$TEMPERATURE = $self->{config}->{instrument}->get_value();
			}
			if ($TEMPERATURE < @{$self->{config}->{points}}[0]) {
				return 1;
			}
			else {
				return 0;
			}
		
		}
		
	return 0;		
			
	
	
}

sub get_value {
	my $self = shift;
	return $self->{config}->{instrument}->get_value();
}

	
sub halt {
	return shift;
}

sub stabilize {
	my $self = shift;
	my $setpoint = shift;
	
	my $time0 = time();
	
	my @T_INSTR;
	my @T_SENSOR;
	
	my @MEDIAN_INSTR;
	my @MEDIAN_SENSOR;
	
	my $MEDIAN_INSTR_MEDIAN = undef;
	my $INSTR_STD_DEV = undef;
	my $SENSOR_STD_DEV = undef;
	
	my $criterion_setpoint = 0;
	my $criterion_std_dev_INSTR = 0;
	my $criterion_std_dev_SENSOR = 1;

	print "Stabilize Temperature at $setpoint K ... \n";
	$self->{config}->{instrument}->set_heatercontrol('AUTO');
	$self->{config}->{instrument}->set_T($setpoint);
	
	local $| = 1;
	
	while (1) {
	
		#----------COLLECT DATA--------------------
		my $T_INSTR = $self->{config}->{instrument}->get_value();
		push(@T_INSTR, $T_INSTR);
		
		if (scalar @T_INSTR > int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval})) {
			shift(@T_INSTR);
			
			my $stat = Statistics::Descriptive::Full->new();
			$stat->add_data(\@T_INSTR);
			my $MEDIAN_INSTR = $stat->median();
			
			push(@MEDIAN_INSTR, $MEDIAN_INSTR);
			
			if (scalar @MEDIAN_INSTR > int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval})) {
				shift(@MEDIAN_INSTR);
			}
		}
		
		if (defined $self->{config}->{sensor}) {
			my $T_SENSOR = $self->{config}->{sensor}->get_value();
			push(@T_SENSOR, $T_SENSOR);
			
			if (scalar @T_SENSOR > int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval})) {
				shift(@T_SENSOR);
				
				my $stat = Statistics::Descriptive::Full->new();
				$stat->add_data(\@T_SENSOR);
				my $MEDIAN_SENSOR = $stat->median();
				
				push(@MEDIAN_SENSOR, $MEDIAN_SENSOR);
				
				if (scalar @MEDIAN_SENSOR > int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval})) {
					shift(@MEDIAN_SENSOR);
				}
			}
		}
		
		#--------CHECK THE CRITERIONS--------------
		
		if (defined @MEDIAN_INSTR[-1])	{
			if (abs($setpoint - @MEDIAN_INSTR[-1]) < $self->{config}->{tolerance_setpoint}) {
				$criterion_setpoint = 1;
			}
			else {
				$criterion_setpoint = 0;
			}
		}
		
		# if (scalar @MEDIAN_INSTR >= int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval}) - 1) {
			
			# my $stat = Statistics::Descriptive::Full->new();
			# $stat->add_data(\@MEDIAN_INSTR);
			# $MEDIAN_INSTR_MEDIAN = $stat->median();
			
			# if (abs($setpoint - $MEDIAN_INSTR_MEDIAN) < $self->{config}->{tolerance_setpoint}) {
				# $criterion_setpoint = 1;
			# }
			# else {
				# $criterion_setpoint = 0;
			# }
		# }
		
		if (scalar @T_INSTR >= int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval}) - 1) {
			my $stat = Statistics::Descriptive::Full->new();
			$stat->add_data(\@T_INSTR);
			$INSTR_STD_DEV = $stat->standard_deviation();
			
			if ($INSTR_STD_DEV < $self->{config}->{std_dev_instrument} ) {
				$criterion_std_dev_INSTR = 1;
			}
			else {
				$criterion_std_dev_INSTR = 0;
			}
		}
		
		if (defined $self->{config}->{sensor}) {
			if (scalar @T_SENSOR >= int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval}) - 1) {
				my $stat = Statistics::Descriptive::Full->new();
				$stat->add_data(\@T_SENSOR);
				$SENSOR_STD_DEV = $stat->standard_deviation();
				
				if ($SENSOR_STD_DEV < $self->{config}->{std_dev_sensor} ) {
					$criterion_std_dev_SENSOR = 1;
				}
				else {
					$criterion_std_dev_SENSOR = 0;
				}
			}
		}
		
		
		my $elapsed_time = $self->convert_time(time()-$time0);
		
		my $line1  = "\rElapsed: $elapsed_time \n Current Temp INSTR: @T_INSTR[-1] \n Current Temp SENSOR: @T_SENSOR[-1] \n ";
		my $line2 = "Current Median: @MEDIAN_INSTR[-1] \n Std. Dev. T Instr. : $INSTR_STD_DEV \n Std. Dev. T Sensor : $SENSOR_STD_DEV \n ";
		my $line3 = "CRIT SETPOINT: $criterion_setpoint \n CRIT Std. Dev. T Instr. : $criterion_std_dev_INSTR \n CRIT Std. Dev. T Sensor : $criterion_std_dev_SENSOR \n ";
		
		my $output = $line1.$line2.$line3;
		
		print $output;
		
		if ($criterion_std_dev_INSTR * $criterion_std_dev_SENSOR * $criterion_setpoint) {
			last;
			print "\n";
		}
		else {
			print "\033[2J";
		}

		
		sleep ($self->{config}->{stabilize_measurement_interval});
	}
	
	$| = 0;
	
	print "Temperature stabilized at $setpoint K \n";
}

sub convert_time { 
	my $self = shift;
	
	my $time = shift; 
	my $days = int($time / 86400); 
	$time -= ($days * 86400); 
	my $hours = int($time / 3600); 
	$time -= ($hours * 3600); 
	my $minutes = int($time / 60); 
	my $seconds = $time % 60; 
	  
	$days = $days < 1 ? '' : $days .'d '; 
	$hours = $hours < 1 ? '' : $hours .'h '; 
	$minutes = $minutes < 1 ? '' : $minutes . 'm '; 
	$time = $days . $hours . $minutes . $seconds . 's'; 
	return $time; 
}


1;
