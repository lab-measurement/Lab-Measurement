package Lab::MooseInstrument::SCPI::Calculate::Data;

use Moose::Role;
use MooseX::Params::Validate;
use Lab::MooseInstrument::Cache;

use Lab::MooseInstrument qw/getter_params setter_params/;

use namespace::autoclean;

sub _getter_args {
    return validated_hash( \@_, getter_params() );
}

sub _setter_args {
    return validated_hash( \@_, setter_params() );
}

cache calculate_data_call_catalog => (
    getter => 'calculate_data_call_catalog',
    isa    => 'ArrayRef'
);

sub calculate_data_call_catalog {
    my ( $self, %args ) = _getter_args(@_);
    my $string = $self->query( command => 'CALC:DATA:CALL:CAT?', %args );
    $string =~ s/'//g;
    my $result = [ split ',', $string ];
    $self->cached_calculate_data_call_catalog($result);
}

sub calculate_data_call {
    my ( $self, %args ) =
      validated_hash( \@_, getter_params(), format => { isa => 'Str' } );

    my $format = delete $args{format};

    return $self->query( command => 'CALC:DATA:CALL?', %args );
}

1;
