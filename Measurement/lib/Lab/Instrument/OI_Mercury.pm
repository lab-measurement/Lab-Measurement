package Lab::Instrument::OI_Mercury;
our $VERSION = '3.10';
use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
	supported_connections => [ 'IsoBus', 'Socket', 'GPIB', 'VISA' ],
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__); 

	return $self;
}

sub get_he_level {
  my $self = shift;
  my $channel = shift;
  $channel = "DB5.L1" unless defined($channel);
  
  my $level=$self->query("READ:DEV:$channel:LVL:SIG:HEL\n");
  # typical response: STAT:DEV:DB5.L1:LVL:SIG:HEL:LEV:56.3938%:RES:47.8665O

  $level=~s/^.*:LEV://;
  $level=~s/%.*$//;
  return $level;  
};

sub get_n2_level {
  my $self = shift;
  my $channel = shift;
  $channel = "DB5.L1" unless defined($channel);
  
  my $level=$self->query("READ:DEV:$channel:LVL:SIG:NIT\n");
  # typical response: STAT:DEV:DB5.L1:LVL:SIG:NIT:COUN:10125.0000n:FREQ:472867:LEV:52.6014%

  $level=~s/^.*:LEV://;
  $level=~s/%.*$//;
  return $level;  
};

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::OI_Mercury - Oxford Instruments Mercury Cryocontrol

=head1 SYNOPSIS

    use Lab::Instrument::OI_Mercury;
    
    my $ilm=new Lab::Instrument::OI_Mercury(
      connection_type=>'Socket', 
      remote_port=>7020, 
      remote_addr=>1.2.3.4,
    );

=head1 DESCRIPTION

The Lab::Instrument::OI_Mercury class implements an interface to the Oxford Instruments 
Mercury cryostat control system.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2013 Andreas K. Hüttel (L<http://www.akhuettel.de/>)

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
