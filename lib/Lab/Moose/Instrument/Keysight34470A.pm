package Lab::Moose::Instrument::Keysight34470A;

#ABSTRACT: Keysight 34470A digital multimeter.

use v5.20;

=head1 DESCRIPTION

Inherits from L<Lab::Moose::Instrument::HP34410A>

=cut

use warnings;
use strict;

use Moose;

extends 'Lab::Moose::Instrument::HP34410A';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x2a8d, pid => 0x0201 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

__PACKAGE__->meta()->make_immutable();

1;

