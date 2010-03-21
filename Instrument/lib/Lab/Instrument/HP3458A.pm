#$Id$

package Lab::Instrument::HP3458A;

use strict;
use Lab::Instrument;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@_);

    return $self
}

sub read_value {
    # Triggers one Measurement and Reads it
    my $self=shift;
    $self->{vi}->Write("TRIG SGL");
    my $val= $self->{vi}->BrutalRead(16);
    chomp $val;
    return $val;
}

sub read_voltage_dc {
    my $self=shift;
    $self->{vi}->Write("DCV");
    my $val= $self->{vi}->BrutalRead(16);
    return $val #$self->{vi}->Query("DCV");
}


sub display_text {
    my $self=shift;
    my $text=shift;
    
    if ($text) {
        $self->{vi}->Write(qq(DISPlay:TEXT "$text"));
    } else {
        chomp($text=$self->{vi}->Query(qq(DISPlay:TEXT?)));
        $text=~s/\"//g;
    }
    return $text;
}

sub display_on {
    my $self=shift;
    $self->{vi}->Write("DISPlay ON");
}



sub beep {
    # It beeps!
    my $self=shift;
    $self->{vi}->Write("SYSTem:BEEPer");
}

sub get_error {
    my $self=shift;
    chomp(my $err=$self->{vi}->Query("SYSTem:ERRor?"));
    my ($err_num,$err_msg)=split ",",$err;
    $err_msg=~s/\"//g;
    return ($err_num,$err_msg);
}

sub reset {
    # Resets HP3458A into standard configuration
    my $self=shift;
    $self->{vi}->Write("RESET");
}

sub preset {
    # Sets HP3458A into predefined configurations
    # 0 Fast
    # 1 Norm
    # 2 DIG 
    my $self=shift;
    my $preset=shift;
    my $cmd=sprintf("PRESET %u",$preset);
    $self->{vi}->Write($cmd);
}


1;

=head1 NAME

Lab::Instrument::HP3458A - Agilent 3458A Multimeter

=head1 SYNOPSIS

    use Lab::Instrument::HP3458A;
    
    my $dmm=new Lab::Instrument::HP3458A({
        GPIB_board   => 0,
        GPIB_address => 11,
    });
    print $dmm->read_voltage_dc();

=head1 DESCRIPTION

The Lab::Instrument::HP3458A class implements an interface to the Agilent / HP 3458A 
digital multimeter. The Agilent 3458A Multimeter, recognized the world over as the
standard in high performance DMMs, provides both speed and accuracy in the R&D lab,
on the production test floor, and in the calibration lab.

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head2 read_voltage_dc

    $datum=$hp->read_voltage_dc();

Make a dc voltage measurement.

=head2 display_on

    $hp->display_on();

Turn the front-panel display on.

=head2 display_text

    $hp->display_text($text);
    print $hp->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 beep

    $hp->beep();

Issue a single beep immediately.

=head2 get_error

    ($err_num,$err_msg)=$hp->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 reset

    $hp->reset();

Reset the multimeter to its power-on configuration.

=head2 preset

    $hp->preset($config);

Choose one of several configuration presets (0: fast, 1: norm, 2: DIG).

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2009 David Kalok

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
