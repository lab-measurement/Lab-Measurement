package Lab::IO::Interface::Void;

our $VERSION='3.515';

use Lab::IO::Interface;

use Lab::Generic;
use parent ("Lab::IO::Interface");

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);

	$self->{CHANNELS} = {
		'MESSAGE' => \&send_to_trash
	 ,'ERROR' => \&send_to_trash
	 ,'WARNING' => \&send_to_trash
	 ,'DEBUG' => \&send_to_trash
	 ,'PROGRESS' => \&send_to_trash
	};
	return $self;
}

sub send_to_trash {
	return;
}
1;
