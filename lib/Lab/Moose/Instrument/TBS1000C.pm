package Lab::Moose::Instrument::TBS1000C;

#ABSTRACT: Tektronix TBS 1000C series Oscilloscope.

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Lab::Moose::Instrument::Cache;
use Carp 'croak';
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x0699, pid => 0x03c4 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 my $tbs = instrument(
    type => 'TBS1000C',
    connection_type => 'USB'
    );

 # Configure measurement setup
 $tbs->waveform_output_encoding(value => 'ASCII');
 $tbs->trigger_mode(value => 'NORMAL');
 $tbs->data_source(value => 'CH1');
 $tbs->acquire_stopafter(value => 'SEQUENCE');

 # Start acquisition
 $tbs->acquire_state(value =>1);

 # Waveform will be recorded once triggered
 # software trigger:
 # $tbs->trigger_force();

 # Wait until acquisition is finished
 $tbs->opc_query();
 
 # Get waveform as arrayref
 my $data_block = $tbs->curve_query(); 

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back
    
=cut

#
# ACQUIRE
#

=head2 acquire_state/acquire_state_query

 $tbs->acquire_state(value => 1);
 say $tbs->acquire_state_query();

Allowed values: C<0,1>

=cut

sub acquire_state {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 1/] ) }
    );
    $self->write( command => "ACQUIRE:STATE $value", %args );
}

sub acquire_state_query {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->query( command => "ACQUIRE:STATE?", %args );
}

=head2 acquire_stopafter/acquire_stopafter_query

 $tbs->acquire_stopafter(value => 'SEQUENCE');
 say $tbs->acquire_stopafter_query();

Allowed values: SEQUENCE, STOPAFTER

=cut

sub acquire_stopafter {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/RUNSTOP SEQUENCE/] ) }
    );
    $self->write( command => "ACQUIRE:STOPAFTER $value", %args );
}

sub acquire_stopafter_query {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->query( command => "ACQUIRE:STOPAFTER?", %args );
}

#
# BUSY
#

=head2 busy_query

 my $busy = $tbs->busy_query();

Return 1 if busy, 0 if idle.

=cut

sub busy_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "BUSY?", %args );
}

#
# CURVE
#

=head2 curve_query

 my $data_block = $tbs->curve_query();

Get waveform from instrument as arrayref.

The channel is defined by the C<data_source> method.

=cut

sub curve_query {
    my ( $self, %args ) = validated_getter( \@_ );
    my $encoding = $self->waveform_output_encoding_query();
    if ( $encoding ne 'ASCII' ) {
        croak("only supports ASCII encoding, so far");
    }

    my $data = $self->query( command => "CURVE?", %args );
    return [ split /,/, $data ];
}

#
# DATA
#

=head2 data_source/data_source_query

 $tbs->data_source(value => 'CH1');
 say $tbs->data_source_query();

Data source for the C<curve_query> method.
Allowed values: C<CH1, CH2, MATH, REF1, REF2>

=cut

sub data_source {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/CH1 CH2 MATH REF1 REF2/] ) }
    );
    $self->write( command => "DATA:SOURCE $value", %args );
}

sub data_source_query {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->query( command => "DATA:SOURCE?", %args );
}

#
# TRIGGER
#

=head2 trigger_query

 my $info = $tbs->trigger_query();

Info about trigger setup.

=cut

sub trigger_query {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->query( command => "TRIGGER:A?", %args );
}

=head2 trigger_force

 $tbs->trigger_force();

Force a trigger.

=cut

sub trigger_force {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->write( command => "TRIGGER FORCE", %args );
}

=head2 trigger_state_query

 say $tbs->trigger_state_query();

Returns one of C<ARMED, AUTO, READY, SAVE, TRIGGER>.

=cut

sub trigger_state_query {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->query( command => "TRIGGER:STATE?", %args );
}

=head2 trigger_mode/trigger_mode_query

 $tbs->trigger_mode(value => 'NORMAL');
 say $tbs->trigger_mode_query();

Allowed values: C<NORMAL, AUTO>

=cut

sub trigger_mode {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO NORMAL/] ) }
    );
    $self->write( command => "TRIGGER:A:MODE $value", %args );
}

sub trigger_mode_query {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->query( command => "TRIGGER:A:MODE?", %args );
}

#
# Waveform
#

=head2 waveform_output_encoding/waveform_output_encoding_query

 $tbs->waveform_output_encoding(value => 'ASCII');
 say $tbs->waveform_output_encoding_query();

Allowed values: C<ASCII, BINARY>

=cut

sub waveform_output_encoding {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/BINARY ASCII/] ) }
    );
    $self->write( command => "WFMOUTPRE:ENCDG $value", %args );
}

sub waveform_output_encoding_query {
    my ( $self, %args ) = validated_getter( \@_, );
    return $self->query( command => "WFMOUTPRE:ENCDG?", %args );
}

with qw(
    Lab::Moose::Instrument::Common
);

__PACKAGE__->meta()->make_immutable();

1;
