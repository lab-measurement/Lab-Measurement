package Lab::Instrument::SpectrumSCPI;
our $VERSION = '3.10';

use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => [ 'GPIB' ],

    connection_settings => {
        gpib_board => 0,
        gpib_address => undef,
    },

    device_settings => {

    },
    

);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    $self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
    $self->connection()->Clear();
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

sub set_power_unit
{
    my $self = shift;
    my $unit = shift || "DBM"; #DBM, W
    $self->write("UNIT:POW $unit");
}

sub set_frequency
{
    my $self = shift;
    my $freq = shift || "DEF"; #Hz
    $self->write("FREQ:CENT $freq");
}

sub set_span
{
    my $self = shift;
    my $span = shift || "DEF"; #Hz
    $self->write("FREQ:SPAN $span");
}

sub set_bandwidth
{
    my $self = shift;
    my $bw = shift || "DEF"; #Hz
    $self->write("BAND:RES $bw");
}

sub set_sweep_time
{
    my $self = shift;
    my $time = shift || "DEF"; #Hz
    $self->write("SWE:Time $time");
}

sub set_continous
{
    my $self = shift;
    my $cont = shift || "ON"; #ON, OFF
    $self->write("INIT:CONT $cont");
}

sub set_time_domain
{
    my $self = shift;
    my $freq = shift;
    my $bw   = shift;
    $self->set_continous("OFF");
    $self->set_frequency($freq);
    $self->set_span("0 Hz");
    $self->set_bandwidth($bw);
    $self->set_sweep_time("2000 US"); #TODO
}

sub read_rms
{
    my $self = shift;
    $self->write("INIT;*WAI");
    $self->write("CALC:MARK:FUNC:SUMM:RMS ON");
    return $self->query(":CALC:MARK:FUNC:SUMM:RMS:RES?");
}
#
sub read
{
    my $self = shift;
    #TODO: Check other modes
    return $self->query("READ?");
    
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
        if ($current_error =~ m/^\+?0,/) { last; }
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

Lab::Instrument::SpectrumSCPI - Spectrum Analyzer with SCPI command set

=head1 DESCRIPTION

The Lab::Instrument::SpectrumSCPI class implements a generic interface to
digital spectrum analyzers with SCPI command set. It is tested against a
R&S FSV 7.

=head1 CONSTRUCTOR

    my $spectrum=new(\%options);

=head1 METHODS

=head2 read

    $value=$spectrum->read();

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
