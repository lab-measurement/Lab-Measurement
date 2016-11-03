#!perl -T

use 5.010;
use warnings;
use strict;

use Test::More;
use Test::Fatal;
use Data::Dumper;
use Lab::Moose::BlockData;
{
    my $data = Lab::Moose::BlockData->new(
        matrix => [ [ 1, 2, 3 ], [ 3, 4, 5 ] ] );

    isa_ok( $data, 'Lab::Moose::BlockData' );

    is( $data->rows,    2, 'get number of rows' );
    is( $data->columns, 3, 'get number of columns' );

    {
        my $row = $data->row(1);

        is_deeply( $row, [ 3, 4, 5 ], "get row as array" );
    }

    {
        my $column = $data->column(2);

        is_deeply( $column, [ 3, 5 ], "get column as array" );
    }

    # Add row

    {
        my $new_row = [ 6, 7, 8 ];
        $data->add_row($new_row);

        is( $data->rows(), 3, "row added" );

        my $row = $data->row(2);
        is_deeply( $row, $new_row );
    }

    # Add column
    {
        my $new_column = [ 10, 11, 12 ];
        $data->add_column($new_column);

        is( $data->columns(), 4, "column added" );

        my $column = $data->column(3);
        is_deeply( $column, $new_column, "added column is intact" );
    }
}

# Add row to empty data
{
    my $data = Lab::Moose::BlockData->new();
    isa_ok( $data, 'Lab::Moose::BlockData' );
    my $new_row = [ 1, 2, 3 ];
    $data->add_row($new_row);

    is( $data->rows(),    1, "have one row" );
    is( $data->columns(), 3, "have three columns" );

    my $row = $data->row(0);
    is_deeply( $row, $new_row, "add first row" );
}

# Add column to empty data

{
    my $data = Lab::Moose::BlockData->new();
    isa_ok( $data, 'Lab::Moose::BlockData' );
    my $new_column = [ 1, 2, 3 ];
    $data->add_column($new_column);

    is( $data->columns(), 1, "have one column" );
    is( $data->rows(),    3, "have three columns" );

    my $column = $data->column(0);
    is_deeply( $column, $new_column, "add first column" );
}

# Invalid use
{
    ok(
        exception { Lab::Moose::BlockData->new( matrix => [ [] ] ); },
        "empty matrix throws"
    );
    ok(
        exception {
            Lab::Moose::BlockData->new( matrix => [ [ 1, 2 ], [3] ] );
        },
        "non-rectangular data throws"
    );

    my $data = Lab::Moose::BlockData->new();
    ok(
        exception { $data->add_column( [] ); },
        "adding empty column throws"
    );

    $data->add_column( [ 1, 2, 3 ] );
    ok(
        exception { $data->add_column( [ 4, 5 ] ); },
        "adding column of wrong size throws"
    );
    ok(
        exception { $data->add_column( [ 1, 2, 'e1' ] ); },
        "non-number in data throws"
    );

}

done_testing();
