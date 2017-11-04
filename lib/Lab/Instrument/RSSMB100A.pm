package Lab::Instrument::RSSMB100A;

#ABSTRACT: Rohde & Schwarz SMB100A signal generator

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => ['GPIB'],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
    },

    device_settings => {},

    device_cache => {
        frq         => undef,
        power       => undef,
        pulselength => undef,
        pulseperiod => undef,
    },

);

=head1 METHODS

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    return $self;
}

=head2 id

 my $id = $smb->id();

Do C<*IDN?> query.

=cut

sub id {
    my $self = shift;
    return $self->query('*IDN?');
}

=head2 reset

 $smb->reset();

Reset with C<*RST> command.

=cut

sub reset {
    my $self = shift;
    $self->write('*RST');
}

=head2 set_frq

 $sms->set_frq(3.3e6);

Set output frequency (Hz).

=cut

sub set_frq {
    my $self = shift;
    my ($freq) = $self->_check_args( \@_, ['value'] );

    #my $freq = shift;
    $self->set_cw($freq);

}

sub set_cw {
    my $self = shift;
    my $freq = shift;

    $self->write("FREQuency:CW $freq Hz");
}

=head2 get_frq

 my $freq = $smb->get_frq({read_mode => 'cache'});

Query output frequency (Hz).

=cut

sub get_frq {
    my $self = shift;

    my $freq = $self->query("FREQuency:CW?");

    return $freq;

}

=head2 set_power

 $smb->set_power(-20);

Set output power (dBm).

=cut

sub set_power {
    my $self = shift;
    my ($power) = $self->_check_args( \@_, ['value'] );
    $self->write("POWer:LEVel $power DBM");
}

=head2 get_power

 my $power = $smb->get_power();

Query output power (dBm).

=cut

sub get_power {
    my $self = shift;
    return $self->query("POWer:LEVel?");
}

sub set_pulselength {
    my $self = shift;
    my ($length) = $self->_check_args( \@_, ['value'] );
    $self->write("PULM:WIDT $length s");
}

sub get_pulselength {
    my $self   = shift;
    my $length = $self->query("PULM:WIDT?");
    return $length;
}

sub set_pulseperiod {
    my $self = shift;
    my ($period) = $self->_check_args( \@_, ['value'] );
    $self->write("PULM:PER $period s");
}

sub get_pulseperiod {
    my $self   = shift;
    my $period = $self->query("PULM:PER?");
    return $period;
}

sub power_on {
    my $self = shift;
    $self->write('OUTP:STATe ON');
}

sub power_off {
    my $self = shift;
    $self->write('OUTP:STATe OFF');
}

sub selftest {
    my $self = shift;
    return $self->query("*TST?");
}

sub display_on {
    my $self = shift;
    $self->write("DISPlay ON");
}

sub display_off {
    my $self = shift;
    $self->write("DISPlay OFF");
}

sub enable_external_am {
    my $self = shift;
    $self->write("AM:DEPTh MAX");
    $self->write("AM:SENSitivity 70PCT/VOLT");
    $self->write("AM:TYPE LINear");
    $self->write("AM:STATe ON");
}

sub disable_external_am {
    my $self = shift;
    $self->write("AM:STATe OFF");
}

sub enable_internal_pulsemod {
    my $self = shift;
    $self->write("PULM:SOUR INT");
    $self->write("PULM:DOUB:STAT OFF");
    $self->write("PULM:MODE SING");
    $self->write("PULM:STAT ON");
}

sub disable_internal_pulsemod {
    my $self = shift;
    $self->write("PULM:STAT OFF");
}

1;

