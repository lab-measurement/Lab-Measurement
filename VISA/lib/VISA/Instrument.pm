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

	$self->Connect(@_);

	return $self
}

sub find {
	my $proto = shift;
    my $expr=shift;
	my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

	my ($status,$res)=VISA::viOpenDefaultRM();
	if ($status != $VISA::VI_SUCCESS) { die "Cannot open resource manager: $status";}
	$self->{default_rm}=$res;

	($status,my $listhandle,my $count,my $description)=VISA::viFindRsrc($self->{default_rm},'?*INSTR');
	if ($status != $VISA::VI_SUCCESS) { die "Cannot find resources: $status";}	
	my $found;
	while ($count-- > 0) {
		($status,my $instrument)=VISA::viOpen($self->{default_rm},$description,$VISA::VI_NULL,$VISA::VI_NULL);
		if ($status != $VISA::VI_SUCCESS) { die "Cannot open instrument $description. status: $status";}
		my $cmd='*IDN?';
		$self->{instr}=$instrument;
		my $result=$self->Query($cmd);
		$status=VISA::viClose($instrument);
		if ($status != $VISA::VI_SUCCESS) { die "Cannot close instrument $description. status: $status";}
		if ($result =~ $expr) {
			$found=$description;
			$count=0;
		}
		if ($count) {
			($status, $description)=VISA::viFindNext($listhandle);
			if ($status != $VISA::VI_SUCCESS) { die "Cannot find next instrument: $status";}
		}
	}
	$status=VISA::viClose($listhandle);
	if ($status != $VISA::VI_SUCCESS) { die "Cannot close find list: $status";}
	
	if ($found) {
		($status,my $instrument)=VISA::viOpen($self->{default_rm},$description,$VISA::VI_NULL,$VISA::VI_NULL);
		if ($status != $VISA::VI_SUCCESS) { die "Cannot open instrument $description. status: $status";}
		$self->{instr}=$instrument;
		
		$status=VISA::viClear($self->{instr});
		if ($status != $VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
		
		$status=VISA::viSetAttribute($self->{instr}, $VISA::VI_ATTR_TMO_VALUE, 3000);
		if ($status != $VISA::VI_SUCCESS) { die "Error while setting timeout value: $status";}
	
		return $self;
	}
	return 0;
}

sub Connect {
    my $self = shift;
	my ($gpib_board,$gpib_addr)=@_;
	
	my ($status,$res)=VISA::viOpenDefaultRM();
	if ($status != $VISA::VI_SUCCESS) { die "Cannot open resource manager: $status";}
	$self->{default_rm}=$res;
	
	my $resource_name;
	if ($gpib_board =~ /ASRL/) {	# serial
		$resource_name=$gpib_board."::INSTR";
	} else { # GPIB
		$resource_name=sprintf("GPIB%u::%u::INSTR",$gpib_board,$gpib_addr);
	}
	($status,$res)=VISA::viOpen($self->{default_rm},
								$resource_name,
								$VISA::VI_NULL,$VISA::VI_NULL);
	if ($status != $VISA::VI_SUCCESS) { die "Cannot open instrument: $status";}
	$self->{instr}=$res;
	
	$status=VISA::viClear($self->{instr});
	if ($status != $VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
	
	$status=VISA::viSetAttribute($self->{instr}, $VISA::VI_ATTR_TMO_VALUE, 3000);
	if ($status != $VISA::VI_SUCCESS) { die "Error while setting timeout value: $status";}
}


sub Write {
	my $self=shift;
	my $cmd=shift;
	my ($status, $write_cnt)=VISA::viWrite($self->{instr},
										   $cmd,
										   length($cmd));
	if ($status != $VISA::VI_SUCCESS) { die "Error while reading voltage: $status";}
	return $write_cnt;
}

sub Query {
	my $self=shift;
	my $cmd=shift;
	my ($status, $write_cnt)=VISA::viWrite($self->{instr},
										   $cmd,
										   length($cmd));
	if ($status != $VISA::VI_SUCCESS) { die "Error while reading voltage: $status";}
	
	($status,my $result,my $read_cnt)=VISA::viRead($self->{instr},300);
	if ($status != $VISA::VI_SUCCESS) { die "Error while reading voltage: $status";}
	return $result;
}

sub DESTROY {
	my $self=shift;
	my $status=VISA::viClose($self->{instr});
	$status=VISA::viClose($self->{default_rm});
}

1;

=head1 NAME

VISAInstrument - Base class for VISA based instrument classes

=head1 SYNOPSIS

    use VISAInstrument;
    our @ISA=('VISAInstrument');

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 DESTROY;

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item VISA

The VISA::Instrument class uses the VISA module (L<VISA>).

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
