package Lab::Moose::DataFile::Gnuplot;

#ABSTRACT: Text based data file ('Gnuplot style')

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints 'enum';
use PDL::Core qw/topdl/;
use Data::Dumper;
use Carp;
use Scalar::Util 'looks_like_number';
use Lab::Moose::Plot;
use Lab::Moose::DataFile::Read;
use List::Util 'any';
use namespace::autoclean;

extends 'Lab::Moose::DataFile';

has columns => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has num_data_rows => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    writer   => '_num_data_rows',
    init_arg => undef
);

has precision => (
    is      => 'ro',
    isa     => enum( [ 1 .. 17 ] ),
    default => 10,
);

has plots => (
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { [] },
    init_arg => undef
);

sub BUILD {
    my $self    = shift;
    my @columns = @{ $self->columns() };
    if ( @columns == 0 ) {
        croak "need at least one column";
    }
    $self->log_comment( comment => join( "\t", @columns ) );
}

=head1 SYNOPSIS

 use Lab::Moose;

 my $folder = datafolder();

 # datafile with two simple 2D plots:

 my $file = datafile(
     type => 'Gnuplot',
     folder => $folder,
     filename => 'gnuplot-file.dat',
     columns => [qw/time voltage temp/]
     );

  $file->add_plot(
     x => 'time',
     y => 'voltage',
     curve_options => {with => 'points'},
     hard_copy => 'gnuplot-file-T-V.png',
  );
   
  $file->add_plot(
      x => 'time',
      y => 'temp',
      hard_copy => 'gnuplot-file-T-Temp.png',
  );

 $file->log(time => 1, voltage => 2, temp => 3);


=head1 METHODS

=head2 new

Supports the following attributtes in addition to the L<Lab::Moose::DataFile>
requirements:

=over

=item * columns

(mandatory) arrayref of column names

=item * precision 

The numbers are formatted with a C<%.${precision}g> format specifier. Default
is 10.

=back

=head2 log

 $file->log(column1 => $value1, column2 => $value2, ...);
 
Log one line of data.

=cut

sub log {
    my $self = shift;
    $self->_log_bare(@_);
    $self->_trigger_plots();
}

# Bare logging. Do not trigger plots.
sub _log_bare {

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
        my $precision = $self->precision();
        $line .= sprintf( "%.${precision}g", $value );
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

    my $num = $self->num_data_rows;
    $self->_num_data_rows( ++$num );
}

=head2 log_block

 $file->log_block(
     prefix => {column1 => $value1, ...},
     block => $block,
     add_newline => 0
 );

Log a 1D or 2D PDL or array ref. The first dimension runs over the datafile
rows. You can add prefix columns, which will be the same for each line in the
block. E.g. when using a spectrum analyzer inside a voltage sweep, one would
log the returned PDL prefixed with the sweep voltage.

=cut

sub log_block {
    my $self = shift;
    my ( $prefix, $block, $add_newline ) = validated_list(
        \@_,
        prefix      => { isa => 'HashRef[Num]', optional => 1 },
        block       => {},
        add_newline => { isa => 'Bool',         default  => 1 }
    );

    $block = topdl($block);

    my @dims = $block->dims();

    if ( @dims == 1 ) {
        $block = $block->dummy(1);
        @dims  = $block->dims();
    }
    elsif ( @dims != 2 ) {
        croak "log_block needs 1D or 2D piddle";
    }

    my $num_prefix_cols = $prefix ? ( keys %{$prefix} ) : 0;
    my $num_block_cols = $dims[1];

    my @columns = @{ $self->columns() };

    my $num_cols = @columns;

    if ( $num_prefix_cols + $num_block_cols != $num_cols ) {
        croak "need $num_cols columns, got $num_prefix_cols prefix columns"
            . " and $num_block_cols block columns";
    }

    my $num_rows = $dims[0];
    for my $i ( 0 .. $num_rows - 1 ) {
        my %log;

        # Add prefix columns to %log.
        for my $j ( 0 .. $num_prefix_cols - 1 ) {
            my $name = $columns[$j];
            $log{$name} = $prefix->{$name};
        }

        # Add block columns to %log.
        for my $j ( 0 .. $num_block_cols - 1 ) {
            my $name = $columns[ $j + $num_prefix_cols ];
            $log{$name} = $block->at( $i, $j );
        }
        $self->_log_bare(%log);
    }

    if ($add_newline) {
        $self->log_newline();
    }
    $self->_trigger_plots();
}

=head2 log_newline

 $file->log_newline();

print "\n" to the datafile.

=cut

sub log_newline {
    my $self = shift;
    my $fh   = $self->filehandle;
    print {$fh} "\n";
}

=head2 log_comment

 $file->log_comment(comment => $string);

log a comment string, which will be prefixed with '#'. If C<$string> contains
newline characters, several lines of comments will be written.

=cut

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

# Refresh plots after log/log_block
sub _trigger_plots {
    my $self = shift;

    if ( $self->num_data_rows() < 2 ) {
        return;
    }

    my @plots = @{ $self->plots() };
    my @indices = grep { not defined $plots[$_]->{handle} } ( 0 .. $#plots );
    for my $index (@indices) {
        $self->_refresh_plot( index => $index );
    }
}

=head2 add_plot

 $file->add_plot(
     x => 'x-column',
     y => 'y-column',
     plot_options => {grid => 1, xlabel => 'voltage', ylabel => 'current'},
     curve_options => {with => 'points'},
     hard_copy => 'myplot.png',
     hard_copy_terminal => 'svg',
 );

Add a new live plot to the datafile. Options:

=over

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

=item * handle

Set this to a string, if you need to refresh the plot manually with the
C<refresh_plots> option. Multiple plots can share the same handle string.

=item * hard_copy        

Create a copy of the plot in the data folder.

=item * hard_copy_terminal

Terminal for hard_copy option. Use png terminal by default. The 'output'
terminal option must be supported.

=back

=cut

sub add_plot {
    my ( $self, %args ) = validated_hash(
        \@_,
        x                  => { isa => 'Str' },
        y                  => { isa => 'Str' },
        terminal           => { isa => 'Str', optional => 1 },
        terminal_options   => { isa => 'HashRef', optional => 1 },
        plot_options       => { isa => 'HashRef', optional => 1 },
        curve_options      => { isa => 'HashRef', optional => 1 },
        handle             => { isa => 'Str', optional => 1 },
        hard_copy          => { isa => 'Str', optional => 1 },
        hard_copy_terminal => { isa => 'Str', optional => 1 },
    );
    my $plots = $self->plots();

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

    my $handle = $args{handle};

    push @{$plots}, {
        plot   => $plot,
        x      => $x_column,
        y      => $y_column,
        handle => $handle
    };

    # add hard copy plot
    my $hard_copy = delete $args{hard_copy};
    if ( defined $hard_copy ) {
        my $hard_copy_file = Lab::Moose::DataFile->new(
            folder   => $self->folder(),
            filename => $hard_copy,
        );

        delete $args{terminal};
        delete $args{terminal_options};

        my $hard_copy_terminal = delete $args{hard_copy_terminal};
        my $terminal
            = defined($hard_copy_terminal) ? $hard_copy_terminal : 'png';

        $self->add_plot(
            x                => $x_column,
            y                => $y_column,
            terminal         => $terminal,
            terminal_options => { output => $hard_copy_file->path() },
            %args,
        );
    }
}

sub _refresh_plot {
    my $self = shift;
    my ($index) = validated_list(
        \@_,
        index => { isa => 'Int' },
    );

    my $plots = $self->plots();
    my $plot  = $plots->[$index];

    if ( not defined $plot ) {
        croak "no plot with name at index $index";
    }

    my $column_names = $self->columns();
    my ( $x, $y ) = ( $plot->{x}, $plot->{y} );

    my ($x_index) = grep { $column_names->[$_] eq $x } 0 .. $#{$column_names};

    my ($y_index) = grep { $column_names->[$_] eq $y } 0 .. $#{$column_names};

    my $data_columns = read_2d_gnuplot_format( fh => $self->filehandle() );

    $plot->{plot}->plot(
        data => [ $data_columns->[$x_index], $data_columns->[$y_index] ],
    );
}

=head2 refresh_plots

 $file->refresh_plots(handle => $handle);
 $file->refresh_plots();

Call C<refresh_plot> for each plot with hanle C<$handle>.

If the C<handle> argument is not given, refresh all plots.

=cut

sub refresh_plots {
    my $self = shift;
    my ($handle) = validated_list(
        \@_,
        handle => { isa => 'Str', optional => 1 },
    );

    my @plots = @{ $self->plots() };

    my @indices;

    if ( defined $handle ) {
        for my $index ( 0 .. $#plots ) {
            my $plot = $plots[$index];
            if ( defined $plot->{handle} and $plot->{handle} eq $handle ) {
                push @indices, $index;
            }
        }

        if ( !@indices ) {
            croak "no plot with handle $handle";
        }
    }

    else {
        @indices = ( 0 .. $#plots );
    }

    for my $index (@indices) {
        $self->_refresh_plot( index => $index );
    }
}

__PACKAGE__->meta->make_immutable();

1;
