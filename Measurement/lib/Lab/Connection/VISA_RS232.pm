#!/usr/bin/perl -w

#
# RS232 Connection class for Lab::Bus::VISA
# This one implements a RS232-Standard connection on top of VISA (translates 
# RS232 settings to VISA attributes, mostly).
#




package Lab::Connection::VISA_RS232;
our $VERSION = '3.10';

use strict;
use Lab::Bus::VISA;
use Lab::Connection;
use Lab::Exception;


our @ISA = ("Lab::Connection");

our %fields = (
	bus_class => 'Lab::Bus::VISA',
	resource_name => undef,
	brutal => 0,
	timeout => 2,
	wait_status=>0, # sec;
	wait_query=>10e-6, # sec;
	read_length=>1000, # bytes
	rs232_address => undef,
);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $twin = undef;
		
	my $self = $class->SUPER::new(@_); # getting fields and _permitted from parent class, parameter checks
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	
	return $self;
}


#
# adapting bus setup to VISA
#
sub _setbus {
	my $self=shift;
	my $bus_class = $self->bus_class();

	no strict 'refs';
	$self->bus($bus_class->new($self->config())) || Lab::Exception::Error->throw( error => "Failed to create bus $bus_class in " . __PACKAGE__ . "::_setbus.\n");
	use strict;

	#
	# build VISA resource name
	#
	if (not defined $self->rs232_address())
		{
		Lab::Exception::UndefinedField->throw(error => 'No rs232 address defined !');
		}
		
	my $resource_name = "ASRL";
	$resource_name .= $self->rs232_address();
	$resource_name .= '::INSTR';
	$self->resource_name($resource_name);
	$self->config()->{'resource_name'} = $resource_name;
	
	# again, pass it all.
	$self->connection_handle( $self->bus()->connection_new( $self->config() ));
	
	
	return $self->bus();
	
}

sub _configurebus {
	my $self = shift;
	
	
	#
	# set VISA Attributes:
	#
	
	
	# boudrate
	$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_ASRL_BAUD, $self->config()->{baudrate});
	
	# databits
	$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_ASRL_DATA_BITS, $self->config()->{databits});
	
	# parity
	my $parity;
	if ( $self->config()->{parity} eq 'none' ) { $parity = 0; }
	elsif ( $self->config()->{parity} eq 'odd' ) { $parity = 1; }
	elsif ( $self->config()->{parity} eq 'even' ) { $parity = 2; }
	elsif ( $self->config()->{parity} eq 'mark' ) { $parity = 3; }
	elsif ( $self->config()->{parity} eq 'space' ) { $parity = 4; }
	else { $parity = $self->config()->{parity}; }	
	$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_ASRL_PARITY, $parity);
	
	# stop bits
	my $stopbits;
	if ( $self->config()->{stopbits} == 1 )
		{
		$stopbits =  $Lab::VISA::VI_ASRL_STOP_ONE;
		}
	elsif ( $self->config()->{stopbits} == 1.5 )
		{
		$stopbits =  $Lab::VISA::VI_ASRL_STOP_ONE5;
		}
	elsif ( $self->config()->{stopbits} == 2 )
		{
		$stopbits =  $Lab::VISA::VI_ASRL_STOP_TWO;
		}
	else
		{
		$stopbits = $self->config()->{stopbits};
		}
	$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_ASRL_STOP_BITS, $stopbits);
	
	# termination character
	if ( defined $self->config()->{termchar} )
		{
		$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_TRUE);
		$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_TERMCHAR, $self->config()->{termchar});
		}
	else
		{
		$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_FALSE);
		}
	
	# read timeout
	$self->bus()->set_visa_attribute($self->connection_handle(), $Lab::VISA::VI_ATTR_TMO_VALUE, $self->config()->{timeout}*1e3);

	
}




1;

#
# Read,Write,Query are OK in the version from Lab::Connection
#


=pod

=encoding utf-8

=head1 NAME

Lab::Connection::VISA_RS232 - RS232-type connection class which uses L<Lab::Bus::VISA> 
and thus NI VISA (L<Lab::VISA>) as a backend.

=head1 SYNOPSIS

This class is not called directly. To make a RS232 suppporting instrument use 
Lab::Connection::VISA_RS232, set the connection_type parameter accordingly:

 $instrument = new BlaDeviceType(
    connection_type => 'VISA_RS232',
    rs232_adress => 1
 )

=head1 DESCRIPTION

C<Lab::Connection::VISA_RS232> provides a RS232-type connection with L<Lab::Bus::VISA> using
NI VISA (L<Lab::VISA>) as backend.

It inherits from L<Lab::Connection::RS232> and subsequently from L<Lab::Connection>.

The main feature is to set upon initialization all the RS232 libe parameters
  baud_rate
  ...

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::VISA_RS232(
    rs232_adress => 1,
    baud_rate => 9600,
 )


=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.


=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $RS232_Address=$instrument->Config(rs232_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $RS232_Address = $connection->Config()->{'rs232_address'};
 
=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::RS232>

=item * L<Lab::Connection::VISA>

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich
           2012      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
