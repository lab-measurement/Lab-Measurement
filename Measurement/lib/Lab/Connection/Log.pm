package Lab::Connection::Log;
# Role for connection logging.

use Role::Tiny;
use 5.010;

use YAML::XS;
use autodie;
use Carp;

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

    # FIXME: Currently it's not possible to have a file handle in %fields, as
    # this breaks the dclone used in Sweep.pm. 
    open my $fh, '>', $self->log_file();
    close $fh;

    return $self;

};

sub dump_ref {
    my $self = shift;
    my $ref = shift;
    open my $fh, '>>', $self->log_file();
    say {$fh} Dump($ref);
    close $fh;
}

# Part of the Lab::Connection interface is implemented via Read and
# Write. Logging these would be redundant.

for my $method (
    qw/Clear Write Read BrutalRead LongQuery BrutalQuery timeout block_connection unblock_connection is_blocked/) {
    around $method => sub {
	my $orig = shift;
	my $self = shift;
	
	my $retval =  $self->$orig(@_);
	
	unshift @_, $retval;
	unshift @_, $method;

	my $index = $self->log_index();
	
	unshift @_, $index;
	
	$self->dump_ref(\@_);

	$self->log_index(++$index);
	
	return $retval;
    };
}

1;

