package Lab::Moose::Connection::USBTMC;

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(enum);
use Carp;

use Lab::Moose::Instrument qw/timeout_param/;

use Module::Load 'load';

require 'linux/ioctl.ph';                        ## no critic
require 'Lab/Moose/Connection/USBTMC/tmc.ph';    ## no critic

#use namespace::autoclean;

has device => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has filehandle => (
    is       => 'ro',
    isa      => 'FileHandle',
    writer   => '_filehandle',
    init_arg => undef
);

sub BUILD {
    my $self = shift;

    my $file = '/dev/usbtmc' . $self->device();

    # Use raw syscalls.
    open my $fh, '+<:unix', $file
        or croak "cannot open $file: $!";

    $self->_filehandle($fh);
}

sub Read {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
    );

    my $result_string = "";

    # FIXME: handle long reads

    my $fh = $self->filehandle();

    my $read_length = 10000;

    my $read = sysread $fh, $result_string, $read_length;

    if ( not defined $read ) {
        croak "Read error: $!";
    }

    return $result_string;
}

sub Write {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    my $command = $arg{command};

    my $fh = $self->filehandle();

    my $written = syswrite $fh, $command;

    if ( not defined $written ) {
        croak "Write failed: $!";
    }

    my $expected = length $command;

    if ( $written != $expected ) {
        croak "incomplete Write: written: $written, expected: $expected";
    }
}

sub _safe_ioctl {
    my ( $fh, $request, $name ) = pos_validated_list(
        \@_,
        { isa => 'FileHandle' },
        { isa => 'Int' },
        { isa => 'Str' }
    );

    ioctl( $fh, $request, 0 )
        or croak "ioctl '$name' failed: $!";
}

sub Clear {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
    );

    my $fh = $self->filehandle();

    _safe_ioctl( $fh, USBTMC_IOCTL_CLEAR(), "clear" );
}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable();

1;
