package Lab::Connection::Log;
# Role for connection logging.

use Role::Tiny;
use 5.010;

use YAML::XS;
use autodie;

sub decode_args {
    my @args = @_;
    shift @args;
    if   ( ref $args[0] eq 'HASH' ) {
	return $args[0]
    }
    else {
	return {@args}
    }
}

sub dump_hash {
    my $self = shift;
    my $options = shift;
    
    open my $fh, '>>', $self->log_file();
    print {$fh} Dump($options);
    close $fh;
}



sub dump_ref {
    my $self = shift;
    my $ref = shift;
    open my $fh, '>>', $self->log_file();
    print {$fh} Dump($ref);
    close $fh;
}

# Part of the Lab::Connection interface is implemented via Read and
# Write. Logging these would be redundant.

for my $method (
    qw/Clear Write Read timeout block_connection unblock_connection/) {
    around $method => sub {
	my $orig = shift;
	my $self = shift;
	my @args = @_;
	my $hash->{method} = $method;
	$hash->{args} = \@args;
	
	my $retval =  $self->$orig(@_);
	
	$hash->{retval} = $retval;
	$self->dump_ref($hash);

	
	return $retval;
    };
}

1;

