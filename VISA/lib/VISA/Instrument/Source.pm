#$Id$
package VISA::Instrument::Source;
use strict;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	my $self = {};
    bless ($self, $class);

	return $self
}

sub configure {
	my $self=shift;
	my $config=shift;

	for my $conf_name (keys %{$self->{default_config}}) {
		unless ((defined($self->{config}->{$conf_name})) || (defined($config->{$conf_name}))) {
			$self->{config}->{$conf_name}=$self->{default_config}->{$conf_name};
		} elsif (defined($self->{config}->{$conf_name})) {
			$self->{config}->{$conf_name}=$config->{$conf_name};
		}
	}
}

sub set_voltage {
	my $self=shift;
	return $self->_set_voltage(@_);
}

sub _set_voltage {
	warn '_set_voltage not implemented for this instrument';
}

sub get_voltage {
	warn '_set_voltage not implemented for this instrument';
}

sub get_range() {
	warn '_set_voltage not implemented for this instrument';
}

sub set_range() {
	warn '_set_voltage not implemented for this instrument';
}

1;

=head1 NAME

VISA::Instrument::Source - Base class for voltage source instruments

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($source_num)

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_value($value)

=head2 get_value()

=head2 get_number()

=head2 get_full_range()

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item DB2Kconnector

The NGsource class uses the DB2Kconnector module (L<DB2Kconnector>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
