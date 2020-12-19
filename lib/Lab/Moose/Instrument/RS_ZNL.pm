package Lab::Moose::Instrument::RS_ZNL;

#ABSTRACT: Rohde & Schwarz ZNL Vector Network Analyzer

use v5.20;

use Moose;

extends 'Lab::Moose::Instrument::RS_ZVA';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x0957, pid => 0x8b18 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

=head1 SYNOPSIS

 my $data = $znl->sparam_sweep(timeout => 10);

=cut

=head1 METHODS

See L<Lab::Moose::Instrument::VNASweep> for the high-level C<sparam_sweep> and
C<sparam_catalog> methods.

=cut

__PACKAGE__->meta->make_immutable();

1;

