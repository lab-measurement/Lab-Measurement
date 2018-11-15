package Lab::Moose::Instrument::SCPI::Sense::Function;

#ABSTRACT: Role for the SCPI SENSe:FUNCtion subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

excludes 'Lab::Moose::Instrument::SCPI::Sense::Function::Concurrent';

=head1 DESCRIPTION

This role is intended for instruments which support a single sense function.
The command for setting the function must be SENS:FUNC $function.
Instruments with concurrent sense shell use the Sense::Function:Concurrent
role. 
 
The set sense function is used by other SENSE: roles, like SENSE:NPLC. For
example,

 $source->sense_function(value => 'CURR');
 $source->sense_nplc(value => 10);

will set the integration time for current measurement to 10 power line cycles.

=head1 METHODS

=head2 sense_function_query

=head2 sense_function

Query/Enable the sense function used by the instrument

=cut

# Cache used by multiple functions in sense subsystem
cache sense_function => ( getter => 'sense_function_query' );

sub sense_function_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $value = $self->query( command => "SENS${channel}:FUNC?", %args );
    $value =~ s/["']//g;
    return $self->cached_sense_function($value);
}

sub sense_function {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "SENS${channel}:FUNC '$value'", %args );
    return $self->cached_sense_function($value);
}



1;
