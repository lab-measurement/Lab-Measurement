package Lab::Moose::Connection::VISA_GPIB;

#ABSTRACT: compatiblity alias for VISA::GPIB

use 5.010;
use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Connection::VISA::GPIB';

__PACKAGE__->meta->make_immutable();

1;
