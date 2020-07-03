package Lab::Moose::Connection::VISA_GPIB;

#ABSTRACT: compatiblity alias for VISA::GPIB

use v5.20;

use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Connection::VISA::GPIB';

__PACKAGE__->meta->make_immutable();

1;
