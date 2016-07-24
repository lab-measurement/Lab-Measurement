package Lab::Connection::Mock;

use warnings;
use strict;
use 5.010;

use Class::Method::Modifiers;
use YAML::XS qw/Dump LoadFile/;
use autodie;
use Carp;

use Lab::Connection::LogMethodCall qw/dump_method_call/;
use Data::Compare;
use parent 'Lab::Connection';

our %fields = (
	log_file => undef,
	log_index => 0,
	log_list => undef,
    );

around 'new' => sub {
	my $orig = shift;
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin  = undef;

	# getting fields and _permitted from parent class
	my $self = $class->$orig(@_); 
	
	$self->_construct($class);

	# open the log file
	my $log_file = $self->log_file();
	if (not defined $log_file) {
		croak 'missing "log_file" parameter in connection';
	}

	my @logs = LoadFile($log_file);
	$self->log_list([@logs]);
	
	return $self;
};

sub process_call {
    my $method = shift;
    my $self = shift;
    my $first_arg = shift;

    my $index = $self->log_index();
    
    my $received = dump_method_call($index, $method, $first_arg);
    
    my $expected = $self->log_list()->[$index];

    my $retval = delete $expected->{retval};
    
    if (not Compare($received, $expected)) {
	croak "Mock connection:\nreceived:\n------------------\n", Dump($received), "----------------\nexpected:\n", Dump($expected);
    }
    
    $self->log_index(++$index);
    return $retval;
}

for my $method
    (qw/Clear Write Read Query BrutalRead LongQuery BrutalQuery timeout
block_connection unblock_connection is_blocked/) {
	around $method => sub {
	    my $orig = shift;
	    return process_call($method, @_);
	};
}

sub _setbus {
    # no bus for this connection, so do nothing.
    return;
}
1;
