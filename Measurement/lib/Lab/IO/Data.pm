package Lab::IO::Data;

our $VERSION='3.512';

sub new { 
	my $proto = shift;
	my $class = ref($proto) || $proto;	
	
	my $self = {};
	$self->{data} = {};
	if (defined ${$class."::msg"}) {$self->{msg} = ${$class."::msg"};}
	
	return bless $self, $class;
}

# msg_parsed: return msg with parsed params
sub msg_parsed {
  my $self = shift;
	
	if (not defined $self->{msg}) {return '';}
	my $msg = $self->{msg}; # copy
	
	if (not defined $self->{data}->{params}) {
	  $msg =~ s/%(\w+)%/\?$1\?/g;
	  return $msg;
	}
		
	my $value;
	while ($msg =~ /%(\w+)%/) {
		$param_name = $1;
		if(exists $self->{data}->{params}->{$param_name} && !ref($self->{data}->{params}->{$param_name})) {
		  $value = $self->{data}->{params}->{$param_name};
			$msg =~ s/%$param_name%/'$value'/;
		}
		else {
		  $msg =~ s/%$param_name%/\?$param_name\?/;
		}
	}
	
	return $msg;
}

1;
