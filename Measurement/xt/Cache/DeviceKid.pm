package DeviceKid;

use Moose;

use namespace::autoclean;

extends 'Device';

sub BUILD {
    my $self = shift;
    $self->cache_declare( lala_kid => { getter => 'lala_kid' }, );

}

sub lala_kid {
    return 'lala_kid';
}

__PACKAGE__->meta->make_immutable;

1;
