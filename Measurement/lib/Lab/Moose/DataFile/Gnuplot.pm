package Lab::Moose::DataFile::Gnuplot;

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::BlockData;
use Data::Dumper;
use Carp;
use Scalar::Util 'looks_like_number';
use namespace::autoclean;

our $VERSION = '3.520';

extends 'Lab::Moose::DataFile';

has columns => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

sub BUILD {
    my $self    = shift;
    my @columns = @{ $self->columns() };
    if ( @columns == 0 ) {
        croak "need at least one column";
    }
    $self->log_comment( comment => join( "\t", @columns ) );
}

sub log {

    # We do not use MooseX::Params::Validate for performance reasons.
    my $self = shift;
    my %args;

    if ( ref $_[0] eq 'HASH' ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    my @columns = @{ $self->columns() };

    my $line = "";

    while ( my ( $idx, $column ) = each(@columns) ) {
        my $value = delete $args{$column};
        if ( not defined $value ) {
            croak "missing value for column '$column'";
        }
        if ( not looks_like_number($value) ) {
            croak "value '$value' for column '$column' isn't numeric";
        }

        $line .= sprintf( "%.17g", $value );
        if ( $idx != $#columns ) {
            $line .= "\t";
        }
    }
    $line .= "\n";

    if ( keys %args ) {
        croak "unknown colums in log call: ", join( ' ', keys %args );
    }

    my $fh = $self->filehandle();
    print {$fh} $line;
}

sub log_block {
    my $self = shift;
    my ( $prefix, $block, $add_newline ) = validated_list(
        \@_,
        prefix      => { isa => 'HashRef[Num]', optional => 1 },
        block       => { isa => 'Lab::Moose::BlockData' },
        add_newline => { isa => 'Bool',         default  => 1 }
    );

    my $num_prefix_cols = $prefix ? ( keys %{$prefix} ) : 0;
    my $num_block_cols = $block->columns();

    my @columns = @{ $self->columns() };

    my $num_cols = @columns;

    # Input validation is done by log method.

    my $num_rows = $block->rows();
    for my $i ( 0 .. $num_rows - 1 ) {
        my $row = $block->row($i);
        my %log;
        for my $j ( 0 .. $num_prefix_cols - 1 ) {
            my $name = $columns[$j];
            $log{$name} = $prefix->{$name};
        }
        for my $j ( 0 .. $num_block_cols - 1 ) {
            my $name = $columns[ $j + $num_prefix_cols ];
            $log{$name} = $row->[$j];
        }
        $self->log(%log);
    }

    if ($add_newline) {
        $self->log_newline();
    }
}

sub log_newline {
    my $self = shift;
    my $fh   = $self->filehandle;
    print {$fh} "\n";
}

sub log_comment {
    my $self = shift;
    my ($comment) = validated_list(
        \@_,
        comment => { isa => 'Str' }
    );
    my @lines = split( "\n", $comment );
    my $fh = $self->filehandle();
    for my $line (@lines) {
        print {$fh} "# $line\n";
    }
}

__PACKAGE__->meta->make_immutable();

1;
