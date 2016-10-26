package Lab::Moose::Connection::USBTMC;

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(enum);
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;

use Time::HiRes qw/gettimeofday tv_interval/;

use YAML::XS;

use Module::Load 'load';

load('linux/ioctl.ph');

use namespace::autoclean;

has device => (
    is       => 'ro',
    isa      => 'num',
    required => 1,
);

# has serial => (
#     is => 'ro',
#     isa => 'str'
#     );

has filehandle => (
    is       => 'ro',
    isa      => 'filehandle',
    writer   => '_filehandle',
    init_arg => undef
);

sub build {
    my $self = shift;

    my $file = '/dev/usbtmc' . $self->device();

    open my $fh, '+<:unix', $file
        or croak "cannot open $file: $!";

    $self->_filehandle($fh);
}

sub Read {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        read_length_param,
    );

    my $result_string = "";

    #fixme: handle timeout
    #    my $start_time = [gettimeofday];

    my $fh = $self->filehandle();

    while (1) {

        # my $elapsed_time = tv_interval($start_time);

        # if ( $elapsed_time > $self->timeout() ) {
        #     croak(
        #         "timeout in read with args:\n",
        #         dump( \%arg )
        #     );
        # }

        my $read_length = 1000000;

        my $read = sysread $fh, $result_string, $read_length,
            length($result_string);

        if ( not defined $read ) {
            croak "Read error: $!";
        }

        if ( $read < $read_length ) {
            last;
        }
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

sub Query {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        read_length_param,
        command => { isa => 'Str' },
    );

    my %write_arg = %arg;
    delete $write_arg{read_length};
    $self->Write(%write_arg);

    delete $arg{command};
    return $self->Read(%arg);
}

sub Clear {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
    );

    # From linux/usb/tmc.h
    my $USBTMC_IOCTL_CLEAR = _IO( 91, 2 );
    my $fh = $self->filehandle();

    ioctl $fh, $USBTMC_IOCTL_CLEAR, 0
        or croak "ioctl 'USBTMC_IOCTL_CLEAR' failed: $!";
}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable();

1;
