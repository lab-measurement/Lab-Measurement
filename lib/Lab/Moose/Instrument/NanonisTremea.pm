package Lab::Moose::Instrument::NanonisTremea;

use v5.20;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Carp;
use namespace::autoclean;

use Lab::Moose::Instrument qw/     
    validated_getter validated_setter setter_params /;


extends 'Lab::Moose::Instrument';



sub nt_hstring {
  my $s = shift;
  $s=substr $s, 0, 32;
  return $s . ( \0 x (32 - length $s));
}


sub nt_string {
  my $s = shift;
  return (pack "N", length($s)) . $s;
}

sub nt_int {
  my $i = shift;
  return pack "N!", $i;
}

sub nt_uint16 {
  my $i = shift;
  return pack "n", $i;
}

sub nt_uint32 {
  my $i = shift;
  return pack "N", $i;
}


sub nt_float32 {
  my $f = shift;
  return pack "f>", $f;
}

sub nt_float64 {
  my $f = shift;
  return pack "d>", $f;
}

sub  header_write{
    my ($self,$command) = @_;
    $command = lc($command);

    my ($pad_len) = 32 - length($command);
   
    my($template)="A".length($command);

    for (1..$pad_len){

        $template=$template."x"
    }
    my $packed= pack($template,$command); 
    $self->write(command=>$packed);
}

__PACKAGE__->meta()->make_immutable();

1;