package Lab::Moose::Instrument::RS_ZVM;

#ABSTRACT: Rohde & Schwarz ZVM Vector Network Analyzer

use v5.20;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/getter_params timeout_param validated_getter validated_setter/;
use Carp;
use Config;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with 'Lab::Moose::Instrument::SCPI::Format' => {
    -excludes => [qw/format_border format_border_query/],
    },
    qw(
    Lab::Moose::Instrument::SCPI::Sense::Function
    Lab::Moose::Instrument::SCPI::Source::Power
    Lab::Moose::Instrument::VNASweep
);

sub BUILD {
    my $self = shift;

    #$self->clear();
    #$self->cls(timeout => 5);
}

sub cached_format_data_builder {
    my $self = shift;
    return $self->format_data_query( timeout => 3 );
}

sub sparam_catalog {
    my $self     = shift;
    my $function = $self->cached_sense_function();

    if ( $function !~ /(?<sparam>S[12]{2})/ ) {
        croak "no S-parameter selected";
    }

    my $sparam = $+{sparam};

    return [ "Re($sparam)", "Im($sparam)" ];
}

sub trace_data_response_all {
    my ( $self, %args ) = validated_hash(
        \@_,
        getter_params(),
        trace => { isa => 'Str' },
    );

    my $trace = delete $args{trace};

    return $self->binary_query(
        command => "TRAC:DATA:RESP:ALL? $trace",
        %args
    );
}

sub sparam_sweep_data {
    my ( $self, %args ) = validated_getter( \@_ );

    my $channel = $self->cached_instrument_nselect();

    # Start single sweep.
    $self->initiate_immediate();

    # Wait until single sweep is finished.
    $self->wai();
    return $self->trace_data_response_all(
        trace => "CH${channel}DATA",
        %args
    );
}

=head1 SYNOPSIS

 my $data = $zvm->sparam_sweep(timeout => 10);
 my $matrix = $data->matrix;

=cut

=head1 METHODS

See L<Lab::Moose::Instrument::VNASweep> for the high-level C<sparam_sweep> and
C<sparam_catalog> methods.

=cut

=head2 set_power, get_power

Interface for power sweeps

=cut

sub set_power {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    $self->source_power_level_immediate_amplitude( value => $value );
}

sub get_power {
	my $self = shift;
	return $self->source_power_level_immediate_amplitude_query();
}


__PACKAGE__->meta->make_immutable();

1;
