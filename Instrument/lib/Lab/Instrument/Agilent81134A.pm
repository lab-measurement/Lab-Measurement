#$Id$

package Lab::Instrument::Agilent81134A;

use strict;
use Lab::Instrument;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self
}

1;

=head1 NAME

Lab::Instrument::Agilent81134A - a Agilent 81134A pulse generator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2005 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
