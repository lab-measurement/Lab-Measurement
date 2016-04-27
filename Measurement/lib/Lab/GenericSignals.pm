
package Lab::GenericSignals;

our $VERSION='3.500';

use Lab::Generic;
use sigtrap 'handler' => \&abort_all, qw(normal-signals error-signals);

sub abort_all {  
  foreach my $object (@{Lab::Generic::OBJECTS}) {
		$object->abort();		
	}
	@{Lab::Generic::OBJECTS} = ();	
	exit;
}

END {  
  abort_all();
}

1;
