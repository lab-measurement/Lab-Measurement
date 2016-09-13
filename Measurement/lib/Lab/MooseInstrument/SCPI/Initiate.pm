package Lab::MooseInstrument::SCPI::Initiate;
use Moose::Role;
use Lab::MooseInstrument qw/setter_params getter_params/;
use Lab::MooseInstrument::Cache;
use MooseX::Params::Validate;
use Lab::SCPI;

our $VERSION = '3.512';

cache initiate_continuous => ( getter => 'initiate_continuous_query' );

sub initiate_continuous {
    my ( $self, %args ) =
      validated_hash( \@_, setter_params(), value => { isa => 'Bool' } );

    my $value = delete $args{value};
    my $gpib_value = $value ? 'ON' : 'OFF';

    $self->write( command => "INIT:CONT $gpib_value", %args );
    $self->cached_initiate_continuous($value);
}

sub initiate_continuous_query {
    my ( $self, %args ) = validated_hash( \@_, getter_params(), );

    return $self->cached_initiate_continuous(
        $self->query( command => 'INIT:CONT?', %args ) );
}

sub initiate_immediate {
    my ( $self, %args ) = validated_hash( \@_, setter_params() );
    $self->write( command => 'INIT', %args );
}

1;
