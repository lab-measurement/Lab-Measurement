package Lab::Connection::LinuxGPIB::Log;
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::LinuxGPIB';

use Role::Tiny::With;
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

with 'Lab::Connection::Log';

1;
    
