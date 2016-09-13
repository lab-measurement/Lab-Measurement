#!perl
use 5.010;
use warnings;
use strict;
use Test::More tests => 22;
use Test::Fatal;
use Lab::MooseInstrument;

#
# Basic Usage
#

{

    package TestConnection;
    use Moose;
    use Test::More;

    sub Clear {
        ok( 1, 'connection clear called' );
    }

    sub Write {
        my $self = shift;
        my %args = @_;
        is( $args{command}, 'some write command', "connection Write called" );
    }

    sub Read {
        my $self = shift;
        my %args = @_;
        is( $args{timeout}, 5, 'timeout in connection Read is set' );
        return 'abcd';
    }

    sub Query {
        my $self = shift;
        my %args = @_;
        is( $args{command}, 'some command', "connection Query called" );
        return 'efgh';
    }
}

{
    my $connection = TestConnection->new();
    isa_ok( $connection, 'TestConnection' );

    my $instr = Lab::MooseInstrument->new( connection => $connection );
    isa_ok( $instr, 'Lab::MooseInstrument' );

    is( $instr->read( timeout => 5 ), 'abcd', 'instr can read' );

    is( $instr->query( command => 'some command' ), 'efgh', 'instr can query' );

    $instr->write( command => 'some write command' );
}

#
# Basic Usage of Device Cache
#

{
    {

        package MyDevice;

        use Moose;
        use Lab::MooseInstrument::Cache;

        extends 'Lab::MooseInstrument';

        cache func1 => ( getter => 'func1', isa => 'Str' );

        cache func2 => ( getter => 'func2' );

        sub func1 {
            return 'func1';
        }

        sub func2 {
            return 'func2';
        }
    }

    my $connection = TestConnection->new();
    my $instr = MyDevice->new( connection => $connection );
    isa_ok( $instr, 'MyDevice' );

    is( $instr->cached_func1(), 'func1', 'no value in cache: call getter' );

    $instr->cached_func1('new value');

    is( $instr->cached_func1(), 'new value', 'new value in cache' );

}

#
# Extend device cache with subclass and roles
#

{
    {

        package MyRole;
        use Moose::Role;
        use Lab::MooseInstrument::Cache;

        cache func3 => ( getter => 'func3' );

        sub func3 {
            return 'func3';
        }
    }

    {

        package MyRole2;
        use Moose::Role;
        use Lab::MooseInstrument::Cache;

        cache func4 => ( getter => 'func4' );

        sub func4 {
            return 'func4';
        }
    }

    {

        package MyDevice::Extended;
        use Moose;
        use Lab::MooseInstrument::Cache;
        extends 'MyDevice';
        with 'MyRole', 'MyRole2';

        cache func_extended => ( getter => 'func_extended' );

        sub func_extended {
            return 'func_extended';
        }

    }

    my $connection = TestConnection->new();
    my $instr = MyDevice::Extended->new( connection => $connection );
    isa_ok( $instr, 'MyDevice::Extended' );

    is( $instr->cached_func1(), 'func1', 'call cached func1' );

    is( $instr->cached_func2(), 'func2', 'call cached func2' );

    is( $instr->cached_func3(), 'func3', 'call cached func3' );

    is( $instr->cached_func4(), 'func4', 'call cached func4' );

    is( $instr->cached_func_extended(),
        'func_extended', 'call cached func_extended' );

    # predicate and clearer

    ok( $instr->has_cached_func1(), "have cached func1" );

    $instr->clear_cached_func1();

    ok( ( not $instr->has_cached_func1() ), "cleared cached func1" );

    is( $instr->cached_func1(), 'func1', 'call builder after clear' );

    # Illegal operations

    ok( exception { $instr->cached_func_uiaeuiaeuuiae(); },
        "unknown cache key throws" );

    is( exception { $instr->cached_func2( [2] ); },
        undef, "ArrayRef allowed for func2" );

    ok( exception { $instr->cached_func1( [1] ); },
        "ArrayRef throws for func1" );

}
