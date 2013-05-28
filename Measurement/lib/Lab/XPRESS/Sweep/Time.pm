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
		points	=>	[0], #[0,10],
		duration	=> undef,
		stepwidth => 1,
		mode	=> 'continuous',
		allowed_instruments => [undef],
		allowed_sweep_modes => ['continuous'],
		};
	
	if (ref(@args[0]->{duration}) ne "ARRAY") {
		@args[0]->{duration} = [@args[0]->{duration}];
	}
	
	foreach my $d (@{@args[0]->{duration}}) 
			{
			push(@{$self->{default_config}->{points}}, $d);
			}
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

	if ( @{$self->{config}->{points}}[$self->{sequence}] > 0 and $self->{iterator} >= (@{$self->{config}->{points}}[$self->{sequence}]/@{$self->{config}->{interval}}[$self->{sequence}]) )
		{
		if (not defined @{$self->{config}->{points}}[$self->{sequence}+1])
			{
			return 1;
			}

		$self->{iterator} = 0;
		$self->{sequence} ++;
		return 0;
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

sub go_to_sweep_start {
	my $self = shift;
	
	$self->{sequence} ++;
	}
	
sub halt {
	return shift;
}


1;
