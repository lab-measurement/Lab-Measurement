#$Id: IPSWeiss2.pm 2012-11-10 Geissler/Butschkow $

package Lab::Instrument::IPSWeiss;
our $version = '3.10';

use strict;
use Lab::Instrument::IPS;
our @ISA=('Lab::Instrument::IPS');

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	
	$self->{LIMITS} = ( 'magneticfield' => 10, 'field_intervall_limits' => [0, 10], 'rate_intervall_limits' => [1.98, 1.98]);
	
	$self->check_magnet();
	
	return $self;
}

sub check_magnet {
	my $self = shift;
	
	my $version = $self->get_version();
	if (not ($version =~ /Version\s3\.07/)) {
		Lab::Exception::CorruptParameter->throw( error => "This Instrument driver is supposed to be used ONLY with LS Weiss Kryo2 !\n");
	}
}

1;
