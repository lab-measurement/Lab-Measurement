package Lab::Moose::DataFile::Gnuplot::2D;

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints 'enum';
use Data::Dumper;
use Carp;
use Scalar::Util 'looks_like_number';
use Lab::Moose::Plot;
use List::Util 'any';
use namespace::autoclean;

our $VERSION = '3.520';

extends 'Lab::Moose::DataFile::Gnuplot';

=head1 NAME

Lab::Moose::DataFile::Gnuplot::2D - 2D data file with live plotting support.

=head1 SYNOPSIS

 use Lab::Moose;

 my $folder = datafolder();
 
 my $file = datafile(
     type => 'Gnuplot::2D',
     folder => $folder,
     filename => 'gnuplot-file.dat',
     columns => [qw/time voltage temp/]
     );

  $file->add_plot(
     x => 'time',
     y => 'voltage',
     curve_options => {with => 'points'}
  );
   
  $file->add_plot(
      x => 'time'
      y => 'temp',
  );

 $file->log(time => 1, voltage => 2, temp => 3);

=head1 DESCRIPTION

This submodule of L<Lab::Moose::DataFile::Gnuplot> provides live plotting of 2D
data with gnuplot. It requires L<PDL::Graphics::Gnuplot> installed.

=cut

# Refresh plots.
after 'log' => sub {
    my $self = shift;
    if ( $self->num_data_rows() >= 2 ) {
        my @plots = keys %{ $self->plots() };
        my @refresh = grep { $self->plot_refresh()->{$_} eq 'auto' } @plots;
        $self->refresh_plots( names => \@refresh );
    }
};

has plots => (
    is       => 'ro',
    isa      => 'HashRef[Lab::Moose::Plot]',
    default  => sub { {} },
    init_arg => undef
);

# Columns which are used for each plot.
has plot_columns => (
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    default  => sub { {} },
    init_arg => undef
);

has plot_refresh => (
    is       => 'ro',
    isa      => 'HashRef[Str]',
    default  => sub { {} },
    init_arg => undef
);

=head1 METHODS

This module inherits all methods of L<Lab::Moose::DataFile::Gnuplot>.

=head2 add_plot

 $file->add_plot(
     name => 'voltage-plot',
     x => 'x-column',
     y => 'y-column',
     terminal => 'png',
     terminal_options => {output => 'myplot.png'},
     plot_options => {grid => 1, xlabel => 'voltage', ylabel => 'current'},
     curve_options => {with => 'points'},
     refresh => 'manual'
 );

Add a new live plot to the datafile. Options:

=over

=item * name

Identifier for the plot. Only needed if the datafile has several plots and you
want to update them indepentently of each other.

=item * x (mandatory)

Name of the column which is used for the x-axis.

=item * y (mandatory)

Name of the column which is used for the y-axis.

=item * terminal

gnuplot terminal. Default is qt.

=item * terminal_options

HashRef of terminal options. For the qt and x11 terminals, this defaults to
C<< {persist => 1, raise => 0} >>.

=item * plot_options

HashRef of plotting options (See L<PDL::Graphics::Gnuplot> for the complete
list).

=item * curve_options

HashRef of curve options (See L<PDL::Graphics::Gnuplot> for the complete
list).

=item * refresh

If set to 'auto' (default), the plot is updated whenever a new line is logged.
If set to 'manual', the user has to call C<refresh_plot> or C<refresh_plots> to
refresh the plot.

=back

=cut

sub add_plot {
    my ( $self, %args ) = validated_hash(
        \@_,
        name             => { isa => 'Str',     optional => 1 },
        x                => { isa => 'Str' },
        y                => { isa => 'Str' },
        terminal         => { isa => 'Str',     optional => 1 },
        terminal_options => { isa => 'HashRef', optional => 1 },
        plot_options     => { isa => 'HashRef', optional => 1 },
        curve_options    => { isa => 'HashRef', optional => 1 },
        refresh => { isa => enum( [qw/auto manual/] ), default => 'auto' },
    );
    my $name = delete $args{name};

    if ( not defined $name ) {
        $name = _random_plot_name();
    }
    my $plots = $self->plots();

    if ( exists $plots->{$name} ) {
        croak "plot name '$name' is already in use";
    }

    my $x_column = delete $args{x};
    my $y_column = delete $args{y};

    for my $column ( $x_column, $y_column ) {
        if ( not any { $column eq $_ } @{ $self->columns } ) {
            croak "column $column does not exist";
        }
    }

    if ( $x_column eq $y_column ) {
        croak "need different columns for x and y";
    }

    my $refresh = delete $args{refresh};
    my $plot    = Lab::Moose::Plot->new(%args);

    $plots->{$name} = $plot;

    $self->plot_columns()->{$name} = { x => $x_column, y => $y_column };
    $self->plot_refresh()->{$name} = $refresh;
}

=head2 refresh_plot

 $file->refresh_plot(name => $name);

Refresh the plot with name C<$name>. Only useful for plots, which have the
'refresh' option set to 'manual'.

=cut

sub refresh_plot {
    my $self = shift;
    my ($name) = validated_list(
        \@_,
        name => { isa => 'Str' },
    );
    my $plots = $self->plots();
    my $plot  = $plots->{$name};
    if ( not defined $plot ) {
        croak "no plot with name '$name'";
    }

    my $column_names = $self->columns();
    my $plot_columns = $self->plot_columns()->{$name};
    my ( $x, $y ) = @$plot_columns{qw/x y/};

    my ($x_index) = grep { $column_names->[$_] eq $x } 0 .. $#{$column_names};

    my ($y_index) = grep { $column_names->[$_] eq $y } 0 .. $#{$column_names};

    my $data_columns
        = $self->read_2d_gnuplot_format( fh => $self->filehandle() );

    $plot->plot(
        data => [ $data_columns->[$x_index], $data_columns->[$y_index] ],
    );
}

=head2 refresh_plots

 $file->refresh_plots(names => [@names]);
 $file->refresh_plots();

Call C<refresh_plot> for each name in C<@names>.

If C<names> is not set, refresh all plots.

=cut

sub refresh_plots {
    my $self = shift;
    my ($names) = validated_list(
        \@_,
        names => { isa => 'ArrayRef[Str]', optional => 1 },
    );

    if ( not defined $names ) {
        $names = [ keys %{ $self->plots() } ];
    }

    for my $name ( @{$names} ) {
        $self->refresh_plot( name => $name );
    }
}

sub _random_plot_name {
    my $name = "";
    my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
    for ( 1 .. 8 ) {
        $name .= $chars[ rand @chars ];
    }
    return $name;
}

__PACKAGE__->meta->make_immutable();

1;
