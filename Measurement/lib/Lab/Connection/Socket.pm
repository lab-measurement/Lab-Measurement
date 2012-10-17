package Lab::Connection::Socket;
our $VERSION = '3.00';

use Lab::Bus::Socket;
use Lab::Connection;
use Lab::Exception;


our @ISA = ("Lab::Connection");

our %fields = (
	bus_class => 'Lab::Bus::Socket',
	wait_status=>0, # usec;
	wait_query=>10e-6, # sec;
	read_length=>1000, # bytes
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);

	return $self;
}
#

# Connection definitions sufficient:
#sub Write {
#	my $self=shift;
#	my $options=undef;
#	if (ref $_[0] eq 'HASH') { $options=shift }
#	else { $options={@_} }
#	
#	my $timeout = $options->{'timeout'} || $self->timeout();
##	$self->bus()->timeout($self->connection_handle(), $timeout);
#	
#	return $self->bus()->connection_write($self->connection_handle(), $options);
#}


#
#sub Read {
#	my $self=shift;
#	my $options=undef;
#	if (ref $_[0] eq 'HASH') { $options=shift }
#	else { $options={@_} }
#	
#	my $timeout = $options->{'timeout'} || $self->timeout();
#	$self->bus()->timeout($self->connection_handle(), $timeout);
#
#	return $self->bus()->connection_read($self->connection_handle(), $options);
#}
#
#sub Query {
#	my $self=shift;
#	my $options=undef;
#	if (ref $_[0] eq 'HASH') { $options=shift }
#	else { $options={@_} }
#
#	my $wait_query=$options->{'wait_query'} || $self->wait_query();
#	my $timeout = $options->{'timeout'} || $self->timeout();
#	$self->bus()->timeout($self->connection_handle(), $timeout);
#	
#	$self->Write( $options );
#	usleep($wait_query);
#	return $self->Read($options);
#}

#---For compatibility with Instruments written for GPIB----
sub EnableTermChar { # 0/1 off/on
  my $self=shift;
  my $enable=shift;
  print "EnableTermChar Ignored: Only for GPIB not for SOCKET?\n";
  #$self->{'TermChar'}=$enable;#bus()->connection_enabletermchar($self->connection_handle(), $enable);}
  return 1;
}

sub SetTermChar { # the character as string
  my $self=shift;
  my $termchar=shift;
  print "SetTermChar Ignored: Only for GPIB not for SOCKET?\n";
  #my $result=$self->bus()->connection_settermchar($self->connection_handle(), $termchar);
  return 1;
}
