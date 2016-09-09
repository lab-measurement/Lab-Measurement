=head1 NAME

Lab::HasDeviceCache - Role to add a device cache to a driver.

=head1 SYNOPSIS

 package Lab::MooseInstrument::SomeDriver;
 use Moose;
  
  with 'Lab::HasDeviceCache';
  
  sub BUILD {
      my $self = shift;
      $self->cache_declare(
          key1 => {getter => 'get_key1'},
 	 key2 => {getter => 'get_key2'},
 	 );
 }
 
 sub set_key1 {
     my $self = shift;
     ... ;
     $self->write(command => "key1 $value");
     $self->cache_set(key => 'key1', value => $value);
 }
 
 sub set_key2 {
     my $self = shift;
     ... ;
     my $current_value = $self->cache_get(value => 'key2');
     if ($current_value != $value) {
 	$self->write(command => "key2 $value");
 	$self->cache_set(key => 'key2', value => $value);
     }
 
 }
 
 1; 

=cut

package Lab::HasDeviceCache;
use 5.010;
use Moose::Role;
use MooseX::Params::Validate;

use Lab::DeviceCache;

use Lab::MooseInstrument qw(getter_params);

use namespace::autoclean;

our $VERSION = '3.512';

has 'device_cache' => (
    isa => 'Lab::DeviceCache',
    is => 'ro',
    builder => '_build_cache',
    predicate => 'has_device_cache',
    init_arg => undef
    );

sub _build_cache {
    my $self = shift;
    return Lab::DeviceCache->new(device => $self);
}

=head1 METHODS

=head2 cache_declare

 $self->cache_declare(
     key1 => {getter => 'get_key1'},
     key2 => {getter => 'key2_query'}
     );

Declare cache entries before use. Trying to get or set an undeclared cache
entry will croak.

=cut

sub cache_declare {
    my $self = shift;

    my $params = {@_};
    
    my $cache = $self->device_cache();
    
    $cache->declare(device => $self, params => $params);
}


=head2 cache_get

 $self->cache_get(key => 'key1', timeout => 3, read_length => 1000);

Read from the cache. If the cache's value is unset, this will call the getter
provided by C<cache_declare>.

=cut

sub cache_get {
    my ($self, %args) = validated_hash(
	\@_,
	key => { isa => 'Str' },
	getter_params(),
	);
    my $cache = $self->device_cache();
    my $key = delete $args{key};
    return $cache->get(device => $self, key => $key, %args);
}

=head2 cache_set

 $self->cache_set(key => 'key2', value => 'some data');

Set the value of a cache entry.

=cut

sub cache_set {
    my ($self, $key, $value) = validated_list(
	\@_,
	key => { isa => 'Str' },
	value => { isa => 'Str' }
	);
    my $cache = $self->device_cache();
    $cache->set(device => $self, key => $key, value => $value);
}



1;
