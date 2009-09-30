#$Id: HP34970A.pm 489 2006-08-13 15:07:14Z Kalok $

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
    my $self=shift;
    $self->{vi}->Write("RESET");
}

sub preset {
    # 0 Fast
    # 1 Norm
    # 2 DIG 
    my $self=shift;
    my $preset=shift;
    my $cmd=sprintf("PRESET %u",$preset);
    $self->{vi}->Write($cmd);
}
#sub scroll_message {
#    use Time::HiRes (qw/usleep/);
#    my $self=shift;
#    my $message="            Orcs Orcs Orcs Orcs Orcs!.            ";
#    for (0..(length($message)-12)) {
#        $self->display_text(substr($message,$_,$_+11));
#        usleep(100000);
#    }
#    $self->display_clear();
#}

1;

=head1 NAME

Lab::Instrument::HP34970A - a HP/Agilent 34970A digital multimeter

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head2 read_voltage_dc

    $datum=$hp->read_voltage_dc($range,$resolution,@scan_list);

Preset and make a dc voltage measurement with the specified range
and resolution.

=over 4

=item $range

Range is given in terms of volts and can be C<[0.1|1|10|100|1000|MIN|MAX|DEF]>. C<DEF> is default.

=item $resolution

Resolution is given in terms of C<$range> or C<[MIN|MAX|DEF]>.
C<$resolution=0.0001> means 4 1/2 digits for example.
The best resolution is 100nV: C<$range=0.1>; C<$resolution=0.000001>.

=item @scan_list

A list of channels to scan. See the instrument manual.

=back

=head2 conf_monitor

    $hp->conf_monitor(@channels);

=head2 read_monitor

    @channels=$hp->read_monitor();

=head2 display_on

    $hp->display_on();

Turn the front-panel display on.

=head2 display_off

    $hp->display_off();

Turn the front-panel display off.

=head2 display_text

    $hp->display_text($text);
    print $hp->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 display_clear

    $hp->display_clear();

Clear the message displayed on the front panel.

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

=head2 scroll_message

    $hp->scroll_message();

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: HP34970A.pm 489 2006-08-13 15:07:14Z kalok $

Copyright 2009 David Kalok

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
