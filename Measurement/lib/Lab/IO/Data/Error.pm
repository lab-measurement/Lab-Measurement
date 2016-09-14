package Lab::IO::Data::Error;
our $VERSION = '3.520';
use Lab::IO::Data;
our @ISA = ('Lab::IO::Data');

# Test 1 param
package Lab::IO::Data::Error::CorruptParameter;
our $VERSION = '3.520';
our @ISA     = ('Lab::IO::Data::Error');
our $msg     = 'Parameter %param% is of wrong type or otherwise corrupt!';

# Test 2 params
package Lab::IO::Data::Error::CorruptTwo;
our $VERSION = '3.520';
our @ISA     = ('Lab::IO::Data::Error');
our $msg
    = 'Parameters %param1% and %param2% are of wrong type or otherwise corrupt!';

1;
