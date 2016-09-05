package Lab::DeviceCache;
use 5.010;

use Moose;
use MooseX::Params::Validate;
use Scalar::Util 'refaddr';
use Carp;

use Lab::MooseInstrument 'getter_params';

use namespace::autoclean;

has 'device' => (
    is => 'ro',
    isa => 'Object',
    required => 1,
    );

has 'cache' => (
    is => 'ro',
    predicate => 'has_cache',
    init_arg => undef,
    writer => '_cache',
);


sub _assert_correct_device {
    my ($self, $device) = @_;

    if (refaddr $device != refaddr $self->device()) {
	croak 'wrong device';
    }
}

sub _assert_key {
    my ($self, $key) = @_;

    if (not exists $self->cache()->{$key}) {
	croak "key '$key' has not been declared";
    }
}

my @device_key_params = (
    device => { isa => 'Object' },
    key => { isa => 'Str' }
    );

sub set {
    my ($self, $device, $key, $value) = validated_list(
	\@_,
	@device_key_params,
	value => { isa => 'Str' },
	);

    $self->_assert_correct_device($device);
    
    my $cache = $self->cache();

    $self->_assert_key($key);
    
    $cache->{$key}{value} = $value;
}

sub get {
    my ($self, %args) = validated_hash(
	\@_,
	@device_key_params,
	getter_params(),
	);

    my $device = delete $args{device};
    $self->_assert_correct_device($device);
    
    my $key = delete $args{key};
    $self->_assert_key($key);
    
    my $hash = $self->cache()->{$key};

    if (not defined $hash->{value}) {
	# call getter
	my $getter = $hash->{getter};
	return $hash->{value} = $device->$getter(%args);
    }

    return $hash->{value};
}
    
sub declare {
    my ($self, $device, $params) = validated_list(
	\@_,
	device => { isa => 'Object' },
	params => { isa => 'HashRef[HashRef]' }
	);

    if (not $self->has_cache()) {
	$self->_cache({});
    }
    
    $self->_assert_correct_device($device);

    my %params = %{$params};

    
    my $cache = $self->cache();

    
    for my $key (keys %params) {
	if (exists $cache->{$key}) {
	    croak "key '$key' is already declared";
	}

	if (not exists $params{$key}{getter}) {
	    croak "missing 'getter' for key '$key'";
	}
	
	my $getter = $params{$key}{getter};
	
	if (not $device->can($getter)) {
	    croak "invalid getter '$getter'";
	}
	$cache->{$key} = $params{$key};
	$cache->{$key}{value} = undef;
    }
}


__PACKAGE__->meta->make_immutable();

1;
