package Lab::Moose::Instrument::Cryomagnetics_4G;

#ABSTRACT: Cryomagnetics 4G superconducting magnet power supply

use v5.20;

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
    my $self  = shift;
    my $units = $self->get_units();
    if ( $units eq 'A' ) {
        carp
            'Warning: Cryomagnetics 4G Power supply uses current units (A) not field units';
    }
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $magnet = instrument(
     type => 'Cryomagnetics_4G',
     connection_type => 'VISA::GPIB',
     connection_options => {'gpib_address' => 10}
 );
 
=cut

sub _remove_unit {
    my $rv = shift;
    $rv =~ s/[a-zA-Z]*$//;
    return $rv;
}

sub _kG_to_tesla {
    my $kG = shift;
    return 0.1 * $kG;
}

=head1 METHODS

=cut

sub get_field {
    my $self = shift;
    return _kg_to_tesla( $self->get_imag(@_) );
}

# =head1 sweep_to_field

#  my $new_field = $magnet->sweep_to_field(
#     target => $target_field, # Tesla
#     rate => $rate, # Tesla/min
#  );

# =cut

# sub sweep_to_field {
#     my ( $self, %args ) = validated_getter(
#         \@_,
#         target => { isa => 'Num' },
#         rate   => { isa => 'Num' },
#     );

#     my $point = delete $args{target};
#     my $rate  = delete $args{rate};

#     $self->config_sweep( point => $point, rate => $rate, %args );

#     $self->trg(%args);

#     $self->wait(%args);
#     return $self->get_field(%args);
# }

# =head1 config_sweep

#  $magnet->config_sweep(point => $target, rate => $rate);

# Only define setpoints, do not start sweep.

# =cut

# sub config_sweep {
#     my ( $self, %args ) = validated_hash(
#         \@_,
#         point => { isa => 'Num' },
#         rate  => { isa => 'Num' },
#     );
#     my $target = delete $args{point};
#     my $rate   = delete $args{rate};

#     $self->set_field_sweep_rate( value => $rate, %args );
#     $self->set_target_field( value => $target, %args );

#     my $current_field = $self->get_field();
#     $self->_check_sweep_parameters(
#         current => $current_field, target => $target,
#         rate    => $rate
#     );
#     if ( $self->verbose() ) {
#         say "config_sweep: target: $target (T), rate: $rate (T/min)";
#     }
# }

# sub trg {

# }

# sub wait {

# }

# sub active {

# }

# sub in_persistent_mode {

# }

# sub get_persistent_field {

# }

# =head2 heater_on/heater_off

#  $magnet->heater_on();
#  $magnet->heater_off();

# sub heater_on {

# }

# sub heater_off {

# }

=head1 LOW-LEVEL DEVICE METHODS

=head2 get_imag

 my $value = $magnet->get_imag();
 
Uses either Amps or kilo Gauss, depending on units setting.

=cut

sub get_imag {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "IMAG?", %args );
}

=head2 get_iout

 my $value = $magnet->get_iout();
 
Uses either Amps or kilo Gauss, depending on units setting.

=cut

sub get_iout {
    my ( $self, %args ) = validated_getter( \@_ );
    my $rv = $self->query( command => 'IOUT?', %args );
    return _remove_unit($rv);
}

=head2 set_llim/get_llim

 $magnet->set_llim(value => 10);
 my $value = $magnet->get_llim();

Uses either Amps or kilo Gauss, depending on units setting.

=cut

sub set_llim {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    $self->write( command => "LLIM $value", %args );
}

sub get_llim {
    my ( $self, %args ) = validated_getter( \@_ );
    my $rv = $self->query( command => 'LLIM?', %args );
    return _remove_unit($rv);
}

=head2 local

$magnet->local();

=cut

sub local {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "LOCAL", %args );
}

=head2 get_mode

 my $mode = $magnet->get_mode();

Possible return values: Shim, Manual

=cut

sub get_mode {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'MODE?', %args );
}

=head2 set_pshtr/get_pshtr

 $magnet->set_pshtr(value => 0);
 my $value = $magnet->get_pshtr();

Returns 0 or 1.

=cut

sub set_pshtr {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );
    $self->write( command => "PSHTR $value", %args );
}

sub get_pshtr {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "PSHTR?", %args );
}

=head2 set_range/get_range

 $magnet->set_range(select => 1, limit => 2); # 2 Amps
 my $range = $magnet->get_range(select => 1);

C<select> is in range 0,..,4. 

=cut

sub set_range {
    my ( $self, %args ) = validated_getter(
        select => { isa => enum( [ ( 0 .. 4 ) ] ) },
        limit => { isa => 'Num' },
    );
    my $select = delete $args{select};
    my $limit  = delete $args{limit};
    $self->write( command => "RANGE $select $limit", %args );
}

sub get_range {
    my ( $self, %args ) = validated_getter(
        select => { isa => enum( [ ( 0 .. 4 ) ] ) },
    );
    my $select = delete $args{select};
    return $self->query( command => "RANGE? $select", %args );
}

=head2 set_rate/get_rate

 $magnet->set_rate(range => 1, rate => 0.001); # 1mA / sec 
 my $rate = $magnet->get_rate(range => 1);

C<range> is in range 0,...5, where 5 specifies the rate in fast sweep mode.
C<rate> arg is given in Amps per second.

=cut

sub set_rate {
    my ( $self, %args ) = validated_getter(
        range => { isa => enum( [ ( 0 .. 5 ) ] ) },
        rate => { isa => 'Num' },
    );
    my $range = delete $args{range};
    my $rate  = delete $args{rate};
    $self->write( command => "RATE $range $rate", %args );
}

sub get_rate {
    my ( $self, %args ) = validated_getter(
        range => { isa => enum( [ ( 0 .. 5 ) ] ) },
    );
    my $range = delete $args{range};
    return $self->query( command => "RATE? $range", %args );
}

=head2 set_sweep/get_sweep

 $magnet->set_sweep(value => 'UP');
 $magnet->set_sweep(value => 'UP FAST'); # with switch heater off
 my $mode = $magnet->get_sweep();

C<value> is one off 'UP', 'UP FAST', 'DOWN', 'DOWN FAST', 'PAUSE', 'ZERO', 'LIMIT'

=cut

sub set_sweep {
    my ( $self, $value, %args ) = validated_getter(
        \@_,
        value => {
            isa => enum(
                [ qw/UP DOWN PAUSE ZERO LIMIT/, 'UP FAST', 'DOWN FAST' ]
            )
        },
    );

    $self->write( command => "SWEEP $value", %args );
}

sub get_sweep {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "SWEEP?", %args );
}

=head2 set_ulim/get_ulim

 $magnet->set_ulim(value => 10);
 my $value = $magnet->get_ulim();

Uses either Amps or kilo Gauss, depending on units setting.

=cut

sub set_ulim {
    my ( $self, $value, %args ) = validated_getter(
        \@_,
        value => { isa => 'Num' },
    );

    $self->write( command => "ULIM $value", %args );
}

sub get_ulim {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "ULIM?", %args ) );
}

=head2 set_units/get_units

 $magnet->set_units(value => 'A'); # use Amps
 $magnet->set_units(value => 'G'); # use kiloGauss
 my $units = $magnet->get_units(); # 'A' or 'G'

=cut

cache units => ( getter => 'get_units' );

sub set_units {
    my ( $self, $value, %args ) = validated_getter(
        \@_,
        value => { isa => enum( [qw/A G/] ) },
    );
    $self->write( command => "UNITS $value", %args );
}

sub get_units {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "UNITS?", %args );
}

=head2 set_vlim/get_vlim

 $magnet->set_vlim(value => 2); # 2V
 my $vlim = $magnet->get_vlim();

=cut

sub set_vlim {
    my ( $self, $value, %args ) = validated_getter(
        \@_,
        value => { isa => 'Num' },
    );

    $self->write( command => "VLIM $value", %args );
}

sub get_vlim {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "VLIM?", %args ) );
}

=head2 get_vmag

 my $vmag = $magnet->get_vmag();

=cut

sub get_vmag {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "VMAG?", %args ) );
}

=head2 get_vout

 my $vmag = $magnet->get_vout();

=cut

sub get_vout {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "VOUT?", %args ) );
}

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=cut

__PACKAGE__->meta()->make_immutable();

1;
