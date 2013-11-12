package Lab::Generic;

our $VERSION = '3.20';


sub new { 
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self={};
	bless ($self, $class);
	
	return $self;
	
}




sub print {
	my $self = shift;
	my @data = @_;
	my ($package, $filename, $line, $subroutine) = caller(1);
	
	if ( ref(@data[0]) eq 'HASH' )
		{
		while ( my ($k,$v) = each %{@data[0]} ) 
			{
			my $line = "$k => ";
			$line.= $self->print($v);
			if ($subroutine =~ /print/)
				{
				return $line;
				}
			else
				{
				print $line."\n";
				}
			}
		}
	elsif ( ref(@data[0]) eq 'ARRAY' )
		{
		my $line ="[";
		foreach (@{@data[0]})
			{
			$line .= $self->print($_);
			$line .= ", ";
			}
		chop ($line);
		chop ($line);
		$line .= "]";
		if ($subroutine =~ /print/)
				{
				return $line;
				}
			else
				{
				print $line."\n";
				}
		}
	else
		{
		if ($subroutine =~ /print/)
				{
				return @data[0];
				}
			else
				{
				print @data[0]."\n";
				}
		}	
		
}







sub _check_args {
	my $self = shift;
	my $args = shift;
	my $params = shift;
	
	my $arguments = {};

	my $i = 0;
	foreach my $arg (@{$args}) 
	{
		if ( ref($arg) ne "HASH" )
			{
			if ( defined @{$params}[$i] )
				{
				$arguments->{@{$params}[$i]} = $arg;				
				}
			$i++;
			}
		else
			{
			%{$arguments} = (%{$arguments}, %{$arg});
			$i++;
			}
	}

			
	my @return_args = ();
	
	foreach my $param (@{$params}) 
		{
		if (exists $arguments->{$param}) 
			{
			push (@return_args, $arguments->{$param});
			delete $arguments->{$param};
			}
		else
			{
			push (@return_args, undef);
			}
		}

	foreach my $param ('from_device', 'from_cache') 	# Delete Standard option parameters from $arguments hash if not defined in device driver function
		{
		if (exists $arguments->{$param}) 
			{
			delete $arguments->{$param};
			}
		}
		

	push(@return_args, $arguments);
	# if (scalar(keys %{$arguments}) > 0) 
		# {
		# my $errmess = "Unknown parameter given in $self :";
		# while ( my ($k,$v) = each %{$arguments} ) 
			# {
			# $errmess .= $k." => ".$v."\t";
			# }
		# print Lab::Exception::Warning->new( error => $errmess);
		# }
			
	return @return_args;
}
	

1;
