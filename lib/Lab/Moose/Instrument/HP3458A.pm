package Lab::Moose::Instrument::HP3458A;

#ABSTRACT: HP 3458A digital multimeter

use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
);

sub BUILD {
    my $self = shift;
    $self->clear();    # FIXME: does this change any settings!
    $self->cls();
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;


=head1 METHODS


=cut

cache nrdgs        => ( getter => 'get_nrdgs' );
cache sample_event => ( getter => 'get_sample_event' );

sub get_nrdgs {
    my ( $self, %args ) = validated_getter( \@_ );
    my $result = $self->query( "NRDGS?", %args );
    my ( $points, $event ) = split( /,/, $result );
    $self->cached_nrdgs($points);
    $self->cached_sample_event($event);
    return $points;
}

sub get_sample_event {
    my ( $self, %args ) = validated_getter( \@_ );
    my $result = $self->query( "NRDGS?", %args );
    my ( $points, $event ) = split( /,/, $result );
    $self->cached_nrdgs($points);
    $self->cached_sample_event($event);
    return $event;
}

sub set_nrdgs {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Int' },
    );
    my $sample_event = $self->cached_sample_event();
    $self->write( "NRDGS $value,$sample_event", %args );
    $self->cached_nrdgs($value);
}

sub set_sample_event {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO EXTSYN SYN TIMER LEVEL LINE/] ) },
    );
    my $points = $self->cached_nrdgs();
    $self->write( "NRDGS $points,$value", %args );
    $self->cached_sample_event($value);
}

sub get_value {
    my ( $self, %args ) = validated_hash(
        \@_,
        setter_params(),
    );
    return $self->read(%args);
}

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=cut

__PACKAGE__->meta()->make_immutable();

1;
