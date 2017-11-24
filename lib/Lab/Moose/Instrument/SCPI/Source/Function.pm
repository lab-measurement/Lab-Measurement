package Lab::Moose::Instrument::SCPI::Source::Function;

#ABSTRACT: Role for the SCPI SOURce:FUNCtion subsystem

use Moose::Role;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;

=head1 METHODS

=head2 source_function_query

=head2 source_function

 $self->source_function(value => 'VOLT');

Query/Set the type of output signal. Can be B<VOLT> or B<CURR>.

=cut

cache source_function => ( getter => 'source_function_query' );

sub source_function_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $value = $self->query( command => "SOUR:FUNC?", %args );
    $value =~ s/["']//g;
    return $self->cached_source_function($value);
}

sub source_function {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/VOLT CURR/] ) }
    );
    $self->write( command => "SOUR:FUNC $value", %args );
    $self->cached_source_function($value);
}

1;
