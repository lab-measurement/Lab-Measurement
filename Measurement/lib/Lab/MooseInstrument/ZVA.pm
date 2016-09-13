package Lab::MooseInstrument::ZVA;
use 5.010;
use Moose;
use MooseX::Params::Validate;

use namespace::autoclean;

extends 'Lab::MooseInstrument';

with qw(
  Lab::MooseInstrument::Common

  Lab::MooseInstrument::SCPI::Calculate::Data

  Lab::MooseInstrument::SCPI::Sense::Frequency

  Lab::MooseInstrument::SCPI::Initiate

);

sub BUILD {
    my $self = shift;
    $self->clear();
}

1;
