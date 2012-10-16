package Lab::XPRESS::Sweep::Repeater;


use Lab::XPRESS::Sweep::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;


our @ISA=('Lab::XPRESS::Sweep::Sweep');



sub new {
    my $proto = shift;
	my @args=@_;
    my $class = ref($proto) || $proto;
	my $self->{default_config} = {
		id => 'Repeater',
		repetitions	=> 0,
		my_repetitions	=> 1,
		stepwidths	=> 1,
		points	=> [0,1],
		rates	=> [1,1],
		mode	=> 'list',
		allowed_sweep_modes => ['list'],
		backsweep	=>	0,
		};
		
	$self = $class->SUPER::new($self->{default_config},@args);	
	bless ($self, $class);
	$self->{config}->{points} = [(1..$self->{config}->{my_repetitions})];
	$self->{config}->{durations} = ();
	foreach (@{$self->{config}->{points}})
		{
		push (@{$self->{config}->{durations}}, 1);
		}
	
	
	
	# %{$self->{config}} = %{shift @default_config};
	
	 # my $type=ref $_[0];

    # if ($type =~ /HASH/) {
	# %{$self->{config}} = (%{$self->{config}},%{shift @_}); 
	# #while ( my ($k,$v) = each %{$self->{config}} ) {
    # #print "$k => $v\n";
	# }
	
	$self->{config}->{mode} = 'list';
	$self->{loop}->{interval} = $self->{config}->{interval};
			
	$self->{DataFile_counter} = 0;
	
	$self->{DataFiles} = ();
	
    return $self;
}

sub exit_loop {
	my $self = shift;
	
	if ( $self->{iterator} >= $self->{config}->{my_repetitions} )
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
	return $self->{iterator};
}



1;