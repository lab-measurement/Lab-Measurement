package Lab::Connection::Log;
# Role for connection logging.

use Role::Tiny;
use 5.010;

use YAML::XS;
use Data::Dumper;
use autodie;
use Carp;

use Lab::Connection::LogMethodCall qw(dump_method_call);

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

    # FIXME: Currently it's not possible to have a filehandle in %fields, as
    # this breaks the dclone used in Sweep.pm. 
    open my $fh, '>', $self->log_file();
    close $fh;

    return $self;

};

sub dump_ref {
    my $self = shift;
    my $ref = shift;
    open my $fh, '>>', $self->log_file();
    print {$fh} Dump($ref);
    close $fh;
}

for my $method (qw/Clear Write Read Query BrutalRead LongQuery BrutalQuery
 timeout block_connection unblock_connection is_blocked/) {
    around $method => sub {
	my $orig = shift;
	my $self = shift;
	my $retval =  $self->$orig(@_);

	# Inside the around modifier, we need to skip 2 levels to get to the
	# true caller.
	my $caller = caller(2);
	if ($caller !~ /Lab::Connection.*/) {

	    my $index = $self->log_index();

	    if ($index == 1536) {
		croak "index = 1536, method = $method";
	    }
	    my $log = dump_method_call($index, $method, @_);

	    $log->{retval} = $retval;
	    $self->dump_ref($log);

	    $self->log_index(++$index);
	}
	return $retval;
    };
}

1;

