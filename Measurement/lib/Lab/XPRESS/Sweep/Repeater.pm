package Lab::XPRESS::Sweep::Repeater;

our $VERSION = '3.19';

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
		filename_extension => '#',
		repetitions	=> 1,
		#my_repetitions	=> 1,
		stepwidth	=> 1,
		points	=> [1],
		rate	=> [1],
		mode	=> 'list',
		allowed_sweep_modes => ['list'],
		backsweep	=>	0,

		};
		
	$self = $class->SUPER::new($self->{default_config},@args);	
	bless ($self, $class);
	$self->{config}->{points} = [1];
	$self->{config}->{duration} = ();
	foreach (@{$self->{config}->{points}})
		{
		push (@{$self->{config}->{duration}}, 1);
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

# sub exit_loop {
# 	# my $self = shift;
	
# 	# if ( $self->{iterator} >= $self->{config}->{my_repetitions} )
# 	# 	{
# 	# 	return 1;
# 	# 	}
# 	# else
# 	# 	{
# 	# 	return 0;
# 	# 	}

# }

sub get_value {
	my $self = shift;
	return $self->{repetition};
}



1;
