package Lab::XPRESS::Sweep::Magnet;

use Lab::XPRESS::Sweep::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA=('Lab::XPRESS::Sweep::Sweep');




sub new {
    my $proto = shift;
	my @args=@_;
    my $class = ref($proto) || $proto; 
	my $self->{default_config} = {
		id => 'Magnet_sweep',
		interval	=> 1,
		points	=>	[],
		durations	=> [],
		mode	=> 'continuous',
		allowed_instruments => ['Lab::Instrument::IPS', 'Lab::Instrument::IPSWeiss1', 'Lab::Instrument::IPSWeiss2', 'Lab::Instrument::IPSWeissDillFridge'],
		allowed_sweep_modes => ['continuous', 'list', 'step'],
		number_of_points => [undef]
		};
		
	$self = $class->SUPER::new($self->{default_config},@args);	
	bless ($self, $class);
	
	
	print "hallo\n";		
    return $self;
}

sub go_to_sweep_start {
	my $self = shift;
	
	# go to start:
	print "going to start ... ";
	$self->{config}->{instrument}->config_sweep({
		'points' => @{$self->{config}->{points}}[0], 
		'rates' => @{$self->{config}->{rates}}[0] 
		});
	$self->{config}->{instrument}->trg();
	$self->{config}->{instrument}->wait();
	print "done\n";
	
}

sub start_continuous_sweep {
	my $self = shift;

	# continuous sweep:
	$self->{config}->{instrument}->config_sweep({
		'points' => $self->{config}->{points}, 
		'rates' => $self->{config}->{rates}
		});
	$self->{config}->{instrument}->trg();
		
}


sub go_to_next_step {
	my $self = shift;

	
	# step mode:	
	$self->{config}->{instrument}->config_sweep({
		'points' => @{$self->{config}->{points}}[$self->{iterator}], 
		'rates' => @{$self->{config}->{rates}}[$self->{iterator}]
		});
	$self->{config}->{instrument}->trg();
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
			else
				{
				return 0;
				}
			}
		return 1;
		}
	else
		{
		return 0;
		}
}

sub get_value {
	my $self = shift;
	return $self->{config}->{instrument}->get_field();
}


sub exit {
	my $self = shift;
	$self->{config}->{instrument}->abort();
}


1;