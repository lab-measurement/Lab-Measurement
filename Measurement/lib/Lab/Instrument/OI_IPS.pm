
package Lab::Instrument::OI_IPS;
our $VERSION = '3.00';

use strict;
use Lab::Instrument;
use Lab::Instrument::MagnetSupply;
use Time::HiRes qw (usleep);

our @ISA=('Lab::Instrument::MagnetSupply');


our %fields = (
	supported_connections => [ 'GPIB', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
	},

	device_settings => {
	    use_persistentmode          => 0,
	    can_reverse                 => 1,
	    can_use_negative_current    => 1,
	},
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	print "Oxford Instruments IPS superconducting magnet supply code is experimental.\n";
	return $self;
}

sub _device_init {
	my $self=shift;
	
	$self->connection()->SetTermChar(chr(13));
	$self->connection()->EnableTermChar(1);
	$self->ips_set_communications_protocol(4);  # set to extended resolution
	$self->ips_set_control(3);  # set to remote & unlocked
}

sub ips_set_control {
# 0 Local & Locked
# 1 Remote & Locked
# 2 Local & Unlocked
# 3 Remote & Unlocked
    my $self=shift;
    my $mode=shift;
    $self->query("C$mode\r");
}


sub ips_set_communications_protocol {
# 0 "Normal" (default)
# 2 Sends <LF> after each <CR>
# 4 Extended Resolution
# 6 Extended Resolution. Sends <LF> after each <CR>.
    my $self=shift;
    my $mode=shift;
    $self->write("Q$mode\r");
}


sub ips_read_parameter {
# 0 Demand current (output current)     amp
# 1 Measured power supply voltage       volt
# 2 Measured magnet current             amp
# 3 -
# 4 -
# 5 Set point (target current)          amp
# 6 Current sweep rate                  amp/min
# 7 Demand field (output field)         tesla
# 8 Set point (target field)            tesla
# 9 Field sweep rate                    tesla/minute
#10 - 14 -
#15 Software voltage limit              volt
#16 Persistent magnet current           amp
#17 Trip current                        amp
#18 Persistent magnet field             tesla
#19 Trip field                          tesla
#20 Switch heater current               milliamp
#21 Safe current limit, most negative   amp
#22 Safe current limit, most positive   amp
#23 Lead resistance                     milliohm
#24 Magnet inductance                   henry
    my $self=shift;
    my $parameter=shift;
    my $result=$self->query("R$parameter\r");
    chomp $result;
    $result =~ s/^\s*R//;
    $result =~ s/\r//;
    return $result;
}


sub ips_get_status {  # freezes magnet???
    my $self=shift;
    my $result=$self->query("X\r");
    return $result;
}


# returns:
# 0 == Hold
# 1 == To Set Point
# 2 == To Zero
# 3 == Clamped
sub ips_get_hold {
    my $self=shift;
    my $result=$self->ips_get_status();
    $result =~ /X[0-9][0-9]A(.)/;
    $result = $1;
    return $result;
}


# returns:
# 0: Off, Magnet at Zero (switch closed)
# 1: On (switch open)
# 2: Off, Magnet at Field (switch closed)
# 5: Heater Fault (heater is on but current is low)
# 8: No Switch Fitted
sub ips_get_heater {
    my $self=shift;
    my $result=$self->ips_get_status();
    $result =~ /X[0-9][0-9]A[0-9]C[0-9]H(.)/;
    $result = $1;
    return $result;
}


sub ips_set_activity {
# 0 Hold
# 1 To Set Point
# 2 To Zero
# 4 Clamp (clamp the power supply output)
    my $self=shift;
    my $mode=shift;
    $self->query("A$mode\r");
}   


sub ips_set_switch_heater {
# 0 Heater Off                  (close switch)
# 1 Heater On if PSU=Magnet     (open switch)
#  (only perform operation
#   if recorded magnet current==present power supply output current)
# 2 Heater On, no Checks        (open switch)
    my $self=shift;
    my $mode=shift;
    $self->query("H$mode\r");
    sleep(15);  # wait for heater to open the switch    
}

sub ips_set_target_current {
    my $self=shift;
    my $current=shift;
    $self->query("I$current\r");
}

sub ips_set_target_field {
    my $self=shift;
    my $field=shift;
    $self->query("J$field\r");
}

sub ips_set_mode {
#       Display     Magnet Sweep
# 0     Amps        Fast
# 1     Tesla       Fast
# 4     Amps        Slow
# 5     Tesla       Slow
# 8     Amps        Unaffected
# 9     Tesla       Unaffected
    my $self=shift;
    my $mode=shift;
    $self->query("M$mode\r");
}

sub ips_set_polarity {
# 0 No action
# 1 Set positive current
# 2 Set negative current
# 3 Swap polarity
    my $self=shift;
    my $mode=shift;
    $self->query("P$mode\r");
}

sub ips_set_current_sweep_rate {
# amps/min
    my $self=shift;
    my $rate=shift;
    $self->query("S$rate\r");
}

sub ips_set_field_sweep_rate {
# amps/min
    my $self=shift;
    my $rate=shift;
    $self->query("T$rate\r");
}


###########################
# now comes the interface #
###########################


sub _get_current {
    my $self=shift;
    my $res=$self->ips_read_parameter(0);
    return($res);
}


sub _get_heater {
    my $self=shift;
    my $hs = my $result=$self->ips_get_heater();

    if (($hs==0) || ($hs==2)) { return 0; };
    if ($hs==1) { return 1; };
    if ($hs==8) { die "IPS heater status requested but no heater present!\n"; };
    die "IPS heater error!\n";
}


sub _set_heater {
    my $self=shift;
    my $mode=shift;
    if ($mode==99) { $mode=2; };
    $self->ips_set_switch_heater($mode);
    return $self->_get_heater();
}


sub _get_sweeprate {
    my $self=shift;
    # the ips returns AMPS/MIN
    return(($self->ips_read_parameter(6))/60.0);
}


sub _set_sweeprate {
    my $self=shift;
    my $rate=shift;
    $rate=$rate/60.0; # we need for the ips APS/MIN
    $self->ips_set_current_sweep_rate($rate);
    return($self->_get_sweeprate());
}


sub _set_hold {
    my $self=shift;
    my $hold=shift;
    
    if ($hold) {
        $self->ips_set_activity(0); # 0 == hold
    } else {
        $self->ips_set_activity(1); # 1 == to set point
    };
}

sub _get_hold {
    my $self=shift;
    my $r=$self->ips_get_hold();
    if ($r==0) { return 1; };
    if (($r==1) || ($r==2)) { return 0; };
    if ($r==3) { die "magnet is clamped\n"; };
    die "get_hold error\n";
}
    

sub _set_sweep_target_current {
    my $self=shift;
    my $current=shift;
    $self->ips_set_target_current($current);
}





1;


=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::OI_IPS - Oxford Instruments IPS series superconducting magnet supply

  (c) 2010, 2011, 2012 Andreas K. Hüttel

=cut

