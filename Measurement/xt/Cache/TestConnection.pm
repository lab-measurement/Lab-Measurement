package TestConnection;
use 5.010;

use Moose;

use namespace::autoclean;

sub Write {
    say "write args: @_";
}

sub Read {
    say "read args: @_";
    return 'ReadReadRead';
}

sub Query {
    say "query args: @_";
    return 'QueryQueryQuery';
}

sub Clear {
    say "clear args: @_";
}

__PACKAGE__->meta->make_immutable;

1;
