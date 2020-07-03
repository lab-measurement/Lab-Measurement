package Lab::Moose::Instrument::Agilent34410A;

#ABSTRACT: Agilent 34410A digital multimeter.

use v5.20;

=head1 DESCRIPTION

Alias for L<Lab::Moose::Instrument::HP34410A> with adjusted USB vendor/product IDs.

=cut

use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Instrument::HP34410A';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x0957, pid => 0x0607 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

__PACKAGE__->meta()->make_immutable();

1;
