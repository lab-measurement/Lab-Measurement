package Lab::Instrument::U2000;
our $VERSION = '2.96';

use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => [ 'USBtmc' ],

    connection_settings => {
        tmc_address => 0
    },

    device_settings => {
        frequency => 10e6,
    },
    

);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    $self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
    $self->connection()->Clear();
    #TODO: Device clear
    $self->write("SYST:PRES"); # Load presets 
    return $self;
}


# template functions for inheriting classes

sub id {
    my $self=shift;
    return $self->query('*IDN?');
}


sub selftest {
    my $self = shift;
    return $self->query("*TST");
}

sub get_value {
    my $self=shift;
    my $value=$self->query('READ?');
    chomp $value;
    return $value;
}

sub set_trigger {
    my $self=shift;
    my $type=shift; #AUTO, BUS, INT, EXT, IMM
    my $args;
    if (ref $_[0] eq 'HASH') { $args=shift } else { $args={@_} }
    my $delay=$args->{'delay'}; #AUTO, MIN, MAX, DEF, -0.15s to +0.15s
    my $level=$args->{'level'}; #DEF, MIN, MAX, sensor dependent range in dB
    my $hysteresis=$args->{'hysteresis'}; #DEF, MIN, MAX, 0 to 3dB
    my $holdoff=$args->{'holdoff'}; #DEF, MIN, MAX, 1µs to 400ms
    my $slope=$args->{'edge'}; #POS, NEG
    if ($type eq "AUTO")
    {
        $self->write("INIT:CONT ON");
    } else {
        $self->write("INIT:CONT OFF");
    }
    if ($type eq "BUS" || $type eq "INT" || $type eq "EXT" || $type eq "IMM")
    {
        $self->write("TRIG:SOUR $type");
    }
    
    
    if (defined($delay)) 
    {
        if ($delay eq "AUTO") {
            $self->write("TRIG:DEL:AUTO ON");
        } else {
            $self->write("TRIG:DEL:AUTO OFF");
            $self->write("TRIG:DEL $delay");
        }
    }

    if (defined($holdoff))
    {
        $self->write("TRIG:HOLD $holdoff");
    }
    
    if (defined($level))
    {
        $self->write("TRIG:LEV $level");
    }
    
    if (defined($hysteresis))
    {
        $self->write("TRIG:HYST $hysteresis");
    }
    
    if (defined($slope))
    {
        $self->write("TRIG:SLOP $slope");
    }
}

#TODO: Currently this is an untriggered read
sub triggered_read
{
    my $self = shift;
#    $self->write("CONF");
    $self->write("INIT:CONT ON");
#    $self->write("INIT");
    return $self->query("FETC?");
    
}

sub get_error
{
    my $self = shift;
    my $current_error = "";
    my $all_errors = "";
    my $max_errors = 5;
    while ($max_errors--) {
        $current_error = $self->query('SYST:ERR?');
        if ($current_error eq "")  {$all_errors .= "Could not read error message!\n"; last; }
        if ($current_error =~ m/^\+0/) { last; }
        $all_errors .= $current_error."\n";
    }
    if (!$max_errors) { $all_errors .= "Maximum Error count reached!\n"; }
    $self->write("*CLS"); #Clear errors
    chomp($all_errors);
    return $all_errors; 
}


1;


=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::U2000 - Agilent U2000 series USB Power Sensor

=head1 DESCRIPTION

The Lab::Instrument::Multmeter class implements a generic interface to
digital all-purpose multimeters. It is intended to be inherited by other
classes, not to be called directly, and provides a set of generic functions.
The class

=head1 CONSTRUCTOR

    my $power=new(\%options);

=head1 METHODS

=head2 get_value

    $value=$power->get_value();

Read out the current measurement value, for whatever type of measurement
the sensor is currently configured. Waits for trigger.

=head2 id

    $id=$hp->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

none known so far :)

=head1 SEE ALSO

=over 4

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2012 Hermann Kraus

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
