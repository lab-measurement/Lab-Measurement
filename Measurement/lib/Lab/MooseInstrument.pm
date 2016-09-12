=head1 NAME

Lab::MooseInstrument - Base class for instrument drivers.

=head1 SYNOPSIS

 use Lab::MooseInstrument;

 my $instrument = Lab::MooseInstrument->new(connection => $connection);

 
 my $data = $instrument->read();
 
 $instrument->write(command => '*OPC');
 
 my $id = $instrument->query(command => '*IDN?');

=head1 DESCRIPTION

The Lab::MooseInstrument module is a thin wrapper around a connection object.
All other Lab::MooseInstrument::* drivers inherit from this module.

=cut

package Lab::MooseInstrument;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw(duck_type);
use MooseX::Params::Validate;

use Exporter 'import';


our @EXPORT_OK = qw(
getter_params
setter_params
validated_getter
validated_setter
validated_channel_getter
validated_channel_setter
);

use namespace::autoclean 
    -except => 'import', -also => [@EXPORT_OK];

our $VERSION = '3.512';

# do not make imported functions available as methods.

=head1 Methods

=head2 new

See SYNOPSIS.
The constructor requires a connection object, which has
Read, Write, Query and Clear methods. You can provide any object, which
supports these methods.

=cut

has 'connection' => (
    is => 'ro',
    isa => duck_type( [qw/Write Read Query Clear/] ),
    required => 1
);

my %command = (command => { isa => 'Str' });
my %timeout = (timeout => { isa => 'Num', optional => 1 });
my %read_length = (read_length => { isa => 'Int', optional => 1 });

sub getter_params {
    return (%timeout, %read_length);
}

sub setter_params {
    return (%timeout);
}

sub validated_getter {
    return validated_hash(
	\@_,
	getter_params()
	);
}

sub validated_setter {
    my ($self, %args) = validated_hash(
	\@_,
	setter_params(),
	value => { isa => 'Str' },
	);
    my $value = delete $args{value};
    return ($self, $value, %args);
}

my %channel_arg = (channel => { isa => 'Int', optional => 1, default => ''});

sub validated_channel_getter {
    my ($self, %args) = validated_hash(
	\@_,
	getter_params(),
	%channel_arg
	);
    my $channel = delete $args{channel};
    return ($self, $channel, %args);
}

sub validated_channel_setter {
    my ($self, %args) = validated_hash(
	\@_,
	getter_params(),
	%channel_arg,
	value => { isa => 'Str' },
	);
    my $channel = delete $args{channel};
    my $value = delete $args{value};
    return ($self, $channel, $value, %args);
}

#
# Methods
#

=head2 write

 $instrument->write(command => '*RST', timeout => 10);

Call the connection's C<Write> method. The timeout parameter is optional.

=cut

sub write {
    my ($self, %args) = validated_hash(
	\@_,
	%command,
	setter_params(),
	);
    
    return $self->connection()->Write(%args);
}

=head2 read

 $instrument->read(timeout => 10, read_length => 10000);

Call the connection's C<Read> method. The timeout and read_length parameters are
optional.

=cut

sub read {
    my ($self, %args) = validated_hash(
	\@_,
	getter_params()
	);
    
    return $self->connection()->Read(%args);
}

=head2 query

 $instrument->query(command => '*IDN?', read_length => 10000, timeout => 10);

Call the connection's C<Query> method. The timeout and read_length parameters
are optional.

=cut

sub query {
    my ($self, %args) = validated_hash(
	\@_,
	%command,
	getter_params()
	);
    
    return $self->connection()->Query(%args);
}

=head2 clear

 $instrument->clear();

Call the connection's C<Clear> method.

=cut

sub clear {
    my $self = shift;
    $self->connection()->Clear();
}

__PACKAGE__->meta->make_immutable();

1;





