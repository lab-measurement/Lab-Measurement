package Lab::XPRESS::Sweep::Frame;


use Time::HiRes qw/usleep/, qw/time/;
use strict;
use Lab::XPRESS::Sweep::Dummy;

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
		warn 'no master defined';
		}
	elsif ( not defined $self->{slaves}[-1] )
		{
		warn 'no measurement defined';
		return $self;
		}
	elsif ( defined $self->{slaves}[-1] )
		{
		if ( $self->{master}->{config}->{mode} =~ /step|list/  )
			{
			foreach my $slave (@{$self->{slaves}})
				{
				if ( not defined $slave->{DataFiles}[-1] )
					{
					if ( ref($slave) != 'Lab::XPRESS::Sweep::Dummy' )
						{
						warn "no measurement defined in slave ref($slave)";
						}
					}
				}
			$self->{master}->start(undef, $self->{slaves});
			return $self;
			}
		else
			{
			warn 'master not in step or list mode';
			return $self;
			}
		}

}

sub halt {
	my $self = shift;
	
	foreach my $slave ( @{$self->{slaves}} )
		{
		$slave->halt();
		}
		
	if ( defined $self->{master} )
		{
		$self->{master}->halt();
		}
	
	exit;
	
}

sub pause {
	return shift;
}

sub add_master {
	my $self = shift;	
	$self->{master} = shift;
	if ( $self->{master}->{DataFile_counter} > 0 )
		{
		$self->{master}->{DataFile_counter}= 0;
		$self->{master}->{DataFiles} = ();
		#warn 'WARNING: master may not have a DataFile object. Will be ignored.';
		}
	return $self;
}

sub add_slave {
	my $self = shift;
	my $slave = shift;
	
	if ( not defined $self->{master} )
		{
		die 'no master defined when called add_slave().';
		}
	
	my $type = ref($slave);
	if ( $type =~ /^Lab::XPRESS::Sweep/ )
		{
		if ($slave->{DataFile_counter} <= 0) {
			while (1) {
				print "\n XPRESS::FRAME: -- Added slave sweep has no DataFile! Continue anyway (y/n) ?\n";
				my $answer = <>;
				if ($answer =~ /y|Y/) {
					last;
				} 
				elsif ($answer =~ /n|N/) {
					exit;
				}
			}
		}

		push ( @{$self->{slaves}}, $slave );
		$self->{slave_counter}++;
		}
	elsif ( $type eq 'CODE' )
		{
		$slave = new Lab::XPRESS::Sweep::Dummy($slave);
		push ( @{$self->{slaves}}, $slave );
		$self->{slave_counter}++;
		}
	else
		{
		warn "slave object is of type $type. Cannot add slave.";
		}
		
	# my $type = ref($self->{slaves}[-1]);
	# print "add slave:\n";
	# print $type."\n";
	
	return $self;
}

1;
