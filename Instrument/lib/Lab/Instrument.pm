#$Id$

package VISA::Instrument;

use strict;
use VISA;

our $VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

	my @args=@_;
	
	my ($status,$res)=VISA::viOpenDefaultRM();
	if ($status != $VISA::VI_SUCCESS) { die "Cannot open resource manager: $status";}
	$self->{default_rm}=$res;

	my $resource_name;
	if ((ref $args[0]) eq 'HASH') {
		my $config=$args[0];
		if (defined ($config->{GPIB_address})) {
			@args=(
				(defined ($config->{GPIB_board})) ? $config->{GPIB_board} : 0,
				 $config->{GPIB_address});
		} else {
			die "scheiss argumente";
		}
	}
	if ($#args >0) { # GPIB
		$resource_name=sprintf("GPIB%u::%u::INSTR",$args[0],$args[1]);
	} elsif ($args[0] =~ /ASRL/) {	# serial
		$resource_name=$args[0]."::INSTR";
	} else {	#find
		($status,my $listhandle,my $count,my $description)=VISA::viFindRsrc($self->{default_rm},'?*INSTR');
		if ($status != $VISA::VI_SUCCESS) { die "Cannot find resources: $status";}	
		my $found;
		while ($count-- > 0) {
			print STDERR  "VISA::Instrument: checking $description\n";
			($status,my $instrument)=VISA::viOpen($self->{default_rm},$description,$VISA::VI_NULL,$VISA::VI_NULL);
			if ($status != $VISA::VI_SUCCESS) { die "Cannot open instrument $description. status: $status";}
			my $cmd='*IDN?';
			$self->{instr}=$instrument;
			my $result=$self->Query($cmd);
			$status=VISA::viClose($instrument);
			if ($status != $VISA::VI_SUCCESS) { die "Cannot close instrument $description. status: $status";}
			print STDERR  "VISA::Instrument: id $result\n";
			if ($result =~ $args[0]) {
				$resource_name=$description;
				$count=0;
			}
			if ($count) {
				($status, $description)=VISA::viFindNext($listhandle);
				if ($status != $VISA::VI_SUCCESS) { die "Cannot find next instrument: $status";}
			}
		}
		$status=VISA::viClose($listhandle);
		if ($status != $VISA::VI_SUCCESS) { die "Cannot close find list: $status";}		
	}
	
	if ($resource_name) {
		($status,my $instrument)=VISA::viOpen($self->{default_rm},$resource_name,$VISA::VI_NULL,$VISA::VI_NULL);
		if ($status != $VISA::VI_SUCCESS) { die "Cannot open instrument $resource_name. status: $status";}
		$self->{instr}=$instrument;
		
#		$status=VISA::viClear($self->{instr});
#		if ($status != $VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
		
		$status=VISA::viSetAttribute($self->{instr}, $VISA::VI_ATTR_TMO_VALUE, 3000);
		if ($status != $VISA::VI_SUCCESS) { die "Error while setting timeout value: $status";}
	
		return $self;
	}
	return 0;
}

sub Clear {
	my $self=shift;
	
	my $status=VISA::viClear($self->{instr});
	if ($status != $VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
}

sub Write {
	my $self=shift;
	my $cmd=shift;
	my ($status, $write_cnt)=VISA::viWrite($self->{instr},
										   $cmd,
										   length($cmd));
	if ($status != $VISA::VI_SUCCESS) { die "Error while writing: $status";}
	return $write_cnt;
}

sub Query {
	my $self=shift;
	my $cmd=shift;
	my ($status, $write_cnt)=VISA::viWrite($self->{instr},
										   $cmd,
										   length($cmd));
	if ($status != $VISA::VI_SUCCESS) { die "Error while writing: $status";}
	
	($status,my $result,my $read_cnt)=VISA::viRead($self->{instr},300);
	if ($status != $VISA::VI_SUCCESS) { die "Error while reading: $status";}
	return substr($result,0,$read_cnt);
}

sub Handle {
	my $self=shift;
	return $self->{instr};
}

sub DESTROY {
	my $self=shift;
	my $status=VISA::viClose($self->{instr});
	$status=VISA::viClose($self->{default_rm});
}

1;

=head1 NAME

VISA::Instrument - Worker class for VISA based instrument classes

=head1 SYNOPSIS

 use VISA::Instrument;
 
 my $hp22=	new VISA::Instrument(0,22);
 my $id=$hp22->Query('*IDN?');

=head1 DESCRIPTION

This class describes a general visa based instrument.

It can be used either directly by the laborant (programmer) to work with
an instrument that doesn't have its own perl class
(like VISA::Instrument::HP34401A). Or it can be used by such a specialized
perl instrument class (like VISA::Instrument::HP34401A), to delegate the
actual visa work. (All the instruments in the default package do so.)

=head1 CONSTRUCTORS

=head2 new

 $instrument=new VISA::Instrument($gpib_board,$gpib_addr);

=head1 METHODS

=head2 Write

 $write_count=$instrument->Write($command);

=head2 Query

 $result=$instrument->Query($command);

=head2 Clear

 $instrument->Clear();

=head2 Handle

 $instr_handle=$instrument->Handle();

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item VISA

The VISA::Instrument class uses the VISA module (L<VISA>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004/2005 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
