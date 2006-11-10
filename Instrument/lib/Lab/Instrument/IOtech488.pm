#$Id$

package Lab::Instrument::IOtech488;
use strict;
use Lab::Instrument;
use Lab::Instrument::Source;
use Time::HiRes qw /usleep/;

our $VERSION = sprintf("0.%04d", q$Revision: 489 $ =~ / (\d+) /);

our @ISA=('Lab::Instrument::Source');

my $default_config={
    gate_protect            => 1,
    gp_equal_level          => 1e-5,
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
    gp_max_step_per_second  => 2,
    
    channel                 => 1,
};

sub new {
    my $proto = shift;
    my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($default_config,@args);
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@args);
    
    return $self
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    
    my $cmd='P'.$self->{channel}.'X';
    $self->{vi}->Write($cmd);   # select channel
    
    usleep(10000);  # wait; adjust this
    
    $cmd="V".$voltage."X";
    $self->{vi}->Write($cmd);   # set voltage
}

sub _get_voltage {
    my $self=shift;
    
    my $cmd='P'.$self->{channel}.'X';
    $self->{vi}->Write($cmd);   # select channel
    
    usleep(10000);  # wait; adjust this
    
    return $self->{vi}->Query('V?X'); #  read voltage
}

sub set_range {
    my $self=shift;
    my $range=shift;
    
    # Ranges
    # 1 -  1 volt bipolar
    # 2 -  2 volt bipolar
    # 3 -  5 volt bipolar
    # 4 - 10 volt bipolar
    # 5 -  1 volt unipolar
    # 6 -  2 volt unipolar
    # 7 -  5 volt unipolar
    # 8 - 10 volt unipolar
    
    my $cmd='P'.$self->{channel}.'X';
    $self->{vi}->Write($cmd);   # select channel
    
    usleep(10000);  # wait; adjust this
    
    $cmd='R'.$range.'X';
    $self->{vi}->Write($cmd);
}

sub get_range {
    my $self=shift;

    my $cmd='P'.$self->{channel}.'X';
    $self->{vi}->Write($cmd);   # select channel
    
    usleep(10000);  # wait; adjust this
    
    return $self->{vi}->Query('R?X');
}

sub get_info {
    my $self=shift;
    return $self->{vi}->Query('U9X');
}

sub reset {
    my $self=shift;
    $self->{vi}->Write('*RX');
}

1;

=head1 NAME

Lab::Instrument::IOtech488 - IOtech DAC488HR four channel voltage source

=head1 SYNOPSIS

    use Lab::Instrument::IOtech488;
    
    my $gate14=new Lab::Instrument::IOtech488({
        GPIB_board   => 0,
        GPIB_address => 11,
        channel      => 1,
    });
    $gate14->set_range(6);  # 2 volt unipolar
    
    $gate14->set_voltage(0.745);
    
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::IOtech488 class implements an interface to the
7651 voltage and current source by Yokogawa. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTORS

=head2 new({})

 my $gate14=new Lab::Instrument::IOtech488({
     GPIB_board   => 0,
     GPIB_address => 11,
     channel      => 1,
 });

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_range($range)

    # Ranges
    # 1 -  1 volt bipolar
    # 2 -  2 volt bipolar
    # 3 -  5 volt bipolar
    # 4 - 10 volt bipolar
    # 5 -  1 volt unipolar
    # 6 -  2 volt unipolar
    # 7 -  5 volt unipolar
    # 8 - 10 volt unipolar

A change of range will set the output to zero!!!

=head2 get_info()

Returns the information provided by the instrument's 'U9' command.

=head2 reset()

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item Lab::VISA

=item Lab::Instrument

=item Source

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
