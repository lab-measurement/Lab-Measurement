package Lab::BlockData;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;

use Carp;

use Data::Dumper;
use namespace::autoclean -also => [qw/_rows_equal _get_vector_param/];

our $VERSION = '3.512';

sub _rows_equal {
    my $matrix = shift;

    my $rows = @{$matrix};

    my $columns = @{ $matrix->[0] };

    for my $row ( @{$matrix} ) {
        if ( @{$row} != $columns ) {
            return;
        }
    }

    return 1;
}

subtype 'Lab::BlockData::Natural', as 'Int', where { $_ >= 0 };

# A vector is a non-empty ArrayRef.
subtype 'Lab::BlockData::Vector', as 'ArrayRef', where { @{$_} > 0 };

subtype 'Lab::BlockData::Matrix',
  as 'Lab::BlockData::Vector[Lab::BlockData::Vector[Num]]',
  where { _rows_equal($_) },
  message { "rows have different length: " . Dumper($_) };

has 'matrix' => (
    is        => 'ro',
    isa       => 'Lab::BlockData::Matrix',
    predicate => 'has_matrix',
    writer    => '_matrix',
);

has 'rows' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    writer   => '_rows'
);

has 'columns' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    writer   => '_columns'
);

sub BUILD {
    my $self = shift;

    if ( not $self->has_matrix ) {
        return;
    }

    my $matrix  = $self->matrix();
    my $rows    = @{$matrix};
    my $columns = @{ $matrix->[0] };
    $self->_rows($rows);
    $self->_columns($columns);
}

sub row {
    my $self = shift;

    if ( not $self->has_matrix ) {
        croak "calling method 'row' before adding data";
    }

    my ($row) = pos_validated_list( \@_, { isa => 'Lab::BlockData::Natural' } );
    my $rows = $self->rows();
    if ( $row >= $rows ) {
        croak sprintf( "row '$row' is out of range (0..%d)", $rows - 1 );
    }

    my $matrix = $self->matrix();

    return @{ $matrix->[$row] };
}

sub column {
    my $self = shift;

    if ( not $self->has_matrix ) {
        croak "calling method 'column' before adding data";
    }

    my ($column) =
      pos_validated_list( \@_, { isa => 'Lab::BlockData::Natural' } );
    my $columns = $self->columns();

    if ( $column >= $columns ) {
        croak
          sprintf( "column '$column' is out of range (0..%d)", $columns - 1 );
    }

    my $matrix = $self->matrix();

    my @column;
    for my $row ( @{$matrix} ) {
        push @column, $row->[$column];
    }

    return @column;
}

sub _get_vector_param {
    my $args = shift;

    my ($vector) =
      pos_validated_list( $args, { isa => 'Lab::BlockData::Vector[Num]' } );

    return $vector;
}

sub add_row {
    my $self = shift;
    my $row  = _get_vector_param( \@_ );

    if ( not $self->has_matrix ) {
        $self->_matrix( [$row] );
        $self->_rows(1);
        $self->_columns( scalar @{$row} );
        return;
    }

    my $columns = $self->columns();
    my $entries = @{$row};

    if ( $columns != $entries ) {
        croak sprintf( "expected row with %d entries, got %d entries",
            $columns, $entries );
    }

    my $matrix = $self->matrix();
    push @{$matrix}, $row;
    my $rows = $self->rows();
    $self->_rows( ++$rows );
}

sub add_column {
    my $self   = shift;
    my @column = @{ _get_vector_param( \@_ ) };

    if ( not $self->has_matrix ) {
        my @matrix;
        for my $num (@column) {
            push @matrix, [$num];
        }
        $self->_matrix( [@matrix] );
        $self->_rows( scalar @column );
        $self->_columns(1);
        return;
    }

    my $rows    = $self->rows();
    my $entries = @column;

    if ( $rows != $entries ) {
        croak sprintf( "expected column with %d entries, got %d entries",
            $rows, $entries );
    }

    my $matrix = $self->matrix();

    for my $row ( @{$matrix} ) {
        my $entry = shift @column;
        push @{$row}, $entry;
    }

    my $columns = $self->columns();
    $self->_columns( ++$columns );
}

sub print_to_file {
    my ( $self, %args ) = validated_hash(
        \@_,
        file      => { isa => 'Str' },
        overwrite => { isa => 'Bool', default => 0 },
        append    => { isa => 'Bool', default => 0 },
    );

    my $file      = $args{file};
    my $overwrite = $args{overwrite};
    my $append    = $args{append};

    if ( not $self->has_matrix() ) {
        croak "do not have matrix";
    }

    if ( $overwrite && $append ) {
        croak "cannot use both overwrite and append options";
    }

    if ( !( $overwrite || $append ) && -f $file ) {
        croak "file $file does already exist. Use a new filename!";
    }

    my $open_mode = $append ? '>>' : '>';

    open my $fh, $open_mode, $file
      or croak "cannot open file: $!";
    my $matrix = $self->matrix;
    for my $row ( @{$matrix} ) {
        for my $real_number ( @{$row} ) {

            # Avoid ascii -> binary -> ascii conversion.
            printf {$fh} "%s ", $real_number;
        }
        print {$fh} "\n";
    }
    close $fh
      or croak "cannot close";
}

__PACKAGE__->meta->make_immutable();

1;

