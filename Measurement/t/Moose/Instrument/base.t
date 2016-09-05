#!perl

use Test::More tests => 15;

use Lab::MooseInstrument;

#
# Basic Usage
#
{
    package TestConnection;
    use Moose;
    use Test::More;
    sub Clear {
	ok(1, 'connection clear called')
    }
    sub Write {
	my $self = shift;
	my %args = @_;
	is($args{command}, 'some write command',
	   "connection Write called");
    }
    sub Read {
	my $self = shift;
	my %args = @_;
	is($args{timeout}, 5, 'timeout in connection Read is set');
	return 'abcd';
    }
    sub Query {
	my $self = shift;
	my %args = @_;
	is($args{command}, 'some command', "connection Query called");
	return 'efgh';
    }
}

{
    my $connection = TestConnection->new();
    isa_ok($connection, 'TestConnection');

    my $instr = Lab::MooseInstrument->new(connection => $connection);
    isa_ok($instr, 'Lab::MooseInstrument');

    is($instr->read(timeout => 5), 'abcd', 'instr can read');

    is($instr->query(command => 'some command'), 'efgh', 'instr can query');

    $instr->write(command => 'some write command');
}

#
# Basic Usage of Device Cache
#

{
    {
	package MyDevice;
	use Moose;
	extends 'Lab::MooseInstrument';
	with 'Lab::HasDeviceCache';

	sub BUILD {
	    my $self = shift;
	    $self->cache_declare(
		key1 => { getter => 'func1' },
		key2 => { getter => 'func2' }
		);
	}

	sub func1 {
	    return 'func1';
	}
	
	sub func2 {
	    return 'func2';
	}
    }

    my $connection = TestConnection->new();
    my $instr = MyDevice->new(connection => $connection);
    isa_ok($instr, 'MyDevice');

    is($instr->cache_get(key => 'key1'), 'func1', 'cache calls getter');
    $instr->cache_set(key => 'key1', value => 'new value');
    is($instr->cache_get(key => 'key1'), 'new value', 'cache value replaced');
    
}

#
# Extend device cache in role
#
{
    {
	package MyRole;
	use Moose::Role;

	sub BUILD {}
	after 'BUILD' => sub {
	    my $self = shift;
	    $self->cache_declare(
		key3 => {getter => 'func3'}
		);
	};

	sub func3 {
	    return 'func3';
	}
    }

    {
	package MyDevice::Extended;
	use Moose;
	extends 'MyDevice';
	with 'MyRole';
    }

    my $connection = TestConnection->new();
    my $instr = MyDevice::Extended->new(connection => $connection);
    isa_ok($instr, 'MyDevice::Extended');

    is($instr->cache_get(key => 'key1'), 'func1', 'cache calls getter');
    $instr->cache_set(key => 'key1', value => 'new value');
    is($instr->cache_get(key => 'key1'), 'new value', 'cache value replaced');

    is($instr->cache_get(key => 'key3'), 'func3', 'cache calls getter');
    $instr->cache_set(key => 'key3', value => 'new value 3');
    is($instr->cache_get(key => 'key3'), 'new value 3',
       'cache value replaced');

}
