#!/usr/bin/perl -w

#$Id$

package Lab::Data::Meta;

use strict;
use Lab::Data::XMLtree;
require Exporter;

our @ISA = qw(Exporter Lab::Data::XMLtree);

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

our $AUTOLOAD;

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

my $declaration = {
    data_complete           => ['SCALAR'],

    dataset_title           => ['SCALAR'],
    dataset_description     => ['SCALAR'],
    data_file               => ['SCALAR'],#     relativ zur descriptiondatei

    block                   => [
        'ARRAY',
        'id',
        {
            original_filename   => ['SCALAR'],
            timestamp           => ['SCALAR'],
            comment             => ['SCALAR']
        }
    ],
    column                  => [
        'ARRAY',
        'id',
        {
            unit        => ['SCALAR'],
            label       => ['SCALAR'],
            description => ['SCALAR'],
            min         => ['SCALAR'],
            max         => ['SCALAR']
        }
    ],
    axis                    => [
        'HASH',
        'label',
        {
            unit        => ['SCALAR'],
            logscale    => ['SCALAR'],
            expression  => ['SCALAR'],
            min         => ['SCALAR'],
            max         => ['SCALAR'],
            description => ['SCALAR']
        }
    ],
};

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $class->SUPER::new($declaration,@_), $class;
}

sub save {
    my $self = shift;
    my $filename = shift;
    $self->save_xml($filename,$self,'metadata');
}

1;

__END__

=head1 NAME

Lab::Data::Meta - Meta data for datasets

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new([$config][,$basepathname])

=head1 METHODS

=head2 Description Methods done via AUTOLOAD

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
