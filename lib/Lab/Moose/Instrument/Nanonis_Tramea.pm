package Lab::Moose::Instrument::Nanonis_Tramea;

#ABSTRACT: Nanonis Tramea quantum measurement system

use v5.20;


use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';


=head1 SYNOPSIS

 ...

=head1 LOW-LEVEL HELPERS

These helpers encapsulate the binary data types as given in the Nanonis manual:

 All numeric values are sent in binary form (e.g. a 32 bit integer is encoded 
 in 4 bytes). The storage method of binary encoded numbers is big-endian, that
 is, the most significant byte is stored at the lowest address.

=head2 nt_hstring($s)

32byte string, padded with zero bytes.

=cut

sub nt_hstring {
  my $s = shift;
  $s=substr $s, 0, 32;
  return $s . ( \0 x (32 - length $s));
}

=head2 nt_string($s)

Variable length string, prefixed with a 32bit integer which gives the length
in bytes.

=cut

sub nt_string {
  my $s = shift;
  return (pack "N", length($s)) . $s;
}

=head2 nt_int($i)

32bit signed integer

=cut

sub nt_int {
  my $i = shift;
  return pack "N!", $i;
}

=head2 nt_uint16($i)

16bit unsigned integer

=cut

sub nt_uint16 {
  my $i = shift;
  return pack "n", $i;
}

=head2 nt_uint32($i)

32bit unsigned integer

=cut

sub nt_uint32 {
  my $i = shift;
  return pack "N", $i;
}

=head2 nt_float32($f)

32bit (single precision) floating point number

=cut

sub nt_float32 {
  my $f = shift;
  return pack "f>", $f;
}

=head2 nt_float64($f)

64bit (double precision) floating point number

=cut

sub nt_float64 {
  my $f = shift;
  return pack "d>", $f;
}

=head2 nt_header($command, $bodysize, $respond)

=cut

sub nt_header {
  my $command = shift;
  my $bodysize = shift;
  my $respond = shift;
  return nt_hstring($command) . nt_int($bodysize) . nt_uint16($respond);
}

=head1 METHODS

This driver implements the following high-level methods:

=head2 get_point (to be done)

=head2 get_sweep (to be done)

Perform a single sweep and return the resulting spectrum as a 2D PDL:

 [
  [volt1,  volt2,  volt3,  ..., voltN],
  [value1, value2, value3, ..., valueN],
 ]

I.e. the first dimension runs over the sweep points.




=cut




__PACKAGE__->meta()->make_immutable();

1;
