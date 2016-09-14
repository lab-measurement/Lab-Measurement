#!perl -T

use 5.010;
use warnings;
use strict;

use Test::More tests => 21;
use Test::Fatal;
use Data::Dumper;
use Lab::BlockData;
{
    my $data = Lab::BlockData->new( matrix => [ [ 1, 2, 3 ], [ 3, 4, 5 ] ] );

    isa_ok( $data, 'Lab::BlockData' );

    is( $data->rows,    2, 'get number of rows' );
    is( $data->columns, 3, 'get number of columns' );

    {
        my @row = $data->row(1);

        is_deeply( [@row], [ 3, 4, 5 ], "get row as array" );
    }

    {
        my @column = $data->column(2);

        is_deeply( [@column], [ 3, 5 ], "get column as array" );
    }

    # Add row

    {
        my $new_row = [ 6, 7, 8 ];
        $data->add_row($new_row);

        is( $data->rows(), 3, "row added" );

        my @row = $data->row(2);
    }

    # Add column
    {
        my $new_column = [ 10, 11, 12 ];
        $data->add_column($new_column);

        is( $data->columns(), 4, "column added" );

        my @column = $data->column(3);
        is_deeply( [@column], $new_column, "added column is intact" );
    }
}

# Add row to empty data
{
    my $data = Lab::BlockData->new();
    isa_ok( $data, 'Lab::BlockData' );
    my $row = [ 1, 2, 3 ];
    $data->add_row($row);

    is( $data->rows(),    1, "have one row" );
    is( $data->columns(), 3, "have three columns" );

    my @row = $data->row(0);
    is_deeply( [@row], $row, "add first row" );
}

# Add column to empty data

{
    my $data = Lab::BlockData->new();
    isa_ok( $data, 'Lab::BlockData' );
    my $column = [ 1, 2, 3 ];
    $data->add_column($column);

    is( $data->columns(), 1, "have one column" );
    is( $data->rows(),    3, "have three columns" );

    my @column = $data->column(0);
    is_deeply( [@column], $column, "add first column" );
}

# Invalid use
{
    ok( exception { Lab::BlockData->new( matrix => [ [] ] ); },
        "empty matrix throws" );
    ok( exception { Lab::BlockData->new( matrix => [ [ 1, 2 ], [3] ] ); },
        "non-rectangular data throws" );

    my $data = Lab::BlockData->new();
    ok( exception { $data->add_column( [] ); }, "adding empty column throws" );

    $data->add_column( [ 1, 2, 3 ] );
    ok(
        exception { $data->add_column( [ 4, 5 ] ); },
        "adding column of wrong size throws"
    );
    ok( exception { $data->add_column( [ 1, 2, 'e1' ] ); },
        "non-number in data throws" );

}

