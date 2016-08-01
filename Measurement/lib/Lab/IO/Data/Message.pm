package Lab::IO::Data::Message;

our $VERSION='3.514';

use Lab::IO::Data;
our @ISA = ('Lab::IO::Data');

# Test
package Lab::IO::Data::Message::Test;
our $VERSION='3.514';
our @ISA = ('Lab::IO::Data::Message');
our $msg = 'Static message test!';

1;
