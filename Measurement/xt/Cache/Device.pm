package Device;

use lib '../../lib';
use Moose;

extends 'Lab::MooseInstrument';

with 'Lab::HasDeviceCache';

sub BUILD {
    my $self = shift;
    $self->cache_declare(
	id => {getter => 'id'}
	);
}
    
sub id {
    my $self = shift;
    return $self->query(
	command => '*IDN?',
	timeout => 3,
	read_length => 10000);
}

__PACKAGE__->meta->make_immutable;

1;
