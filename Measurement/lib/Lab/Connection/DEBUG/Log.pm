package Lab::Connection::DEBUG::Log;
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::DEBUG';

use Class::Method::Modifiers;
use YAML::XS;
use Carp;
use autodie;

our %fields = (
    log_file => undef,
    );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self =
      $class->SUPER::new(@_);  # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

# open the log file
my $log_file = $self->log_file();
if (not defined $log_file) {
    croak 'missing "log_file" parameter in connection';
}

# FIXME: Currently it's not possible to have a file handle in %fields, as this
# breaks the dclone used in Sweep.pm. 

open my $fh, '>', $self->log_file();
close $fh;

return $self;
}

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

sub install_modifiers {
    for my $name (@_) {
	around $name => sub {
	    my $orig = shift;
	    my $self = $_[0];
	    my $options = decode_args(@_);
	    my $hash = {method => $name,
			options => $options};
	    
	    $self->dump_hash($hash);
	    
	    $orig->(@_);
	};
    }
}

install_modifiers(qw/Clear Write Read BrutalRead Query LongQuery BrutalQuery/);
# FIXME: timeout, block_connection, unblock_connection

1;
    
