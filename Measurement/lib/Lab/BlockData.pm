package Lab::BlockData;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw/:all/;
use MooseX::Params::Validate;
use Scalar::Util qw/looks_like_number/;
use Carp;

use Data::Dumper;
use namespace::autoclean -also => [
    qw/
      _rows_equal
      _get_vector_param
      _is_vector
      _is_num_vector
      _is_matrix
      /
];

our $VERSION = '3.520';

sub _rows_equal {
    my $matrix = shift;

    my $rows = @{$matrix};

    my $columns = @{ $matrix->[0] };

    for my $row ( @{$matrix} ) {
        if ( @{$row} != $columns ) {
            carp 'rows not equal';
            return;
        }
    }

    return 1;
}

# One can also do the following stuff with parametrized Moose types. But that
# turns out to be a lot slower.

# return true, if ref to non-empty array.
sub _is_vector {
    my $ref = shift;

    if ( ref $ref ne 'ARRAY' ) {
        carp "vector ain't arrayref";
        return;
    }

    if ( @{$ref} < 1 ) {
        carp "empty vector";
        return;
    }

    return 1;
}

sub _is_num_vector {
    my $ref = shift;
    if ( not _is_vector($ref) ) {
        return;
    }

    for my $num ( @{$ref} ) {
        if ( not looks_like_number($num) ) {
            carp "'$num' not a num in num_vector";
            return;
        }
    }

    return 1;
}

sub _is_matrix {
    my $matrix = shift;
    if ( not _is_vector($matrix) ) {
        return;
    }

    for my $row ( @{$matrix} ) {
        _is_num_vector($row) || return;
    }

    _rows_equal($matrix) || return;

    return 1;
}

subtype 'Lab::BlockData::Natural', as 'Int', where { $_ >= 0 };

# A vector is a non-empty ArrayRef.
subtype 'Lab::BlockData::Vector', as 'Ref', where { _is_vector($_) };

has 'matrix' => (
    is        => 'ro',
    isa       => subtype( 'Ref' => where { _is_matrix($_) } ),
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
      pos_validated_list( $args,
        { isa => subtype( 'Ref' => where { _is_num_vector($_) } ) } );

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

