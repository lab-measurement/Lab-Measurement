package Lab::Moose::Instrument::SR830;

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::BlockData;
use Carp;
use namespace::autoclean;
use POSIX qw/log10 ceil floor/;

our $VERSION = '3.530';

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

=encoding utf8

=head1 NAME

Lab::Moose::Instrument::SR830 -  Stanford Research SR830 Lock-In Amplifier

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $lia = instrument(type => 'SR830', %connection_options);
 
 # Set reference frequency to 10 kHz
 $lia->set_freq(value => 10000);

 # Set time constant to 10 sec
 $lia->set_tc(value => 10);

 # Set sensitivity to 10 mV
 $lia->set_sens(value => 0.001);
 
 # Get X and Y values
 my $xy = $lia->get_xy();
 say "X: ", $xy->{x};
 say "Y: ", $xy->{y};

=head1 METHODS

=head2 get_freq

 my $freq = $lia->get_freq();

Query frequency of the reference oscillator.

=head2 set_freq

 $lia->set_freq(value => $freq);

Set frequency of the reference oscillator.

=cut

cache freq => ( getter => 'get_freq' );

sub get_freq {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_freq( $self->query( command => 'FREQ?', %args ) );
}

sub set_freq {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => "FREQ $value", %args );
    $self->cached_freq($value);
}

=head2 get_amplitude

 my $ampl = $lia->get_amplitude();

Query amplitude of the sine output.

=head2 set_amplitude

 $lia->set_amplitude(value => $ampl);

Set amplitude of the sine output.

=cut

cache amplitude => ( getter => 'get_amplitude' );

sub get_amplitude {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_amplitude(
        $self->query( command => 'SLVL?', %args ) );
}

sub set_amplitude {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write( command => "SLVL $value", %args );
    $self->cached_amplitude($value);
}

cache phase => ( getter => 'get_phase' );

=head2 get_phase

 my $phase = $lia->get_phase();

Get reference phase shift (in degree). Result is between -180 and 180.

=head2 set_phase

 $lia->set_phase(value => $phase);

Set reference phase shift. The C<$phase> parameter has to be between -360 and
729.99.

=cut

sub get_phase {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_phase( $self->query( command => 'PHAS?', %args ) );
}

sub set_phase {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    if ( $value < -360 || $value > 729.98 ) {
        croak "$value is not in allowed range of phase: [-360, 729.99] deg.";
    }
    $self->write( command => "PHAS $value", %args );
    $self->cached_phase($value);
}

=head2 get_xy

 my $xy = $lia->get_xy();
 my $x = $xy->{x};
 my $y = $xy->{y};

Query the X and Y values.

=head2 get_rphi

 my $rphi = $lia->get_rphi();
 my $r = $rphi->{r};
 my $phi = $rphi->{phi};

Query R and the angle (in degree).

=head2 get_xyrphi

Get x, y, R and the angle all in one call.

=cut

cache xy => ( getter => 'get_xy' );

sub get_xy {
    my ( $self, %args ) = validated_getter( \@_ );
    my $retval = $self->query( command => "SNAP?1,2", %args );
    my ( $x, $y ) = split( ',', $retval );
    chomp $y;
    return $self->cached_xy( { x => $x, y => $y } );
}

cache rphi => ( getter => 'get_rphi' );

sub get_rphi {
    my ( $self, %args ) = validated_getter( \@_ );
    my $retval = $self->query( command => "SNAP?3,4", %args );
    my ( $r, $phi ) = split( ',', $retval );
    chomp $phi;
    return $self->cached_rphi( { r => $r, phi => $phi } );
}

cache xyrphi => ( getter => 'get_xyrphi' );

sub get_xyrphi {
    my ( $self, %args ) = validated_getter( \@_ );
    my $retval = $self->query( command => "SNAP?1,2,3,4", %args );
    my ( $x, $y, $r, $phi ) = split( ',', $retval );
    chomp( $x, $y, $r, $phi );
    return $self->cached_xyrphi( { x => $x, y => $y, r => $r, phi => $phi } );
}

cache tc => ( getter => 'get_tc' );

=head2 get_tc

 my $tc = $lia->get_tc();

Query the time constant.

=head2 set_tc

 # Set tc to 30μs
 $lia->set_tc(value => 30e-6);

Set the time constant. The value is rounded to the nearest valid
value. Rounding is performed in logscale. Croak if the the value is out of
range.

=cut

sub _int_to_tc {
    my $self = shift;
    my ($int_tc) = pos_validated_list( \@_, { isa => 'Int' } );
    use integer;
    my $exponent = $int_tc / 2 - 5;
    no integer;

    my $tc = 10**($exponent);

    if ( $int_tc % 2 ) {
        $tc *= 3;
    }
    return $tc;
}

sub get_tc {
    my ( $self, %args ) = validated_getter( \@_ );
    my $int_tc = $self->query( command => 'OFLT?', %args );
    return $self->cached_tc( $self->_int_to_tc($int_tc) );
}

sub set_tc {
    my ( $self, $tc, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    my $logval = log10($tc);
    my $n      = floor($logval);
    my $rest   = $logval - $n;
    my $int_tc = 2 * $n + 10;

    if ( $rest > log10(6.5) ) {
        $int_tc += 2;
    }
    elsif ( $rest > log10(2) ) {
        $int_tc += 1;
    }

    if ( $int_tc < 0 ) {
        croak "minimum value for time constant is 1e-5";
    }
    if ( $int_tc > 19 ) {
        croak "maximum value for time constant is 30000";
    }

    $self->write( command => "OFLT $int_tc", %args );
    $self->cached_tc( $self->_int_to_tc($int_tc) );
}

=head2 get_sens

 my $sens = $lia->get_sens();

Get sensitivity (in Volt).

=head2 set_sens

 $lia->set_sens(value => $sens);

Set sensitivity (in Volt).

Same rounding as for C<set_tc>.

=cut

sub _int_to_sens {
    my $self = shift;
    my ($int_sens) = pos_validated_list( \@_, { isa => 'Int' } );

    ++$int_sens;

    use integer;
    my $exponent = $int_sens / 3 - 9;
    no integer;

    my $sens = 10**($exponent);

    if ( $int_sens % 3 == 1 ) {
        $sens *= 2;
    }
    elsif ( $int_sens % 3 == 2 ) {
        $sens *= 5;
    }

    return $sens;
}

cache sens => ( getter => 'get_sens' );

sub get_sens {
    my ( $self, %args ) = validated_getter( \@_ );
    my $int_sens = $self->query( command => 'SENS?', %args );
    return $self->cached_sens( $self->_int_to_sens($int_sens) );
}

sub set_sens {
    my ( $self, $sens, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    my $logval   = log10($sens);
    my $n        = floor($logval);
    my $rest     = $logval - $n;
    my $int_sens = 3 * $n + 26;

    if ( $rest > log10(7.5) ) {
        $int_sens += 3;
    }
    elsif ( $rest > log10(3.5) ) {
        $int_sens += 2;
    }
    elsif ( $rest > log10(1.5) ) {
        $int_sens += 1;
    }

    if ( $int_sens < 0 ) {
        croak "minimum value for sensitivity is 2nV";
    }

    if ( $int_sens > 26 ) {
        croak "maximum value for sensitivity is 1V";
    }

    $self->write( command => "SENS $int_sens", %args );
    $self->cached_sens( $self->_int_to_sens($int_sens) );
}

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=cut

1;
