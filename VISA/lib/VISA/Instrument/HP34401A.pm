#$Id$

package VISA::Instrument::HP34401A;

use strict;
use VISA::Instrument;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

	$self->{vi}=new VISA::Instrument(@_);

	return $self
}

sub read_voltage_dc {
	my $self=shift;
	my $range=shift;
	my $resolution=shift;
	
	my $cmd=sprintf("MEASure:VOLTage:DC? %u,%f",$range,$resolution);
	my ($value)=split "\n",$self->{vi}->Query($cmd);
	return $value;
}

1;

=head1 NAME

VISA::Instrument::HP34401A - a HP 34401A digital multimeter

=head1 SYNOPSIS

    use VISA::Instrument::HP34401A;
    
    my $hp22=new VISA::Instrument::HP34401A(0,22);
	print $hp22->read_voltage_dc(10,0.00001);

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 read_voltage_dc($range,$resolution);

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item VISA::Instrument

The HP34401A uses the VISA::Instrument class (L<VISA::Instrument>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
