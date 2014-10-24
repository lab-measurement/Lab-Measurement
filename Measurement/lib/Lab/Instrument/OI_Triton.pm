package Lab::Instrument::OI_Triton;
our $VERSION = '3.40';
use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
	supported_connections => [ 'Socket', 'VISA' ],

	# default settings for the supported connections
	connection_settings => {
		remote_port=>33576,
		remote_addr=>'triton',
	},
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__); 

	return $self;
}

sub get_temperature {
  my $self = shift;
  my $channel = shift;
  $channel = "1" unless defined($channel);

  my $temp=$self->query("READ:DEV:T$channel:TEMP:SIG:TEMP\n");
  # typical response: STAT:DEV:T1:TEMP:SIG:TEMP:1.47628K

  $temp=~s/^.*:SIG:TEMP://;
  $temp=~s/K.*$//;
  return $temp;
};



1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::OI_Triton - Oxford Instruments Triton DR Control

=head1 SYNOPSIS

    use Lab::Instrument::OI_Triton;
    
    my $m=new Lab::Instrument::OI_Triton(
      connection_type=>'Socket', 
      remote_port=>33576, 
      remote_addr=>'triton',
    );

=head1 DESCRIPTION

The Lab::Instrument::OI_Triton class implements an interface to the Oxford Instruments 
Triton dilution refrigerator control system.

=head1 METHODS

=head2 get_temperature

   $t=$m->get_temperature('1');

Read out the designated temperature channel. Result is in Kelvin (?).

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2014 Andreas K. Hüttel (L<http://www.akhuettel.de/>)

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
