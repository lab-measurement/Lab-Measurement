package Lab::Moose::Instrument::SCPI::Output::State;

#ABSTRACT: Role for the SCPI OUTPut:STATe subsystem

use v5.20;

use Moose::Role;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;

=head1 METHODS

=head2 output_state_query

=head2 output_state

 $self->output_state(value => 'ON');
 $self->output_state(value => 'OFF');

Query/Set whether output is on or off. Allowed values: C<ON, OFF>.

=cut

cache output_state => ( getter => 'output_state_query' );

sub output_state_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_output_state(
        $self->query( command => "OUTP:STAT?", %args ) );
}

sub output_state {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) }
    );

    $self->write( command => "OUTP:STAT $value", %args );
    $self->cached_output_state($value);
}

1;

