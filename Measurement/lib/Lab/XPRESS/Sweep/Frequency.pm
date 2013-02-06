package Lab::XPRESS::Sweep::Frequency;

use Lab::XPRESS::Sweep::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA=('Lab::XPRESS::Sweep::Sweep');




sub new {
    my $proto = shift;
	my @args=@_;
    my $class = ref($proto) || $proto; 
	my $self->{default_config} = {
		id => 'Frequency_Sweep',
		interval	=> 1,
		points	=>	[],
		rates => [1],
		mode	=> 'step',
		allowed_instruments => ['Lab::Instrument::SignalRecovery726x'],
		allowed_sweep_modes => ['list', 'step'],
		number_of_points => [undef]
		};
		
	$self = $class->SUPER::new($self->{default_config},@args);	
	bless ($self, $class);
		
    return $self;
}

sub go_to_sweep_start {
	my $self = shift;
	
	# go to start:
	$self->{config}->{instrument}->set_frq({value => @{$self->{config}->{points}}[0]});
}

sub start_continuous_sweep {
	my $self = shift;

	return;
		
}


sub go_to_next_step {
	my $self = shift;

	$self->{config}->{instrument}->set_frq({value => @{$self->{config}->{points}}[$self->{iterator}]});

}

sub exit_loop {
	my $self = shift;

	if ( $self->{config}->{mode} =~ /step|list/ )
			{	
			if (not defined @{$self->{config}->{points}}[$self->{iterator}+1])
				{
				return 1;
				}
			else
				{
				return 0;
				}
			}
}

sub get_value {
	my $self = shift;
	return $self->{config}->{instrument}->get_frq();
}


sub exit {
	my $self = shift;
	$self->{config}->{instrument}->abort();
}


1;