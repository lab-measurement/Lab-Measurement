#$Id$
package Lab::Instrument::Source;
use strict;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

my $default_config={};

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $def_conf=shift;
    my @args=@_;
    for my $conf_name (keys %{$def_conf}) {
        $default_config->{$conf_name}=$def_conf->{$conf_name};
    }

    my $self = {};
    bless ($self, $class);
    
    $self->configure(@args);

    return $self
}

sub configure {
    my $self=shift;
    my $config=shift;

    for my $conf_name (keys %{$default_config}) {
        unless ((defined($self->{config}->{$conf_name})) || (defined($config->{$conf_name}))) {
            $self->{config}->{$conf_name}=$default_config->{$conf_name};
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
    warn 'get_voltage not implemented for this instrument';
}

sub get_range() {
    warn 'get_range not implemented for this instrument';
}

sub set_range() {
    warn 'set_range not implemented for this instrument';
}

1;

=head1 NAME

Lab::Instrument::Source - Base class for voltage source instruments

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($default_config,$config)

=head1 METHODS

=head2 configure($config)

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
