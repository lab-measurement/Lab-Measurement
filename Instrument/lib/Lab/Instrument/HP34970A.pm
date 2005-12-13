#$Id$

package Lab::Instrument::HP34970A;

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

sub read_voltage_dc {
    my $self=shift;
    my ($range,$resolution,@scan_list)=@_;
    
    $range="DEF" unless (defined $range);
    $resolution="DEF" unless (defined $resolution);
    
    my $cmd=sprintf("MEASure:VOLTage:DC? %u,%f, (\@%s)",$range,$resolution,join ",",@scan_list);
    my ($value)=split "\n",$self->{vi}->Query($cmd);
    return $value;
}

sub conf_monitor {
    my ($self,$channel)=@_;
    $self->{vi}->Write("ROUT:MON (\@$channel)");
    $self->{vi}->Write("ROUT:MON:STATE ON");
}

sub read_monitor {
    my $self=shift;
    return $self->{vi}->Query("ROUT:MON:DATA?");
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

sub display_off {
    my $self=shift;
    $self->{vi}->Write("DISPlay OFF");
}

sub display_clear {
    my $self=shift;
    $self->{vi}->Write("DISPlay:TEXT:CLEar");
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
    $self->{vi}->Write("*RST");
}

sub scroll_message {
    use Time::HiRes (qw/usleep/);
    my $self=shift;
    my $message="            This perl instrument driver is copyright 2004/2005 by Daniel Schroeer.            ";
    for (0..(length($message)-12)) {
        $self->display_text(substr($message,$_,$_+11));
        usleep(100000);
    }
    $self->display_clear();
}

1;

=head1 NAME

Lab::Instrument::HP34970A - a HP/Agilent 34970A digital multimeter

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
