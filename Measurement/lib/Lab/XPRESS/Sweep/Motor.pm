package Lab::XPRESS::Sweep::Motor;

use Lab::XPRESS::Sweep::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA=('Lab::XPRESS::Sweep::Sweep');




sub new {
    my $proto = shift;
	my @args=@_;
    my $class = ref($proto) || $proto; 
	my $self->{default_config} = {
		id => 'Motor_sweep',
		interval	=> 1,
		points	=>	[],
		durations	=> [],
		mode	=> 'continuous',
		allowed_instruments => ['Lab::Instrument::PD11042', 'Lab::Instrument::ProStep4'],
		allowed_sweep_modes => ['continuous', 'list', 'step'],
		number_of_points => [undef]
		};
		
	$self = $class->SUPER::new($self->{default_config},@args);	
	bless ($self, $class);
	
	
			
    return $self;
}

sub go_to_sweep_start {
	my $self = shift;
	
	# go to start:
	print "going to start ... ";
	$self->{config}->{instrument}->move(@{$self->{config}->{points}}[0], @{$self->{config}->{rates}}[0], {mode => 'ABS'});
	$self->{config}->{instrument}->wait();
	print "done\n";
	
}

sub start_continuous_sweep {
	my $self = shift;
	
	# continuous sweep:
	$self->{config}->{instrument}->move(@{$self->{config}->{points}}[$self->{iterator}+1], @{$self->{config}->{rates}}[$self->{iterator}+1], {mode => 'ABS'});
		
}


sub go_to_next_step {
	my $self = shift;

	# step mode:
	$self->{config}->{instrument}->move(@{$self->{config}->{points}}[$self->{iterator}], @{$self->{config}->{rates}}[$self->{iterator}], {mode => 'ABS'});
	$self->{config}->{instrument}->wait();
	
}

sub exit_loop {
	my $self = shift;
	if (not $self->{config}->{instrument}->active() )
		{
		if ( $self->{config}->{mode} =~ /step|list/ )
			{	
			if (not defined @{$self->{config}->{points}}[$self->{iterator}+1])
				{
				return 1;
				}
			}
		if ( $self->{config}->{mode} eq 'continuous' )
			{	
			if (not defined @{$self->{config}->{points}}[$self->{sequence}+2])
				{
				return 1;
				}
			$self->{sequence}++;
			$self->{config}->{instrument}->move(@{$self->{config}->{points}}[$self->{sequence} +1 ], @{$self->{config}->{rates}}[$self->{sequence} +1 ], {mode => 'ABS'});
			}
		return 0;
		}
	else
		{
		return 0;
		}
}

sub get_value {
	my $self = shift;
	return $self->{config}->{instrument}->get_position();
}


sub exit {
	my $self = shift;
	$self->{config}->{instrument}->abort();
}


1;