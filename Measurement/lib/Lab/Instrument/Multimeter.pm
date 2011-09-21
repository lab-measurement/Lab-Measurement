
package Lab::Instrument::Multimeter;
our $VERSION = '2.92';

use strict;
use Lab::Instrument;


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


# template functions for inheriting classes

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


sub display_on {
    my $self=shift;
    $self->_display_on();
}

sub _display_on{
    die "display_on not implemented for this instrument\n";
}


sub display_off {
    my $self=shift;
    $self->_display_off();
}

sub _display_off{
    die "display_off not implemented for this instrument\n";
}


sub display_clear {
    my $self=shift;
    $self->_display_clear();
}

sub _display_clear{
    die "display_clear not implemented for this instrument\n";
}


sub display_text {
    my $self=shift;
    my $text=shift;
    $self->_display_text($text);
}

sub _display_text{
    die "display_text not implemented for this instrument\n";
}


sub selftest {
    my $self=shift;
    $self->_selftest();
}

sub _selftest{
    die "selftest not implemented for this instrument\n";
}



sub configure_voltage_measurement{
    my $self=shift;
    my $range=shift; # in V, or "AUTO"
    my $tint=shift;  # in sec
    $self->_configure_voltage_measurement($range,$tint);
}

sub _configure_voltage_measurement{
    die "configure_voltage_measurement not implemented for this instrument\n";
}


1;


=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::Multimeter - Generic digital multimeter interface

=head1 DESCRIPTION

The Lab::Instrument::Multmeter class implements a generic interface to
digital all-purpose multimeters. It is intended to be inherited by other
classes, not to be called directly, and provides a set of generic functions.
The class

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head2 get_value

    $value=$hp->get_value();

Read out the current measurement value, for whatever type of measurement
the multimeter is currently configured.

=head2 id

    $id=$hp->id();

Returns the instruments ID string.

=head2 display_on

    $hp->display_on();

Turn the front-panel display on.

=head2 display_off

    $hp->display_off();

Turn the front-panel display off.

=head2 display_text

    $hp->display_text($text);

Display a message on the front panel. 

=head2 display_clear

    $hp->display_clear();

Clear the message displayed on the front panel.


=head1 CAVEATS/BUGS

none known so far :)

=head1 SEE ALSO

=over 4

=item * L<Lab::Instrument>

=item * L<Lab::Instrument:HP34401A>

=item * L<Lab::Instrument:HP3458A>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
