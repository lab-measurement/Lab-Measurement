package Lab::Instrument::SRS_SIM928;
use strict;
use Lab::Instrument;
use Lab::Instrument::Source;
use Time::HiRes qw/usleep/;

our $VERSION="1.21";

our @ISA=('Lab::Instrument::Source');

my $default_config={
    gate_protect            => 1,
    gp_equal_level          => 1e-5,
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
    gp_max_step_per_second  => 2,
    gp_max_volt         => 0.100,
    gp_min_volt         => -1.500,
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
    my $value=shift;
    my $channel=shift;
    my $cmd=sprintf("SNDT $channel, \"VOLT %e\"",$value);
    usleep(0.1e6);
    $self->{vi}->Write($cmd);
}


sub _get_voltage {
    my $self=shift;
    my $channel=shift;
    my $cmd=sprintf("CONN $channel, \"X\"");    # X is only a token for the connection!!
    $self->{vi}->Write($cmd);
    usleep(0.1e6);
    $cmd="VOLT?";
    my $result=$self->{vi}->Query($cmd);
    usleep(0.1e6);
    $self->{vi}->Write("X");
    usleep(0.1e6);
    chop $result;
    $result =~ s/\r//;

    return $result;
}



sub get_battery_status {
    my $self=shift;
    my $channel=shift;
    my $cmd=sprintf("CONN $channel, \"X\"");    # X is only a token for the connection!!
    $self->{vi}->Write($cmd);
    my $date=$self->{vi}->Query("BIDN? 4");
    my $cycles = $self->{vi}->Query("BIDN? 3");
    my $lifetime=$self->{vi}->Query("BIDN? 2");
    $self->{vi}->Write("X");
    
    return "production date: $date cycles: $cycles design life: $lifetime";
}

sub clear {
    my $self=shift;
    my $channel=shift;
    my $cmd="SNDT $channel, \"*CLS\"";
    $self->{vi}->Write($cmd);
}

sub reset {
    my $self=shift;
    my $channel=shift;
    my $cmd="SNDT $channel, \"*RST\"";
    $self->{vi}->Write($cmd);
}

sub id {
    my $self=shift;
    my $cmd=sprintf("CONN 2, \"X\"");   # X is only a token for the connection!!
    $self->{vi}->Write($cmd);
    $cmd="*IDN?";
    my $result=$self->{vi}->Query($cmd);
    $self->{vi}->Write("X");
    return $result;
}

1;


=head1 NAME

Lab::Instrument::SRS_SIM928 - SRS SIM928 voltage source module for SIM900 mainframe

=head1 SYNOPSIS

    use Lab::Instrument::SRS_SIM928;
    
    my $gates=new Lab::Instrument::SRS_SIM928(0,11);
    $gates->set_voltage(0.745,1);
    print $gate14->get_voltage(1);

    my $plunger=new Lab::Instrument::Source($gates, 3);

    $plunger->set_voltage(-0.5);


=head1 DESCRIPTION

The Lab::Instrument::SRS_SIM928 class implements an interface to the
SIM928 voltage source modules. This class derives from L<Lab::Instrument::Source>
and provides all functionality described there.

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 set_voltage($voltage,$channel)

=head2 get_voltage($channel)

=head2 get_battery_status($channel)

Provides information on the battery in the module C<$channel>.

=head2 clear($channel)

Clears the error status.

=head2 reset($channel)

Resets the module. Voltage is set to zero and output is turned OFF.

=head2 id()

Returns the information provided by the instrument's '*IDN?' command.

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::VISA>

=item L<Lab::Instrument>

=item L<Lab::Instrument::Source>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
