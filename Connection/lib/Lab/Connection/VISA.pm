#!/usr/bin/perl -w
# POD

package Lab::Interface::VISA;

# this is only a wrapper package for Lab::Visa to provide the
# new interface package approach also for VISA

use strict;
use warnings;

use Lab::Interface; 
use Lab::VISA;

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

sub new {
	my $self = shift;
	# create hash ref
	my $object = {};
	# create object
	bless ($object,$self);
	# get arguments
	my %args = @_;

	# open resource manager
	my ($status,$res)=Lab::VISA::viOpenDefaultRM();
        if ($status != $Lab::VISA::VI_SUCCESS) {
            if (exists $args{'ForceRM'}) { 
              print STDERR "Warning: Resource Manager Error reduced to Warning!\n";
            } else {
		      die "Cannot open resource manager: $status";
            }
	}
    $object->{default_rm}=$res;
    return $object;
};


sub InstrumentNew {
	my $self = shift;
	# get arguments
	my %args = @_;

        my $resource_name;
	# resource string given
	if (exists $args{'ResString'}) {
		$resource_name = $args{'ResString'};
	} 
	# board and addr given (untested by vkr - I have no card)
	if (exists $args{'GPIBaddr'}) {
		# create if missing
		$args{'GPIBboard'}=0 unless (exists $args{'GPIBboard'};
		$resource_name=sprintf("GPIB%u::%u::INSTR",$args{'GPIBboard'},
				$args{'GPIBaddr'});
	}
	# via network like Tektronix AFG
	if (exists $args{'IPaddr'}) {
		# create network card if missing
		$args{'NetCard'} = 0 unless (exists $args{'NetCard'});
		$resource_name=sprintf("TCPIP%u::%u::INSTR",$args{'NetCard'},
				$args{'IPaddr'});
	}
	# open device
	my $visahandle;
	if ($resource_name) {
        	($status,$visahandle)=Lab::VISA::viOpen(
			$self->{default_rm},
			$resource_name,
			$Lab::VISA::VI_NULL,
			$Lab::VISA::VI_NULL);
        	if ($status != $Lab::VISA::VI_SUCCESS) { 
			die "Cannot open VISA instrument \"$resource_name\". Status: $status";
		}
		
        	$status=Lab::VISA::viSetAttribute(
			$visahandle, 
			$Lab::VISA::VI_ATTR_TMO_VALUE, 
			3000);
        	if ($status != $Lab::VISA::VI_SUCCESS) { 
			die "Error while setting timeout value: $status";
		}
	} else die "Need a valid VISA resource name\n";    

	my %instrument={'valid' -> 1, 'type'->"VISA", 'visahandle' -> $visahandle};  
	return %instrument;
}

# functionality

sub InstrumentClear { # $self=Interface, %handle
	my $self=shift;
	my %handle=shift;
    
	my $status=Lab::VISA::viClear($handle{'visahandle'});
    	if ($status != $Lab::VISA::VI_SUCCESS) { 
		die "Error while clearing instrument: $status";
	}
}

sub InstrumentRead { # $self=Interface, %handle
	my $self = shift;
	my %handle=shift;

	my $result = "";
    	my $read_cnt = 0;

	(my $status,$result,$read_cnt)=Lab::VISA::viRead(
				$handle{'visahandle'},
				1000);
	$result = substring($result,0,$read_cnt);

	# next read?
      	while ((($status == $Lab::VISA::VI_SUCCESS) or ($status == 0x3FFF0005)) and ($read_cnt == 1000)){
        	# read again
        	($status,my $buf,$read_cnt)=Lab::VISA::viRead(
				$handle{'visahandle'},
				1000);
        	# add to last
        	$result .= substring($buf,0,$read_cnt);
      	}
      	# check status
      	if (($status != $Lab::VISA::VI_SUCCESS) 
	  	  && ($status != 0x3FFF0005)) {
		  die "Error while reading: $status";
	}
      	# set correct value for return
      	$read_cnt=length($result);
	return substr($result,0,$read_cnt);
}


sub InstrumentBrutalRead {
	my $self = shift;
	my %handle=shift;

	my ($status,$result,$read_cnt)=Lab::VISA::viRead(
				$handle{'visahandle'},
				$length);
	
	return substr($result,0,$read_cnt);
}

sub InstrumentWrite {
	my $self = shift;
	my %handle=shift;
	my $cmd=shift;

	my $wait_status=$WAIT_STATUS;
	if ($arg_cnt==3){ $wait_status=shift}
	my ($status, $write_cnt)=Lab::VISA::viWrite(
				$handle{'visahandle'},
				$cmd,
				length($cmd)
			);
	usleep($wait_status);
	if ($status != $Lab::VISA::VI_SUCCESS) { 
		die "Error while writing string \"\n$cmd\n\": $status";
	}
	return $write_cnt;
}


sub InstrumentDestroy { 
    	my $self=shift;
	my %handle=shift;
	my $status=Lab::VISA::viClose($handle{'visahandle'});
}

sub DESTROY {
    	my $self=shift;
	my $status=Lab::VISA::viClose($self->{instr});
	$status=Lab::VISA::viClose($self->{default_rm});
}



1;
__END__

=head1 NAME

Lab::Instrument::VISA - Perl extension for interfacing with instruments via VISA

THIS IS ONLY AN EXAMPLE - THIS PACKGE IS COMPLETELY UNTESTED!!!

=head1 SYNOPSIS

  use Lab::Instrument;
  my $h1 = Lab::Instrument->new( Interface => 'VISA',
                                 ResString => 'TCPIP0::cs025::INSTR');
  my $h2 = Lab::Instrument->new( Interface => 'VISA',
                                 GPIBaddr  => 12 ); # use GPIB board 0
  my $h3 = Lab::Instrument->new( Interface => 'VISA',
                                 GPIBboard => 1,
				                 GPIBaddr  => 12 ); 
  my $h4 = Lab::Instrument->new( Interface => 'VISA',
                                 IPaddr    => 'cs025'); # use network 0
  my $h5 = Lab::Instrument->new( Interface => 'VISA',
                                 IPaddr  => 'cs025',
				                 NetCard => 1);
  
=head1 DESCRIPTION

This is an interface package for Lab::Instruments to communicate via the 
Lab::VISA package. It is only a small wrapper. The work is done by Lab::VISA and
the NI VISA library.

=head1 SEE ALSO

See documentation of C<Lab::VISA>.

=head1 AUTHOR

Matthias Volker, E<lt>mvoelker@cpan.org<gt

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Matthias Voelker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
