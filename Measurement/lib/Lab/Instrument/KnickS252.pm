package Lab::Instrument::KnickS252;
use strict;
use Lab::Instrument;
use Lab::Instrument::Source;

our $VERSION="3.32";

our @ISA=('Lab::Instrument::Source');

our %fields = (
	supported_connections => [ 'GPIB', 'VISA' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => undef,
		timeout => 1
	},

	device_settings => {
		gate_protect            => 1,
		gp_equal_level          => 1e-5,
		gp_max_units_per_second  => 0.005,
		gp_max_units_per_step    => 0.001,
		gp_max_step_per_second  => 5,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
		
		stepsize		=> 0.01,

        read_default => 'device'
	},
	
	
	device_cache => {
        id => 'KnickS252',
		range			=> undef,
		level			=> undef,
	},
	
	device_cache_order => ['function','range'],
	request => 0
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	
    print "the new Knick S252 code is untested so far...\n";
    return $self;
}

sub set_voltage {
    my $self=shift;
    my ($voltage) = $self->_check_args( \@_, ['voltage'] );
    return $self->set_level($voltage, @_);
}

sub _set_level {    
    my $self=shift;
    my ($value) = $self->_check_args( \@_, ['value'] );
    
    my $range=$self->get_range();
    
    if ( $value > $range || $value < -$range ){
        Lab::Exception::CorruptParameter->throw("The desired source level $value is not within the source range $range \n");
    }

    my $cmd=sprintf("X OUT %e\n",$voltage);    
    $self->write( $cmd, error_check => 1 );
    
    return $self->{'device_cache'}->{'level'} = $value;
}

sub get_level { 
    my $self=shift;
    my $cmd="R OUT\n";
    my $result;
    
    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if (not defined $read_mode or not $read_mode =~/device|cache|request|fetch/)
	{
	    $read_mode = $self->device_settings()->{read_default};
	}

    if($read_mode eq 'cache' and defined $self->{'device_cache'}->{'level'})
		{
		  return $self->{'device_cache'}->{'level'};
		}  
	elsif($read_mode eq 'request' and $self->{request} == 0 )
		{
		   $self->{request} = 1;
		   $self->write($cmd);
		   return;
		}
	elsif($read_mode eq 'request' and $self->{request} == 1 )
		{
		   $result = $self->read();
		   $self->write($cmd);
		   return;
		}
	elsif ($read_mode eq 'fetch' and $self->{request} == 1)
		{
		   $self->{request} = 0;
		   $result = $self->read();
		}
	else
		{
		if ( $self->{request} == 1 )
			{
			$result = $self->read();
			$self->{request} = 0;
			$result = $self->query($cmd);
			}
		else
			{
			$result = $self->query($cmd);
			}
		}
   
    $result=~/^OUT\s+([\d\.E\+\-]+)V/;
    return $self->{'device_cache'}->{'level'} = $1;
}

sub get_value { 
    my $self = shift;
    return $self->get_level(@_); 
}

sub get_voltage{    
    my $self=shift;
    return $self->get_level(@_);
}


sub set_range { 
    my $self=shift;
    my ($range) = $self->_check_args( \@_, ['range'] );
	
    if ($range <= 5) {$range = 5;}
        elsif ($range <= 20) {$range = 20;}
        else 
            { 
            Lab::Exception::CorruptParameter->throw( error=>  "unexpected value for RANGE in sub set_range. Expected values are 5V or 20V");
            }

    my $cmd = "P RANGE $range\n";

    $self->write($cmd);
    return $self->{'device_cache'}->{'range'} = $self->get_range();
}



sub get_range{  
    my $self=shift;
    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if (not defined $read_mode or not $read_mode =~ /device|cache/)
    {
        $read_mode = $self->device_settings()->{read_default};
    }    
    if($read_mode eq 'cache' and defined $self->{'device_cache'}->{'range'})
    {
        return $self->{'device_cache'}->{'range'};
    } 
    
    my $cmd="R RANGE\n";
        #  5     5V
        # 20    20V
    my $result=$self->query($cmd);
    my $range=$result=~/^RANGE\s+((AUTO)|5|(20))/;

    return $self->{'device_cache'}->{'range'} = $range;
}


1;

=head1 NAME

Lab::Instrument::KnickS252 - Knick S 252 DC source

=head1 SYNOPSIS

    use Lab::Instrument::KnickS252;
    
    my $gate14=new Lab::Instrument::KnickS252(0,11);
    $gate14->set_range(5);
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::KnickS252 class implements an interface
to the Knick S 252 dc calibrator. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTOR

    $knick=new Lab::Instrument::KnickS252($gpib_board,$gpib_addr);
    # Or any other type of construction supported by Lab::Instrument.

=head1 METHODS

=head2 set_voltage

    $knick->set_voltage($voltage);

=head2 get_voltage

    $voltage=$knick->get_voltage();

=head2 set_range

    $knick->set_range($range);
    # $range is 5 or 20
    #  5  is 5V
    # 20  is 20V

=head2 get_range

    $range=$knick->get_range();
    # $range is 5 or 20
    #  5  is 5V
    # 20  is 20V

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item Lab::Instrument

The Lab::Instrument::KnickS252 class is a Lab::Instrument (L<Lab::Instrument>).

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2004/2005 Daniel Schröer
            2013      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
