package Lab::IO::Data::Message;

use Lab::IO::Data;
our @ISA = ('Lab::IO::Data');

# Test
package Lab::IO::Data::Message::Test;
our @ISA = ('Lab::IO::Data::Message');
our $msg = 'Static message test!';

1;