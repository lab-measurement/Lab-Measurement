package Lab::Moose::Instrument::HP3458A;

#ABSTRACT: HP 3458A digital multimeter

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
);

sub BUILD {
    my $self = shift;
    $self->clear();

    # Set EOI after each answer.
    $self->set_end( value => 'ALWAYS' );
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 my $dmm = instrument(
     type => 'HP3458A',
     connection_type => 'LinuxGPIB',
     connection_options => {
         gpib_address => 12,
         timeout => 10, # if not given, use connection's default timeout
     }
 );

 $dmm->set_sample_event(value => 'SYN');
 $dmm->set_nplc(value => 2);
 
 my $value = $dmm->get_value();

=head1 METHODS


=head2 get_value

 my $value = $dmm->get_value();

Read multimeter output value.

=cut

sub get_value {
    my ( $self, %args ) = validated_hash(
        \@_,
        setter_params(),
    );
    return $self->read(%args);
}

=head2 get_nplc/set_nplc

 $dmm->set_nplc(value => 10);
 $nplc = $dmm->get_nplc();

Get/Set integration time in Number of Power Line Cycles.

=cut

sub get_nplc {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "NPLC?", %args );
}

sub set_nplc {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write( command => "NPLC $value", %args );
}

=head2 get_nrdgs/set_nrdgs

 $dmm->set_nrdgs(readings => 2, sample_event => 'AUTO');
 ($readings, $sample_event) = $dmm->get_nrdgs();

Get/Set number of readings taken per trigger event and the sample event.

=cut

sub get_nrdgs {
    my ( $self, %args ) = validated_getter( \@_ );
    my $result = $self->query( command => "NRDGS?", %args );
    return split( /,/, $result );
}

sub set_nrdgs {
    my ( $self, %args ) = validated_getter(
        \@_,
        readings => { isa => 'Int' },
        sample_event =>
            { isa => enum( [qw/AUTO EXT HOLD LEVEL LINE SGL SYN TIMER/] ) },
    );
    my $readings     = delete $args{readings};
    my $sample_event = delete $args{sample_event};
    $self->write( command => "NRDGS $readings, $sample_event", %args );
}

sub get_tarm_event {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "TARM?", %args );
}

sub set_tarm_event {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO EXT SGL HOLD SYN/] ) },
    );
    $self->write( command => "TARM $value", %args );
}

=head2 get_trig_event/set_trig_event

 $dmm->set_trig_event(value => 'EXT');
 $trig_event = $dmm->get_trig_event();

Get/Set trigger event.

=cut

sub get_trig_event {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "TRIG?", %args );
}

sub set_trig_event {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO EXT SGL HOLD SYN LEVEL LINE/] ) },
    );
    $self->write( command => "TRIG $value", %args );
}

=head2 tarm_sgl_query

 my $data = $dmm->tarm_sgl_query();

Low level command which sends the "TARM SGL" command and query the data which is returned.
Only useful when the DMM is in high-speed mode. The returned data is formatted according to the current data output format setting.

=cut

sub tarm_sgl_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "TARM SGL", %args );
}

=head2 get_end/set_end

 $dmm->set_end(value => 'ALWAYS');
 $end = $dmm->get_end();

Get/Set control of GPIB End Or Identify (EOI) function.
This driver sets this to 'ALWAYS' on startup.

=cut

sub get_end {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "END?", %args );
}

sub set_end {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/OFF ON ALWAYS/] ) }
    );
    $self->write( command => "END $value" );
}

=head2 get_range/set_range

 $dmm->set_range(value => 100e-3); # select 100mV range (if in DCV mode)
 $range = $dmm->get_range();

Get/Set measurement range.

=cut

sub get_range {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "RANGE?", %args );
}

sub set_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );
    $self->write( command => "RANGE $value" );
}

=head2 get_auto_range/set_auto_range

 $dmm->set_auto_range(value => 'OFF');
 $auto_range = $dmm->get_auto_range();

Get/Set the status of the autorange function.
Possible values: C<OFF, ON, ONCE>.
=cut

sub get_auto_range {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "ARANGE?", %args );
}

sub set_auto_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF ONCE/] ) }
    );
    $self->write( command => "ARANGE $value", %args );
}

sub get_output_format {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'OFORMAT?', %args );
}

sub set_output_format {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ASCII SINT DINT SREAL DREAL/] ) },
    );
    $self->write( command => "OFORMAT $value", %args );
}

sub get_memory_format {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'OFORMAT?', %args );
}

sub set_memory_format {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ASCII SINT DINT SREAL DREAL/] ) },
    );
    $self->write( command => "OFORMAT $value", %args );
}

sub get_auto_zero {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'AZERO?', %args );
}

sub set_auto_zero {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF ONCE/] ) },
    );
    $self->write( command => "AZERO $value", %args );
}

sub get_disp {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'DISP?', %args );
}

sub set_disp {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/OFF ON MSG CLR/] ) },
    );
    $self->write( command => "DISP $value", %args );
}

=head2 set_high_speed_mode

 $dmm->set_high_speed_mode(format => 'DINT');

C<format> can be 'SINT' or 'DINT'.

=back


=cut

sub set_high_speed_mode {
    my ( $self, %args ) = validated_getter(
        \@_,
        format => { isa => enum( [qw/SINT DINT/] ) },
    );
    my $format = delete $args{format};

    $self->set_output_format( value => $format );
    $self->set_memory_format( value => $format );

    $self->set_auto_zero( value => 'OFF' );
    $self->set_disp( value => 'OFF' );

    if ( $self->get_auto_range() ) {
        croak("Autorange mode is on, cannot set high-speed mode");
    }
}

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=cut

__PACKAGE__->meta()->make_immutable();

1;
