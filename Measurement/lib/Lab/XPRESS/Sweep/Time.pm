package Lab::XPRESS::Sweep::Time;

use Lab::XPRESS::Sweep::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA=('Lab::XPRESS::Sweep::Sweep');



sub new {
    my $proto = shift;
	my @args=@_;
    my $class = ref($proto) || $proto; 
	
	# define default values for the config parameters:
	my $self->{default_config} = {
		id => 'Time_sweep',
		interval	=> 1,
		points	=>	[undef,undef], #[0,10],
		duration	=> undef,
		durations	=> undef,
		stepwidths => 1,
		mode	=> 'continuous',
		allowed_instruments => [undef],
		allowed_sweep_modes => ['continuous'],
		number_of_points => [undef]
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
	
	# Durations-Array invalid in Time-sweep; Replace by Duration for consistency:
	$self->{config}->{durations} = ();
	@{$self->{config}->{durations}}[0] = $self->{config}->{duration};
	
	# Calculate Number of Points:
	$self->{config}->{number_of_points} = @{$self->{config}->{durations}}[0]/$self->{config}->{interval};
	
	# No Backsweep allowed; adjust number of Repetitions if Backsweep is 1:
	if ( $self->{config}->{backsweep} == 1 )
		{
		$self->{config}->{repetitions} /= 2;
		$self->{config}->{backsweep} = 0;
		}
	
	# Set loop-Interval to Measurement-Interval:
	$self->{loop}->{interval} = $self->{config}->{interval};

}

sub exit_loop {
	my $self = shift;
	if ( @{$self->{config}->{durations}}[0] != 0 and $self->{iterator} >= $self->{config}->{number_of_points} )
		{
		return 1;
		}
	else
		{
		return 0;
		}
}

sub get_value {
	my $self = shift;
	return $self->{time};
}


sub halt {
	return shift;
}


1;
