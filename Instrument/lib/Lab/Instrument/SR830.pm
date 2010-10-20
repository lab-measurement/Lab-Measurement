package Lab::Instrument::SR830;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{vi}=new Lab::Instrument(@_);
    return $self
}


sub empty_buffer{
    my $self=shift;
    my $times=shift;
    for (my $i=0;$i<$times;$i++){
    $self->{vi}->BrutalRead();
    }
}

sub set_frequency {
    my ($self,$freq)=@_;
    $self->{vi}->Write("FREQ $freq");
}

sub get_frequency {
    my $self = shift;
    my $freq=$self->{vi}->Query("FREQ?");
    chomp $freq;
    return "$freq Hz";
}

sub set_amplitude {
    my ($self,$ampl)=@_;
    $self->{vi}->Write("SLVL $ampl");
    my $realampl=$self->{vi}->Query("SLVL?");
    chomp $realampl;
    return "$realampl V";
}

sub get_amplitude {
    my $self = shift;
    my $ampl=$self->{vi}->Query("SLVL?");
    chomp $ampl;
    return "$ampl V";
}

sub set_sens {
    # set sensitivity to value equal to or greater than argument (in V), Range 2nV..1V
    my ($self,$sens)=@_;
    my $nr = 26;

    if ($sens < 2E-9) { $nr = 0; }
    elsif ($sens <= 5E-9 ) { $nr = 1; }
    elsif ($sens <= 1E-8 ) { $nr = 2; }
    elsif ($sens <= 2E-8 ) { $nr = 3; }
    elsif ($sens <= 5E-8 ) { $nr = 4; }
    elsif ($sens <= 1E-7 ) { $nr = 5; }
    elsif ($sens <= 2E-7 ) { $nr = 6; }
    elsif ($sens <= 5E-7 ) { $nr = 7; }
    elsif ($sens <= 1E-6 ) { $nr = 8; }
    elsif ($sens <= 2E-6 ) { $nr = 9; }
    elsif ($sens <= 5E-6 ) { $nr = 10; }
    elsif ($sens <= 1E-5 ) { $nr = 11; }
    elsif ($sens <= 2E-5 ) { $nr = 12; }
    elsif ($sens <= 5E-5 ) { $nr = 13; }
    elsif ($sens <= 1E-4 ) { $nr = 14; }
    elsif ($sens <= 2E-4 ) { $nr = 15; }
    elsif ($sens <= 5E-4 ) { $nr = 16; }
    elsif ($sens <= 1E-3 ) { $nr = 17; }
    elsif ($sens <= 2E-3 ) { $nr = 18; }
    elsif ($sens <= 5E-3 ) { $nr = 19; }
    elsif ($sens <= 1E-2 ) { $nr = 20; }
    elsif ($sens <= 2E-2 ) { $nr = 21; }
    elsif ($sens <= 5E-2 ) { $nr = 22; }
    elsif ($sens <= 1E-1 ) { $nr = 23; }
    elsif ($sens <= 2E-1 ) { $nr = 24; }
    elsif ($sens <= 5E-1 ) { $nr = 25; }

    $self->{vi}->Write("SENS $nr");

    my $realsens = $self->{vi}->Query("SENS?");
    chomp $realsens;
    my @senses = ("2 nV", "5 nV", "10 nV", "20 nV", "50 nV", "100 nV", "200 nV", "500 nV", "1 µV", "2 µV", "5 µV", "10 µV", "20 µV", "50 µV", "100 nV", "200 nV", "500 µV", "1 mV", "2 mV", "5 mV", "10 mV", "20 mV", "50 mV", "100 mV", "200 mV", "500 mV", "1V");
    return $senses[$realsens];
}

sub get_sens {

    my @senses = ("2 nV", "5 nV", "10 nV", "20 nV", "50 nV", "100 nV", "200 nV", "500 nV", "1 µV", "2 µV", "5 µV", "10 µV", "20 µV", "50 µV", "100 µV", "200 µV", "500 µV", "1 mV", "2 mV", "5 mV", "10 mV", "20 mV", "50 mV", "100 mV", "200 mV", "500 mV", "1V");
    my $self = shift;
    my $nr=$self->{vi}->Query("SENS?");
    chomp $nr;
    return $senses[$nr];
}

sub set_sens_auto{
    my $self=shift;
    my $V=shift;
    my $minsens=shift;
    #print "V=$V\tminsens=$minsens\n";
    #my ($lix, $liy) = $self->read_xy();
    if (abs($V)>=$minsens/2 ){
        $self->set_sens(abs($V*2.));  
        my ($lix, $liy) = $self->read_xy();
    }
    else{
        $self->set_sens(abs($minsens));
        my ($lix, $liy) = $self->read_xy();
    }  
}

sub set_tc {
     # set time constant to value greater than or equal to argument given, value in s

    my ($self,$tc)=@_;
    my $nr = 19;

    if ($tc < 1E-5) { $nr = 0; }
    elsif ($tc < 3E-5 ) { $nr = 1; }
    elsif ($tc < 1E-4 ) { $nr = 2; }
    elsif ($tc < 3E-4 ) { $nr = 3; }
    elsif ($tc < 1E-3 ) { $nr = 4; }
    elsif ($tc < 3E-3 ) { $nr = 5; }
    elsif ($tc < 1E-2 ) { $nr = 6; }
    elsif ($tc < 3E-2 ) { $nr = 7; }
    elsif ($tc < 1E-1 ) { $nr = 8; }
    elsif ($tc < 3E-1 ) { $nr = 9; }
    elsif ($tc < 1 ) { $nr = 10; }
    elsif ($tc < 3 ) { $nr = 11; }
    elsif ($tc < 10 ) { $nr = 12; }
    elsif ($tc < 30 ) { $nr = 13; }
    elsif ($tc < 100 ) { $nr = 14; }
    elsif ($tc < 300 ) { $nr = 15; }
    elsif ($tc < 1000 ) { $nr = 16; }
    elsif ($tc < 3000 ) { $nr = 17; }
    elsif ($tc < 10000 ) { $nr = 18; }

    $self->{vi}->Write("OFLT $nr");

    my @tc = ("10 µs", "30µs", "100 µs", "300 µs", "1 ms", "3 ms", "10 ms", "30 ms", "100 ms", "300 ms", "1 s", "3 s", "10 s", "30 s", "100 s", "300 s", "1000 s", "3000 s", "10000 s", "30000 s");
    my $realtc=$self->{vi}->Query("OFLT?");
    return $tc[$realtc];


}

sub get_tc {

    my @tc = ("10 µs", "30µs", "100 µs", "300 µs", "1 ms", "3 ms", "10 ms", "30 ms", "100 ms", "300 ms", "1 s", "3 s", "10 s", "30 s", "100 s", "300 s", "1000 s", "3000 s", "10000 s", "30000 s");

    my $self = shift;
    my $nr=$self->{vi}->Query("OFLT?");
    return $tc[$nr];
}

sub read_xy {

    # get value of X and Y channel (recorded simultaneously) as array
    my $self = shift;
    my $tmp=$self->{vi}->Query("SNAP?1,2");
    chomp $tmp;
    my @arr = split(/,/,$tmp);
    return @arr;
}

sub read_rphi {

    # get value of amplitude and phase (recorded simultaneously) as array
    my $self = shift;
    my $tmp=$self->{vi}->Query("SNAP?3,4");
    chomp $tmp;
    my @arr = split(/,/,$tmp);
    return @arr;
}

sub read_channels {

    # get value of channel1 and channel2 as array
    my $self = shift;

    $self->{vi}->Query("OUTR?1");
    $self->{vi}->Query("OUTR?2");
    my $x=$self->{vi}->Query("OUTR?1");
    my $y=$self->{vi}->Query("OUTR?2");
    chomp $x;
    chomp $y;
    my @arr = ($x,$y);
    return @arr;

}

sub id {
    my $self=shift;
    $self->{vi}->Query('*IDN?');
}

              
1;

=head1 NAME

Lab::Instrument::SR830 - Stanford Research SR830 Lock-In Amplifier

=head1 SYNOPSIS

    use Lab::Instrument::SR830;
    
    my $sr830=new Lab::Instrument::SR830(0,10);

    ($x,$y) = $sr780->read_xy();
    ($r,$phi) = $sr780->read_rphi();
    
=head1 DESCRIPTION

The Lab::Instrument::SR830 class implements an interface to the
Stanford Research SR830 Lock-In Amplifier.

=head1 CONSTRUCTOR

  $sr830=new Lab::Instrument::SR830($board,$gpib);

=head1 METHODS

=head2 read_xy

  ($x,$y)= $sr830->read_xy();

Reads channels x and y simultaneously; returns an array.

=head2 read_rphi

  ($r,$phi)= $sr830->read_rphi();

Reads amplitude and phase simultaneously; returns an array.

=head2 set_sens

  $string=$sr830->set_sens(1E-7);

Sets sensitivity (value given in V); possible values are:
2 nV, 5 nV, 10 nV, 20 nV, 50 nV, 100 nV, ..., 100 mV, 200 mV, 500 mV, 1V
If the argument is not in this list, the next higher value will be chosen.

Returns the value of the sensitivity that was actually set as string.

=head2 get_sens

  $sens = $sr830->get_sens();

Returns sensitivity (as string, e.g. "50 nV").

=head2 set_tc

  $string=$sr830->set_tc(1E-3);

Sets time constant (value given in seconds); possible values are:
10 us, 30us, 100 us, 300 us, ..., 10000 s, 30000 s
If the argument is not in this list, the next higher value will be chosen.

Returns the value of the time constant that was actually set as string.

=head2 get_tc

  $tc = $sr830->get_tc();

Returns the time constant (as string, e.g. "3 ms").

=head2 set_frequency
 
  $sr830->set_frequency(334);

Sets reference frequency; value given in Hz. Values between 0.001 Hz and 102 kHz can be set.

=head2 get_frequency

  $freq=$sr830->get_frequency();

Returns reference frequency (value given in Hz).

=head2 set_amplitude

  $sr830->set_amplitude(0.005);

Sets output amplitude to the value given (in V); values between 4 mV and 5 V are possible.

=head2 get_amplitude

  $ampl=$sr830->get_amplitude();

Returns amplitude of the sine output in V.


=head2 id

  $id=$sr830->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

command to change a property like amplitude or time constant might have to be executed twice to take effect

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
