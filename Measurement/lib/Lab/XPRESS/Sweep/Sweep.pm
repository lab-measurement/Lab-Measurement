package Lab::XPRESS::Sweep::Sweep;


use Time::HiRes qw/usleep/, qw/time/;
use POSIX qw(ceil);
use Term::ReadKey;
use Lab::XPRESS::Utilities::Utilities;
use Lab::Exception;
use strict;
our $PAUSE = 0;
our $ACTIVE_SWEEPS = ();


our $AUTOLOAD;



sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    
	my $self = bless {}, $class;
	
	$self->{default_config} = {
		instrument => undef,
		allowed_instruments => [undef],

		interval => 0,
		mode => 'dummy',
		delay_before_loop => 0,
		delay_in_loop => 0,
		delay_after_loop => 0,
			
		points => [undef,undef],
		
		rates => [undef],
		durations	=> [undef],
		
		stepwidths => [undef],	
		number_of_points => [undef],
		
		backsweep => 0,
		repetitions => 0
	};

	$self->{LOG} = ();
	@{$self->{LOG}}[0] = {};

	# deep copy $default_config:
	while ( my ($k,$v) = each %{$self->{default_config}} ) 
		 {
		if ( ref($v) eq 'ARRAY')
			{
			$self->{config}->{$k} = ();
			foreach (@{$v})
				{
				push(@{$self->{config}->{$k}}, $_);
				}
			}
		else
			{
			$self->{config}->{$k} =  $v;
			}
		 }
	
	
	my $type=ref $_[0];
	
    if ($type =~ /HASH/) 
		{
		%{$self->{config}} = (%{$self->{config}},%{shift @_},%{shift @_}); 
		}
	
	# for debugging: print config parameters:
	# while ( my ($k,$v) = each %{$self->{config}} ) 
		# {
		# print "$k => $v\n";
		# }
	# print "\n\n";
	
	
		
	$self->prepaire_config();
	
	$self->{pause} = 0;	
	$self->{DataFile_counter} = 0;	
	$self->{DataFiles} = ();
			
			
    return $self;
}

sub prepaire_config {
	my $self = shift;

	# correct typing errors:
	$self->{config}->{mode}  =~ s/\s+//g; #remove all whitespaces
	$self->{config}->{mode}  =~ "\L$self->{config}->{mode}"; # transform all uppercase letters to lowercase letters
	if ($self->{config}->{mode} =~ /continuous|contious|cont|continuouse|continouse|coninuos|continuose/)
		{
		$self->{config}->{mode} = 'continuous';
		}
	
	# make an Array out of single values if necessary:
	if ( ref($self->{config}->{points}) ne 'ARRAY' )
		{
		$self->{config}->{points} = [$self->{config}->{points}];
		}
	if ( ref($self->{config}->{rates}) ne 'ARRAY' )
		{
		$self->{config}->{rates} = [$self->{config}->{rates}];
		}
	if ( ref($self->{config}->{durations}) ne 'ARRAY' )
		{
		$self->{config}->{durations} = [$self->{config}->{durations}];
		}
	if ( ref($self->{config}->{stepwidths}) ne 'ARRAY' )
		{
		$self->{config}->{stepwidths} = [$self->{config}->{stepwidths}];
		}
	if ( ref($self->{config}->{number_of_points}) ne 'ARRAY' )
		{
		$self->{config}->{number_of_points} = [$self->{config}->{number_of_points}];
		}
	


	
	# define alias names:
	if ( defined $self->{config}->{duration} )
		{
		if ( not defined @{$self->{config}->{durations}}[0] )
			{
			@{$self->{config}->{durations}}[0] = $self->{config}->{duration};
			}
		}
	
	if ( defined $self->{config}->{rate} )
		{
		if ( not defined @{$self->{config}->{rates}}[0] )
			{
			@{$self->{config}->{rates}}[0] = $self->{config}->{rate};
			}
		}
		
	if ( defined $self->{config}->{stepwidth} )
		{
		if ( not defined @{$self->{config}->{stepwidths}}[0] )
			{
			@{$self->{config}->{stepwidths}}[0] = $self->{config}->{stepwidth};
			}
		}
	
	
	
	
	# deep Copy original Config Data:
	$self->{config_original} = deep_copy($self->{config});
	
	

	
	# calculate the length of each Array:
	my $length_points = @{$self->{config}->{points}};
	my $length_rates = @{$self->{config}->{rates}};
	my $length_durations = @{$self->{config}->{durations}};
	my $length_stepwidths = @{$self->{config}->{stepwidths}};
	my $length_number_of_points = @{$self->{config}->{number_of_points}};
	
	
	
	
	# Look for inconsistent sweep parameters:
	if ( $length_points < 2  and $self->{config}->{mode} ne 'list')
		{
		die "inconsistent definition of sweep_config_data: less than two elements defined in 'points'. You need at least a 'start' and a 'stop' point.";
		}
	
	if ( $length_rates > $length_points )
		{
		die "inconsistent definition of sweep_config_data: number of elements in 'rates' larger than number of elements in 'points'.";
		}
	if ( $length_durations > $length_points )
		{
		die "inconsistent definition of sweep_config_data: number of elements in 'durations' larger than number of elements in 'points'.";
		}
	if ( $length_stepwidths > $length_points - 1 and $self->{config}->{mode} ne 'list')
		{
		die "inconsistent definition of sweep_config_data: number of elements in 'stepwidths' larger than number of sweep sequences.";
		}
	if ( $length_number_of_points > $length_points - 1 and $self->{config}->{mode} ne 'list')
		{
		die "inconsistent definition of sweep_config_data: number of elements in 'number_of_points' larger than number of sweep sequences.";
		}
		

	
	
	# fill up Arrays to fit with given Points:
	while ( ($length_rates = @{$self->{config}->{rates}}) < $length_points )
		{
		push(@{$self->{config}->{rates}}, @{$self->{config}->{rates}}[-1]);
		}
		
	while ( ($length_durations = @{$self->{config}->{durations}}) < $length_points )
		{
		push(@{$self->{config}->{durations}}, @{$self->{config}->{durations}}[-1]);
		}
		
	while ( ($length_stepwidths = @{$self->{config}->{stepwidths}}) < $length_points )
		{
		push(@{$self->{config}->{stepwidths}}, @{$self->{config}->{stepwidths}}[-1]);
		}
		
	while ( ($length_number_of_points = @{$self->{config}->{number_of_points}}) < $length_points )
		{
		push(@{$self->{config}->{number_of_points}}, @{$self->{config}->{number_of_points}}[-1]);
		}
		
		
		
	# calculate the length of each Array again:
	my $length_points = @{$self->{config}->{points}};
	my $length_rates = @{$self->{config}->{rates}};
	my $length_durations = @{$self->{config}->{durations}};
	my $length_stepwidths = @{$self->{config}->{stepwidths}};
	my $length_number_of_points = @{$self->{config}->{number_of_points}};
		
	
	
	
	# evaluate sweep sign:
	foreach my $i (0..$length_points-2)
		{
		if ( @{$self->{config}->{points}}[$i] - @{$self->{config}->{points}}[$i+1] < 0 )
			{
			@{$self->{config}->{sweepsigns}}[$i] = 1;
			}
		elsif ( @{$self->{config}->{points}}[$i] - @{$self->{config}->{points}}[$i+1] > 0 )
			{
			@{$self->{config}->{sweepsigns}}[$i] = -1;
			}
		else
			{
			@{$self->{config}->{sweepsigns}}[$i] = 0;
			} 
		}
		
			
	
	
	# add current position to Points-Array:
	unshift (@{$self->{config}->{points}}, $self->get_value());
	
	
	
		
	# calculate Durations from rates and vise versa:
	if ( defined @{$self->{config}->{rates}}[0] and defined @{$self->{config}->{durations}}[0] )
		{
		die 'inconsistent definition of sweep_config_data: rate as well as duration defined. Use only one of both.';
		}
	elsif ( defined @{$self->{config}->{durations}}[0] and @{$self->{config}->{durations}}[0] == 0)
		{
		die 'bad definition of sweep parameters: duration == 0 not allowed';
		}
	elsif ( defined @{$self->{config}->{rates}}[0] and @{$self->{config}->{rates}}[0] == 0)
		{
		die 'bad definition of sweep parameters: rate == 0 not allowed';
		}
	elsif ( defined @{$self->{config}->{durations}}[0])
		{					
		foreach my $i (0..$length_points-1)
			{
				@{$self->{config}->{rates}}[$i] = abs(@{$self->{config}->{points}}[$i+1] - @{$self->{config}->{points}}[$i])/@{$self->{config}->{durations}}[$i];
			}
		}
	elsif ( defined @{$self->{config}->{rates}}[0])
		{				
		foreach my $i (0..$length_points-1) 
			{
			@{$self->{config}->{durations}}[$i] = abs(@{$self->{config}->{points}}[$i+1] - @{$self->{config}->{points}}[$i])/@{$self->{config}->{rates}}[$i];
			}
		}
			
		
		
		
	# calculate Stepwidths from Number_of_Points and vise versa:
	if ( defined @{$self->{config}->{stepwidths}}[0] and defined @{$self->{config}->{number_of_points}}[0] )
		{
		die 'inconsistent definition of sweep_config_data: step as well as number_of_points defined. Use only one of both.';
		}
	elsif ( defined @{$self->{config}->{number_of_points}}[0])
		{	
		unshift (@{$self->{config}->{number_of_points}}, 1);
		foreach my $i (1..$length_points-1) 
			{					
			@{$self->{config}->{stepwidths}}[$i-1] = abs(@{$self->{config}->{points}}[$i+1] - @{$self->{config}->{points}}[$i])/@{$self->{config}->{number_of_points}}[$i];
			}
		}
	elsif ( defined @{$self->{config}->{stepwidths}}[0])
		{				
		foreach my $i (1..$length_points-1)
			{
			@{$self->{config}->{number_of_points}}[$i-1] = abs(@{$self->{config}->{points}}[$i+1] - @{$self->{config}->{points}}[$i])/@{$self->{config}->{stepwidths}}[$i];
			}
		}		
	shift @{$self->{config}->{points}};
	
	
	
	
	# Calculations and checks depending on the selected sweep mode:
	if ( $self->{config}->{mode} eq 'continuous' )
		{	
		if ( not defined @{$self->{config}->{rates}}[0] or not defined @{$self->{config}->{durations}}[0] )
			{
			die "inconsistent definition of sweep_config_data: for sweep_mode 'continuous' you have to define the rate or the duration for the sweep.";
			}	
		}
	elsif ( $self->{config}->{mode} eq 'step' )
		{	
		$self->{config}->{interval} = 0;
		if ( not defined @{$self->{config}->{stepwidths}}[0] or not defined @{$self->{config}->{number_of_points}}[0] )
			{
			die "inconsistent definition of sweep_config_data: for sweep_mode 'step' you have to define the setp-size or the number_of_points.";
			}
		
		
		# calculate each point/rate/stepsign/duration in step-sweep:
		my $temp_points = ();
		my $temp_rates = ();
		my $temp_sweepsigns = ();
		my $temp_durations = ();
		
		foreach my $i (0..$length_points-2) 
			{
			my $nop = abs((@{$self->{config}->{points}}[$i+1] - @{$self->{config}->{points}}[$i])/ @{$self->{config}->{stepwidths}}[$i]);
			$nop = ceil($nop); 
			   
			my $point = @{$self->{config}->{points}}[$i];
			for(my $j = 0; $j <= $nop; $j++) 
				{
				if ( $point != @{$temp_points}[-1] or not defined @{$temp_points}[-1]) 
					{
					push (@{$temp_points}, $point);
					push (@{$temp_rates}, @{$self->{config}->{rates}}[$i+1]);
					push (@{$temp_durations}, @{$self->{config}->{durations}}[$i+1]/@{$self->{config}->{number_of_points}}[$i]);
					push (@{$temp_sweepsigns}, @{$self->{config}->{sweepsigns}}[$i]);
					}
				$point += @{$self->{config}->{stepwidths}}[$i]*@{$self->{config}->{sweepsigns}}[$i];
				}
			@{$temp_points}[-1] = @{$self->{config}->{points}}[$i+1];
			}
		pop @{$temp_rates};
		pop @{$temp_durations};
		pop @{$temp_sweepsigns};
		unshift ( @{$temp_rates},@{$self->{config}->{rates}}[0]) ;
		unshift ( @{$temp_durations}, @{$self->{config}->{durations}}[0]);
		#unshift ( @{$temp_sweepsigns}, @{$self->{config}->{sweepsigns}}[0]);
		
		$self->{config}->{points} = $temp_points;
		$self->{config}->{rates} = $temp_rates;		
		$self->{config}->{durations} = $temp_durations;		
		$self->{config}->{sweepsigns} = $temp_sweepsigns;
		}		
	elsif ( $self->{config}->{mode} eq 'list' )
		{	
		$self->{config}->{interval} = 0;
		if ( not defined @{$self->{config}->{rates}}[0] )
			{
			die "inconsistent definition of sweep_config_data: 'rates' needs to be defined in sweep mode 'list'";
			}
		}
	
	
	
	
	# check if instrument is supported:
	if (defined @{$self->{config}->{allowed_instruments}}[0] and not (grep {$_ eq ref($self->{config}->{instrument}) } @{$self->{config}->{allowed_instruments}}) ) {
		die "inconsistent definition of sweep_config_data: Instrument (ref($self->{config}->{instrument})) is not supported by Sweep."
	}
	
	
	
	
	# check if sweep-mode is supported:
	if (defined @{$self->{config}->{allowed_sweep_modes}}[0] and not (grep {$_ eq $self->{config}->{mode} } @{$self->{config}->{allowed_sweep_modes}}) ) {
		die "inconsistent definition of sweep_config_data: Sweep mode $self->{config}->{mode} is not supported by Sweep."
	}

	
	
	
	# adjust repetitions in case of Backsweep selected:
	$self->{config}->{repetitions}++;
	if ( $self->{config}->{backsweep} == 1 )
		{
		$self->{config}->{repetitions} *= 2;
		}
	
	
	
	
	
	
			
}

sub prepare_backsweep {
	my $self= shift;
	my $points = ();
	my $rates = ();
	my $durations = ();
	foreach my $point (@{$self->{config}->{points}}) {
		unshift (@{$points}, $point);
	}
	foreach my $rate (@{$self->{config}->{rates}}) {
		unshift (@{$rates}, $rate);
	}	
	foreach my $duration (@{$self->{config}->{durations}}) {
		unshift (@{$durations}, $duration);
	}

	unshift(@{$rates}, pop(@{$rates}));
	unshift(@{$durations}, 0);
	pop(@{$durations});
	
	#print "Points @{$points} \n";
	#print "Rates @{$rates} \n";
	#print "Durations @{$durations} \n";
	$self->{config}->{points} = $points;
	$self->{config}->{rates} = $rates;	
	$self->{config}->{durations} = $durations;	
	
	
}

sub add_DataFile {
	my $self = shift;
	my $DataFile = shift;
	push(@{$self->{DataFiles}}, $DataFile);
	$self->{DataFile_counter}++;

	@{$self->{LOG}}[$self->{DataFile_counter}] = {};
	
	return $self;
}

sub start {
	my $self = shift;
	ReadMode('cbreak');
	

	unshift (@{$ACTIVE_SWEEPS}, $self);
	$self->{master} = undef;
	$self->{master} = shift;
	$self->{slaves} = undef;
	$self->{slaves} = shift;
	
	
	# calculate duration for the defined sweep:
	$self->estimate_sweep_duration();
	foreach my $slave (@{$self->{slaves}})
		 {
		 $slave->estimate_sweep_duration();
		 }
	# show estimated sweep duration:	
	my $sweep_structure = $self->sweep_structure();
	
	
	
	# create header for each DataFile:
	foreach my $file (@{$self->{DataFiles}})
		 {
		 foreach my $instrument (@{${Lab::Instrument::INSTRUMENTS}})
			 {
			 #print $instrument."\n";
			 $file->add_header($instrument->create_header());
			 }		
		 }
	
	
	
	# link break signals to default functions:
	$SIG{BREAK} = \&enable_pause;
	$SIG{INT} = \&abort;

	for ( my $i = 1; $i <= $self->{config}->{repetitions}; $i++)
		{
		foreach my $file (@{$self->{DataFiles}}) 
			{
			$file->start_block();
			}
		$self->{iterator} = 0;
		$self->{sequence} = 0;
		$self->before_loop();
		$self->go_to_sweep_start();
		$self->delay($self->{config}->{delay_before_loop});
		# continuous sweep:
		if ( $self->{config}->{mode} eq 'continuous' )
			{	
			$self->start_continuous_sweep();
			}
		$self->{Time_start} = time();
		$self->{Date_start}, $self->{TimeStamp_start} = timestamp();
		$self->{loop}->{t0} = $self->{Time_start};
		
		while(1)
			{
			$self->in_loop();
			# step mode:
			if ( $self->{config}->{mode} =~ /step|list/ )
				{
				$self->go_to_next_step();
				$self->delay($self->{config}->{delay_in_loop});
				}			
			$self->{Time} = time()-$self->{Time_start};
			$self->{Date}, $self->{TimeStamp} = timestamp();
			
			
			# Master mode: call slave measurements if defined
			if ( defined @{$self->{slaves}}[0] )
				{
				foreach my $slave (@{$self->{slaves}})
					{
					$slave->start($self);
					}
				}
			# Slave mode: do measurement
			else
				{
				my $i = 1;
				foreach my $DataFile (@{$self->{DataFiles}})
					{
						$DataFile->{measurement}->($self);
						if ($DataFile->{autolog} == 1)
						{
							$DataFile->LOG($self->create_LOG_HASH($i));
						}

					$i++;
					}
				}

			
			# exit loop:
			if ( $self->exit_loop() )
				{
				last;
				}
			
			# pause:
			if ( $self->{config}->{mode} =~ /step|list/ and $PAUSE)
				{
				$self->pause();
				$PAUSE = 0;
				}
			
			
			# check loop duratioin:
			$self->{iterator}++;
			$self->check_loop_duration();
			}
			
		$self->after_loop();
		if ( $PAUSE )
			{
			$self->pause();
			$PAUSE = 0;
			}
		$self->delay($self->{config}->{delay_after_loop});

		# prepare_backsweep:
		if ( $self->{config}->{backsweep} > 0 )
			{
			$self->prepare_backsweep();
			}
		
		}
	
	# finish measurement:
	$self->finish();
	
	return $self;
	
}

sub delay {
	my $self = shift;
	my $delay = shift;
	
	if ( $delay <= 0 )
		{
		return;
		}
	elsif ( $delay > 1 )
		{
		my_sleep($delay, $self, \&user_command);
		}
	else
		{
		my_usleep($delay*1e6, $self, \&user_command);
		}
		
}


sub estimate_sweep_duration {
	my $self = shift;
	my $duration = 0; 
	
	$duration += $self->{config}->{delay_before_loop};
	
	if ( $self->{config}->{mode} =~ /conti/ )
		{		
		foreach (@{$self->{config}->{durations}})
			{
			$duration += $_;			
			}	
		}
	elsif ( $self->{config}->{mode} =~ /step|list/ )
		{
		foreach (@{$self->{config}->{durations}})
			{
			$duration += $_;
			$duration += $self->{config}->{delay_in_loop};
			}		
		}
		
	$duration += $self->{config}->{delay_after_loop};	
	$duration *= $self->{config}->{repetitions};
	
	$self->{config}->{estimated_sweep_duration} = $duration;	
	return $duration;
	
}

sub estimate_total_sweep_duration {
	my $self = shift;
	
	if ( not defined $self->{master} )
		{
		my $duration_total = 0;
		foreach my $slave ( @{$self->{slaves}} )
			{
			$duration_total += $slave->{config}->{estimated_sweep_duration};
			}
		#print "duration_total_1: $duration_total\n";
			my $number_of_steps = @{$self->{config}->{durations}}-1;
		$duration_total *= $number_of_steps;
		#print "duration_total_2: $duration_total\n";
		$duration_total += $self->{config}->{estimated_sweep_duration};
		#print "duration_total_3: $duration_total\n";
		$duration_total *= $self->{config}->{repetitions};
		#print "duration_total_4: $duration_total\n";
		$self->{config}->{estimated_sweep_duration_total} = $duration_total;
		}
	
}

sub sweep_structure {
	my $self = shift;
	my $text = "";
	
	if ( not defined $self->{master} )
		{
		$self->estimate_total_sweep_duration();
		
		
		$text .=  "\n\n\n=====================================================================\n";
		$text .=  "===================  Master/Slave Sweep  ============================\n";
		$text .=  "=====================================================================\n\n\n";
		$text .=  "=========================\n";
		$text .=  " Master = $self->{config}->{id}\n";
		$text .=  "=========================\n";
		$text .=  "\t|\n";
		$text .=  "\t|\n";
		$text .=  "\t|--> Instrument = ".ref($self->{config}->{instrument})."\n";
		# while ( my ($key,$value) = each %{$self->{config}} ) 
			# {
			# if ( ref($value) eq "ARRAY" )
				# {
				# $text .=  "\t|--> $key = @{$value}\n";
				# }
			# elsif ( ref($value) eq "HASH" )
				# {
				# $text .=  "\t|--> $key = %{$value}\n";
				# }
			# else
				# {
				# $text .=  "\t|--> $key = $value\n";
				# }
			# }
		$text .=  "\t|--> Mode = $self->{config}->{mode}\n";
		if ( $self->{config}->{mode} =~ /conti/ )
			{
			$text .=  "\t|--> Interval = $self->{config}->{interval}\n";
			}
		$text .=  "\t|--> Points = @{$self->{config_original}->{points}}\n";
		if ( $self->{config}->{mode} =~ /step/ )
				{
				$text .=  "\t|--> Stepwidths = @{$self->{config}->{stepwidths}}\n";
				}
		$text .=  "\t|--> Rates = @{$self->{config_original}->{rates}}\n";
		$text .=  "\t|--> Durations = @{$self->{config_original}->{durations}}\n";
		$text .=  "\t|--> Delays (before, in, after) loop = $self->{config}->{delay_before_loop}, $self->{config}->{delay_in_loop}, $self->{config}->{delay_after_loop}\n";
		$text .=  "\t|--> Backsweep = $self->{config}->{backsweep}\n";
		$text .=  "\t|--> Repetitions = $self->{config_original}->{repetitions}\n";
		$text .=  "\t|--> Estimated Duration = ".seconds2time($self->{config}->{estimated_sweep_duration})."\n";
		$text .=  "\t|----------------------------------------------------\n";
		
		foreach my $slave (@{$self->{slaves}} )
			{
			$text .=  "\t\t|\n";
			$text .=  "\t\t|\n";
			$text .=  "\t=========================\n";
			$text .=  "\t  Slave = $slave->{config}->{id}\n";
			$text .=  "\t=========================\n";
			$text .=  "\t\t|\n";
			$text .=  "\t\t|\n";
			$text .=  "\t\t|--> Instrument = ".ref($slave->{config}->{instrument})."\n";
			$text .=  "\t\t|--> Mode = $slave->{config}->{mode}\n";
			if ( $slave->{config}->{mode} =~ /conti/ )
				{
				$text .=  "\t\t|--> Interval = $slave->{config}->{interval}\n";
				}
			$text .=  "\t\t|--> Points = @{$slave->{config_original}->{points}}\n";
			if ( $slave->{config}->{mode} =~ /step/ )
				{
				$text .=  "\t\t|--> Stepwidths = @{$slave->{config}->{stepwidths}}\n";
				}
			$text .=  "\t\t|--> Rates = @{$slave->{config_original}->{rates}}\n";
			$text .=  "\t\t|--> Durations = @{$slave->{config_original}->{durations}}\n";
			$text .=  "\t\t|--> Delays (before, in, after) loop = $slave->{config}->{delay_before_loop}, $slave->{config}->{delay_in_loop}, $slave->{config}->{delay_after_loop}\n";
			$text .=  "\t\t|--> Backsweep = $slave->{config}->{backsweep}\n";
			$text .=  "\t\t|--> Repetitions = $slave->{config_original}->{repetitions}\n";
			$text .=  "\t\t|--> Estimated Duration = ".seconds2time($slave->{config}->{estimated_sweep_duration})."\n";
			$text .=  "\t\t|----------------------------------------------------\n";
			}
		$text .=  "\n\n";
		$text .=  "Estimated Duration for Master/Slave-Sweep: ".seconds2time($self->{config}->{estimated_sweep_duration_total})."\n\n\n";
		$text .=  "=====================================================================\n";
		$text .=  "=====================================================================\n\n";
		
		foreach my $slave (@{$self->{slaves}})
			{
			foreach my $file (@{$slave->{DataFiles}})
				{
				$file->add_header($text);
				}
			}
		print $text;
		}
	else
		{
		return undef;
		}
		
	
	
	
}



sub get_value {
	my $self = shift;
	return @{$self->{config}->{points}}[$self->{iterator}];
} 

sub enable_pause {
	$PAUSE = 1;
}

sub pause {
	my $self = shift;
	print "\n\nPAUSE: continue with <ENTER>\n";
	<>;
} 

sub finish {
	my $self = shift;

	# delete entry in ACTIVE_SWEEPS:
	foreach my $i (0..(my $length = @{$ACTIVE_SWEEPS})-1)
		{
		#print "$i FINISH: ".$self."\t".@{$ACTIVE_SWEEPS}[$i]."\n";
		#print "active array before: {@{$ACTIVE_SWEEPS}}\n";
		if ( $self eq @{$ACTIVE_SWEEPS}[$i] )
			{
			#@LIST = splice(@ARRAY, OFFSET, LENGTH, @REPLACE_WITH);
			@{$ACTIVE_SWEEPS} = splice (@{$ACTIVE_SWEEPS}, $i+1, 1);
			#print "active array after: {@{$ACTIVE_SWEEPS}}\n";
			}
		}
		
	# save plot image for all defined measurements:	
	foreach my $file (@{$self->{DataFiles}})
		{
		foreach (0..$file->{plot_count}-1) 
			{
			if ( $file->{logger}->{plots}->[$_]->{autosave} eq 'allways' )
				{
				$file->save_plot($_);
				}
			}
		}
		
	# close DataFiles for all defined slaves:		
	foreach my $slave (@{$self->{slaves}})
		{
		foreach my $file (@{$slave->{DataFiles}})
			{
			foreach (0..$file->{plot_count}-1) 
				{
				
				if ( $file->{logger}->{plots}->[$_]->{autosave} eq 'last' )
					{
					$file->save_plot($_);
					}
				}
			$file->finish_measurement();
			}
		}
		
	# close DataFiles of Master:	
	if ( not defined $self->{master} )
		{
		foreach my $file (@{$self->{DataFiles}})
			{
			foreach (0..$file->{plot_count}-1) 
				{
				if ( $file->{logger}->{plots}->[$_]->{autosave} eq 'last' )
					{
					$file->save_plot($_);
					}
				}
			$file->finish_measurement();
			}
		}	
} 


sub abort {

	print "abort\n";
	foreach my $sweep (@{$ACTIVE_SWEEPS})
		{
		$sweep->exit();
		}
		
	while( @{$ACTIVE_SWEEPS}[0] )
		{
		my $sweep =  @{$ACTIVE_SWEEPS}[0];
		$sweep->finish();
		}
		
	exit;
}

sub stop {

	print "Sweep stopped by User!\n";
	foreach my $sweep (@{$ACTIVE_SWEEPS})
		{
		$sweep->exit();
		}
		
}


sub exit {
	return shift;
}

sub before_loop {
	return shift;
}

sub go_to_sweep_start {
	return shift;
}

sub start_continuous_sweep {
	return shift;
}

sub in_loop {
	return shift;
}

sub go_to_next_step {
	return shift;
}

sub after_loop {
	return shift;
}

sub exit_loop {
	return shift;
}

sub check_loop_duration {

	my $self = shift;
	
	my $char = ReadKey(1e-5);
	if ( defined $char )
		{
		$self->user_command($char);
		}
	
	if ( $self->{config}->{interval} == 0 )
		{
		return 0;
		}
		
	if ( $self->{config}->{mode} =~ /step|list/ )
		{
		return 0;
		}
	
	$self->{loop}->{t1} = time();
	
	if ( not defined $self->{loop}->{t0} )
		{
		$self->{loop}->{t0} = time();
		return 0;
		}
	
	
	my $delta_time = ($self->{loop}->{t1}-$self->{loop}->{t0}) + $self->{loop}->{overtime};
	if ($delta_time > $self->{config}->{interval})
		{
		$self->{loop}->{overtime} = $delta_time - $self->{config}->{interval};
		$delta_time = $self->{config}->{interval};			
		warn "WARNING: Measurement Loop takes more time ($self->{loop}->{overtime}) than specified by measurement intervall ($self->{config}->{interval}).\n";
		}
	else
		{
		$self->{loop}->{overtime} = 0;
		}
	usleep(($self->{config}->{interval}-$delta_time)*1e6);
	$self->{loop}->{t0} = time();
	return $delta_time;
	
}

sub user_command {
	my $self = shift;
	my $cmd = shift;
	
	print "user_command = ".$cmd."\n";
	
	
	if ( $cmd eq "g" )
		{
		foreach my $datafile (@{$self->{DataFiles}})
			{
			$datafile->gnuplot_restart();
			}
		}
	elsif ( $cmd eq "p" )
		{
		#foreach my $datafile (@{$self->{DataFiles}})
		#	{
			@{$self->{DataFiles}}[0]->gnuplot_pause();
		#	}
		}
	
	return 1;
	
}

sub LOG {

	my $self = shift;
	my @args = @_;


	if ( ref($args[0]) eq "HASH" )
		{
		my $file = ( defined $args[1] ) ? $args[1] : 0;
		if ( not defined @{$self->{DataFiles}}[$args[1]-1] )
			{
			Lab::Exception::Warning->throw("DataFile $file is not defined! \n");
			}
		while ( my ($key,$value) = each %{$args[0]} ) 
			{
    		@{$self->{LOG}}[$file]->{$key} = $value;
			}
		}
	else
		{
		# for old style: LOG("column_name", "value", "File")
		my $file = ( defined $args[2] ) ? $args[2] : 0;
		if ( not defined @{$self->{DataFiles}}[$args[2]-1] )
			{
			Lab::Exception::Warning->throw("DataFile $file is not defined! \n");
			}
		@{$self->{LOG}}[$file]->{$args[0]} = $args[1];
		}
}

sub set_autolog {
	my $self = shift;
	my $value = shift;
	my $file = shift;

	if (not defined $file or $file == 0) {
		foreach my $DataFile (@{$self->{DataFiles}})
		{
			$DataFile->set_autolog($value);
		}
	}
	elsif (defined @{$self->{DataFiles}}[$file-1]) {
		@{$self->{DataFiles}}[$file-1]->set_autolog($value);
	}
	else {
		print new Lab::Exception::Warning("DataFile $file is not defined! \n");
	}


	return $self;
}

sub skip_LOG {
	my $self = shift;
	my $file = shift;

	if (not defined $file or $file == 0) {
		foreach my $DataFile (@{$self->{DataFiles}})
		{
			$DataFile->skiplog();
		}
	}
	elsif (defined @{$self->{DataFiles}}[$file-1]) {
		@{$self->{DataFiles}}[$file-1]->skiplog();
	}
	else {
		print new Lab::Exception::Warning("DataFile $file is not defined! \n");
	}


	return $self;
}

sub write_LOG {
	my $self = shift;
	my $file = shift;

	if (not defined $file or $file == 0) {
		my $i = 1;
		foreach my $DataFile (@{$self->{DataFiles}})
		{
			$DataFile->LOG($self->create_LOG_HASH($i));
			$i++;
		}
	}
	elsif (defined @{$self->{DataFiles}}[$file-1]) {
		@{$self->{DataFiles}}[$file-1]->LOG($self->create_LOG_HASH($file));
	}
	else {
		print new Lab::Exception::Warning("DataFile $file is not defined! \n");
	}


	return $self;

}

sub create_LOG_HASH {
	my $self = shift;
	my $file = shift;

	my $LOG_HASH = {};

	foreach my $column (@{@{$self->{DataFiles}}[$file-1]->{COLUMNS}}) {
			if (defined @{$self->{LOG}}[$file]->{$column}) {
				$LOG_HASH->{$column} = @{$self->{LOG}}[$file]->{$column};
			}
			elsif (defined @{$self->{LOG}}[0]->{$column}) {
				$LOG_HASH->{$column} = @{$self->{LOG}}[0]->{$column};
			}
			else {
				if (exists @{$self->{LOG}}[$file]->{$column} or exists @{$self->{LOG}}[0]->{$column})
					{
					print new Lab::Exception::Warning("Value for Paramter $column undefined\n");
					}
				else
					{
					print new Lab::Exception::Warning("Paramter $column not found. Maybe a typing error??\n");
					}
				$LOG_HASH->{$column} = '?';
			}
		}

	return $LOG_HASH;

}


sub deep_copy {

    # if not defined then return it
    return undef if $#_ < 0 || !defined( $_[0] );

    # if not a reference then return the parameter
    return $_[0] if !ref( $_[0] );
    my $obj = shift;
    if ( UNIVERSAL::isa( $obj, 'SCALAR' ) ) {
        my $temp = deepcopy($$obj);
        return \$temp;
    }
    elsif ( UNIVERSAL::isa( $obj, 'HASH' ) ) {
        my $temp_hash = {};
        foreach my $key ( keys %$obj ) {
            if ( !defined( $obj->{$key} ) || !ref( $obj->{$key} ) ) {
                $temp_hash->{$key} = $obj->{$key};
            }
            else {
                $temp_hash->{$key} = deep_copy( $obj->{$key} );
            }
        }
        return $temp_hash;
    }
    elsif ( UNIVERSAL::isa( $obj, 'ARRAY' ) ) {
        my $temp_array = [];
        foreach my $array_val (@$obj) {
            if ( !defined($array_val) || !ref($array_val) ) {
                push ( @$temp_array, $array_val );
            }
            else {
                push ( @$temp_array, deep_copy($array_val) );
            }
        }
        return $temp_array;
    }

    # ?? I am uncertain about this one
    elsif ( UNIVERSAL::isa( $obj, 'REF' ) ) {
        my $temp = deepcopy($$obj);
        return \$temp;
    }

    # I guess that it is either CODE, GLOB or LVALUE
    else {
        return $obj;
    }
}



# sub timestamp {

	# my $self = shift;
	# my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat,
    # $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime(time);
	
	# $Monat+=1;
	# $Jahrestag+=1;
	# $Monat = $Monat < 10 ? $Monat = "0".$Monat : $Monat;
	# $Monatstag = $Monatstag < 10 ? $Monatstag = "0".$Monatstag : $Monatstag;
	# $Stunden = $Stunden < 10 ? $Stunden = "0".$Stunden : $Stunden;
	# $Minuten = $Minuten < 10 ? $Minuten = "0".$Minuten : $Minuten;
	# $Sekunden = $Sekunden < 10 ? $Sekunden = "0".$Sekunden : $Sekunden;
	# $Jahr+=1900;
	
	# return   "$Monatstag.$Monat.$Jahr", "$Stunden:$Minuten:$Sekunden";

# }


1;