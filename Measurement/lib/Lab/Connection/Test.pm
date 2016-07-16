package Lab::Connection::Test;

use warnings;
use strict;
use 5.010;

use Class::Method::Modifiers;
use YAML::XS qw/Dump LoadFile/;
use autodie;
use Carp;

use Data::Compare;
use parent 'Lab::Connection';

my %fields = (
    log_file => undef,
    log_index => 0,
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
    $self->log_list(@logs);
    
    return $self;
}

sub process_call {
    my $method = shift;
    my $self = shift;
    my @args = @_;
    
    my $index = $self->log_index();

    my $received = [$index, $method, @args];
    my $expected = $self->log_list()->[$index];

    my $retval = splice @{$expected}, 1, 1;

    if (not Compare($received, $expected)) {
	die "Test connection:\nreceived:\n------------------\n", Dump($received), "----------------\nexpected:\n", Dump(\@expected);
    }
    
    $self->log_index(++$index);
    return $retval;
}

for my $method
    (qw/Clear Write Read timeout block_connection unblock_connection/) {
	around $method => sub {
	    return process_call($method, @_);
	}
}

1;
