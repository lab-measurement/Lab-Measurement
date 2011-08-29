
package Lab::Instrument::Multimeter;

use strict;
use Scalar::Util qw(weaken);
use Lab::Instrument;
use Carp;
use Data::Dumper;


our @ISA = ("Lab::Instrument");

our %fields = (
	supported_connections => [ ],

	device_settings => {
	},

);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->_construct(__PACKAGE__, \%fields);
	return $self;
}




sub id {
    my $self=shift;
    return $self->_id();
}

sub _id {
    die "id not implemented for this instrument\n";
}


sub get_value {
    my $self=shift;
    my $value=$self->_get_value();
    chomp $value;
    return $value;
}

sub _get_value{
    die "get_value not implemented for this instrument\n";
}

1;









=head1 NAME

Lab::Instrument::Multimeter - Generic digital multimeter interface

=head1 DESCRIPTION

The Lab::Instrument::Multmeter class implements a generic interface to
digital all-purpose multimeters. It is intended to be inherited by other
classes, not to be called directly.

=head1 CONSTRUCTOR

    my $Agi=new(\%options);

=head1 METHODS

=head2 get_value

    $value=$Agi->get_value();

Read out the current measurement value, for whatever type of measurement
the multimeter is currently configured.
Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 id

    $id=$Agi->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>
=item L<Lab::Instrument:HP34401A>

=back

=head1 AUTHOR/COPYRIGHT

Copyright 2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
