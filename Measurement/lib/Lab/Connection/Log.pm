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
    print {$fh} Dump($ref);
    print {$fh} "\n\n";
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
	    
	    my $log = [
		{id => $index},
		{method => $method},
		{retval => $retval},
		{'@_' => \@_},
		];
	    
	    $self->dump_ref($log);

	    $self->log_index(++$index);
	}
	return $retval;
    };
}

1;

