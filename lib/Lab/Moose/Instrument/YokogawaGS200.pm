package Lab::Moose::Instrument::YokogawaGS200;

#ABSTRACT: YokogawaGS200 voltage/current source.

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x0b21, pid => 0x0039 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

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

    #

    # with USB-TMC, clear results in this error:
    # error in libusb_control_transfer_write: Pipe error at /home/simon/.plenv/versions/5.24.0/lib/perl5/site_perl/5.24.0/x86_64-linux/USB/LibUSB/Device/Handle.pm line 22.
    # apparently in USB::TMC::clear_feature_endpoint_out
    if ( $self->connection_type ne 'USB' ) {
        $self->clear();
    }
    $self->cls();
}

=encoding utf8

=head1 SYNOPSIS

 use Lab::Moose;

 my $yoko = instrument(
     type => 'YokogawaGS200',
     connection_type => 'LinuxGPIB',
     connection_options => {gpib_address => 15},
     # mandatory protection settings
     max_units_per_step => 0.001, # max step is 1mV/1mA
     max_units_per_second => 0.01,
     min_units => -10,
     max_units => 10,
 );

 # Step-sweep to new level.
 # Stepsize and speed is given by (max|min)_units* settings.
 $yoko->set_level(value => 9);

 # Get current level from device cache (without sending a query to the
 # instrument):
 my $level = $yoko->cached_level();

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>
=item L<Lab::Moose::Instrument::SCPI::Source::Function>
=item L<Lab::Moose::Instrument::SCPI::Source::Range>
=item L<Lab::Moose::Instrument::LinearStepSweep>

=back
    
=cut

cache source_level => ( getter => 'source_level_query' );

sub source_level_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_source_level(
        $self->query( command => ":SOUR:LEV?", %args ) );
}

sub source_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write(
        command => sprintf( "SOUR:LEV %.15g", $value ),
        %args
    );
    $self->cached_source_level($value);
}

=head2 set_level

 $yoko->set_level(value => $new_level);

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

#
# Aliases for Lab::XPRESS::Sweep API
#

=head2 cached_level

 my $current_level = $yoko->cached_level();

Get current value from device cache.

=cut

sub cached_level {
    my $self = shift;
    return $self->cached_source_level(@_);
}

=head2 get_level

 my $current_level = $yoko->get_level();

Query current level.

=cut

sub get_level {
    my $self = shift;
    return $self->source_level_query(@_);
}

=head2 set_voltage

 $yoko->set_voltage($value);

For XPRESS voltage sweep. Equivalent to C<< set_level(value => $value) >>.

=cut

sub set_voltage {
    my $self  = shift;
    my $value = shift;
    return $self->set_level( value => $value );
}

sub config_sweep {
    my ( $self, %args ) = validated_getter(
        \@_,
        points => { isa => 'Num' },
        rates  => { isa => 'Num' },
    );

    my $target = delete $args{points};
    my $rate   = delete $args{rates};

    my $current_level = $self->get_level();
    my $time = abs( ( $target - $current_level ) / $rate );
    if ( $time < 0.1 ) {
        carp "sweep time < 0.1 seconds; adjusting to 0.1 seconds";
        $time = 0.1;
    }
    if ( $time > 3600 ) {
        croak "sweep time needs to be <= 3600 seconds";
    }

    $self->write( command => 'PROG:REP 0', %args );
    $self->write( command => sprintf( 'PROG:INT %.17g',  $time ), %args );
    $self->write( command => sprintf( 'PROG:SLOP %.17g', $time ), %args );

    $self->write( command => 'PROG:EDIT:STAR', %args );

    # do not use 'source_level', no caching needed here
    $self->write( command => sprintf( "SOUR:LEV %.15g", $target ), %args );
    $self->write( command => 'PROG:EDIT:END', %args );
}

sub trg {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => 'PROG:RUN' );
}

=head2 sweep_to_level

 $yoko->sweep_to_level($value);

For XPRESS voltage sweep. Equivalent to C<set_voltage>.

=cut

sub sweep_to_level {
    my $self = shift;
    return $self->set_voltage(@_);
}

with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::SCPI::Source::Function
    Lab::Moose::Instrument::SCPI::Source::Range
    Lab::Moose::Instrument::LinearStepSweep
);

__PACKAGE__->meta()->make_immutable();

1;
