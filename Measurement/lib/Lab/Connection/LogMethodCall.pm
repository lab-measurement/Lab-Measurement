package Lab::Connection::LogMethodCall;
use warnings;
use strict;
use 5.010;

use Carp;
use Exporter qw(import);

our @EXPORT = qw(dump_method_call);

# Return a hashref, which describes the method call. Does not include the
# methods's return value.
sub dump_method_call {
    my $id = shift;
    my $method = shift;
    my $first_arg = shift;

    my $log = {
	id => $id,
	method => $method,
    };

    if (not defined $first_arg) {
	return $log;
    }
    
    if ($method =~
	/Clear|block_connection|unblock_connection|is_blocked/) {
	# do nothing
    }
    elsif ($method eq 'timeout') {
	$log->{timeout} = $first_arg;
    }
    elsif ($method =~
	   /Write|Read|Query|BrutalRead|BrutalQuery|LongQuery|BrutalQuery/) {
	if (not (ref $first_arg eq 'HASH'))  {
	    croak "arg not a hashref";
	}
	if (not exists $first_arg->{command}) {
	    croak "no command argument";
	}
	$log->{command} = $first_arg->{command};
	# FIXME: readlength?
    }
    else {
	die;
    }

    return $log;
}

1;
    
