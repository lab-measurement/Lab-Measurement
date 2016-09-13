package Lab::MooseInstrument::Common;

use Moose::Role;
use MooseX::Params::Validate;

use Lab::MooseInstrument qw/getter_params setter_params/;
use Carp;

use namespace::autoclean -also => [qw/_getter_args _setter_args/];

sub _getter_args {
    return validated_hash( \@_, getter_params() );
}

sub _setter_args {
    return validated_hash( \@_, setter_params() );
}

sub idn {
    my ( $self, %args ) = _getter_args(@_);
    return $self->query( command => '*IDN?', %args );
}

sub wai {
    my ( $self, %args ) = _setter_args(@_);
    return $self->write( command => '*WAI', %args );
}

sub opc {
    my ( $self, %args ) = _setter_args(@_);
    return $self->write( command => '*OPC', %args );
}

sub opc_query {
    my ( $self, %args ) = _getter_args(@_);
    return $self->query( command => '*OPC?', %args );
}

sub opc_sync {
    my ( $self, %args ) = _getter_args(@_);
    my $one = $self->opc_query(%args);
    if ( $one ne '1' ) {
        croak "OPC query did not return '1'";
    }
    return $one;
}

1;
