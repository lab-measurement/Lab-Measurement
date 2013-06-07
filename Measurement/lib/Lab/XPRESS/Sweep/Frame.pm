package Lab::XPRESS::Sweep::Frame;


use Time::HiRes qw/usleep/, qw/time/;
use strict;
use Lab::Exception;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
	my $self = {};
    bless ($self, $class);
	
	$self->{slave_counter} = 0;
	$self->{slaves} = ();
	
			
    return $self;
}


sub start {
	my $self = shift;
	
	if ( not defined $self->{master} )
		{
		Lab::Exception::Warning->throw(error => "no master defined");
		}
	else {
		$self->{master}->start();
	}

}

sub abort {
	my $self = shift;
	
	$self->{master}->abort();
	
}

sub pause {
	return shift;
}

sub add_master {
	my $self = shift;	
	$self->{master} = shift;

	my $type = ref($self->{master});
	if ( not $type =~ /^Lab::XPRESS::Sweep/ )
		{
		Lab::Exception::Warning->throw(error => "Master is not of type Lab::XPRESS::Sweep . ");
		}
	return $self;
}

sub add_slave {
	my $self = shift;
	my $slave = shift;
	
	if ( not defined $self->{master} )
		{
		Lab::Exception::Warning->throw(error => "no master defined when called add_slave().");
		}
	
	$self->{master}->add_slave($slave);

	return $self;
}

1;
