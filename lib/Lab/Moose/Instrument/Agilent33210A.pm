package Lab::Moose::Instrument::Agilent33210A;

#ABSTRACT: Agilent 33210A Arbitrary Waveform Generator, also as voltage source

use v5.20;

use strict;
use Time::HiRes qw (usleep);
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    setter_params
/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time usleep/;
use Lab::Moose 'linspace';

extends 'Lab::Moose::Instrument';


has [qw/max_units_per_second max_units_per_step min_units max_units/] =>
    ( is => 'ro', isa => 'Num', required => 1 );

has source_level_timestamp => (
    is       => 'rw',
    isa      => 'Num',
    init_arg => undef,
);

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

sub BUILD {
    my $self = shift;
    $self->get_id();
}

sub get_id {
    my $self = shift;
    return $self->query( command => sprintf("*IDN?") );
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $HP = instrument(
     type            => 'Agilent33210A',
     connection_type => 'VISA_GPIB',
     connection_options => {
         pad => 28,
     },
 );

=head1 METHODS

=head2 reset

 $HP->reset();

=cut


sub reset {
    my $self = shift;
    $self->write( command => sprintf("*RST") );
}

=head2 set_frq

 $HP->set_frq( value =>  );

 The frequency can range up to 15MHz

=cut

sub set_frq {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value  => { isa => 'Num' },
    );

	$self->write( command => sprintf("FREQuency %d Hz", $value), %args ); 
}

=head2 get_frq

 $HP->get_frq();

=cut

sub get_frq {
    my $self = shift;

    return $self->query( command => sprintf("FREQuency?") );
}

=head2 set_amplitude

 $HP->set_amplitude( value =>  );

=cut

sub set_amplitude {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value  => { isa => 'Num' },
    );

    $self->write( command => sprintf("VOLTage %e V", $value) );
}

=head2 get_amplitude

 $HP->get_amplitude();

=cut

sub get_amplitude {
    my $self = shift;

    return $self->query( command => sprintf("VOLTage?") );
}


=head2 set_offset

 $HP->set_offset( value =>  );

=cut

sub set_offset {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value  => { isa => 'Num' },
    );

    $self->write( command => sprintf("VOLTage:OFFSet %e V", $value) );
}

=head2 get_offset

 $HP->get_offset();

=cut

sub get_offset {
    my $self = shift;

    return $self->query( command => "VOLTage:OFFSet?" );
}

#
# from here on we define the voltage source interface to be able
# to use the AWG as replacement for a boring dc source
#

cache source_level => ( getter => 'source_level_query' );

sub source_level_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_source_level(
        $self->get_offset()
	);
}

sub source_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->set_offset( value => $value, %args );
    $self->cached_source_level($value);
}

=head2 set_level

 $HP->set_level(value => $new_level);

Go to new level. Sweep with multiple steps if the distance between current and
new level is larger than C<max_units_per_step>.

=cut

sub set_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    return $self->linear_step_sweep(
        to => $value, verbose => $self->verbose,
        %args
    );
}

=head2 cached_level

 my $current_level = $hp->cached_level();

Get current value from device cache.

=cut

sub cached_level {
    my $self = shift;
    return $self->cached_source_level(@_);
}

=head2 get_level

 my $current_level = $hp->get_level();

Query current level.

=cut

sub get_level {
    my $self = shift;
    return $self->source_level_query(@_);
}

# odds and oods


sub selftest {
    my $self = shift;
    return $self->query( command => sprintf("*TST?") );
}

sub display_on {
    my $self = shift;
    $self->write( command => sprintf("DISPlay ON") );
}

sub display_off {
    my $self = shift;
    $self->write( command => sprintf("DISPlay OFF") );
}

sub set_shape {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value  => { isa => 'Str' },
    );

    $self->write( command => 'FUNCtion:SHAPe '.$value );	
}

sub get_shape {
    my $self = shift;
    return $self->query( command => 'FUNCtion:SHAPe?' );	
}


with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::SCPI::Source::Function
    Lab::Moose::Instrument::LinearStepSweep
);



1;
