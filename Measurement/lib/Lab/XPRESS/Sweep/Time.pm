package Lab::XPRESS::Sweep::Time;

our $VERSION = '3.32';

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




=head1 NAME

	Lab::XPRESS::Sweep::Time - simple time controlled repeater

.

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();
	
	
	
	my $repeater = $hub->Sweep('Time',
		{
		duration => 5
		});

.

=head1 DESCRIPTION

Parent: Lab::XPRESS::Sweep::Sweep

The Lab::XPRESS::Sweep::Time class implements a simple time controlled repeater module in the Lab::XPRESS::Sweep framework.

.

=head1 CONSTRUCTOR
	

	my $repeater = $hub->Sweep('Time',
		{
		repetitions => 5
		});

Instantiates a new Repeater.

.

=head1 PARAMETERS



=head2 duration [int] (default = 1)
	
duration for the time controlled repeater. Default value is 1, negative values indicate a infinit number of repetitions.

.

=head2 interval [int] (default = 1)
	
interval in seconds for taking measurement points.

.

=head2 id [string] (default = 'Repeater')

Just an ID.

.


=head2 delay_before_loop [int] (default = 0)

defines the time in seconds to wait after the starting point has been reached.

.


=head2 delay_after_loop [int] (default = 0)

Defines the time in seconds to wait after the sweep has been finished. This delay will be executed before an optional backsweep or optional repetitions of the sweep.

.

=head1 CAVEATS/BUGS

probably none

.

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS::Sweep>

=back

.

=head1 AUTHOR/COPYRIGHT

Christian Butschkow and Stefan Geißler

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

.

=cut

