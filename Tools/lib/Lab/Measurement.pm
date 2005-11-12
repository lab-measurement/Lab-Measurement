#$Id$

package Lab::Measurement;

use 5.008;
use strict;
use warnings;
use FileHandle;
require Exporter;

our @ISA = qw(Exporter);

our $VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

our $AUTOLOAD;

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;

	my $self = {};
    bless ($self, $class);

    my $filename=shift;
	$self->{filename}=$filename;
	
	$self->configure(@_);
	
	$self->{Filehandle}=new FileHandle(">$filename") or die;
	
	return $self
}

sub configure {
	my $self=shift;
	my $config=shift;
	my $default_config={
		col_sep			=> "\t",
		line_sep		=> "\n",
		block_sep		=> "\n",
		comment_char	=> "#",
	};
	for my $conf_name (keys %$default_config) {
		unless ((defined($self->{config}->{$conf_name})) || (defined($config->{$conf_name}))) {
			$self->{config}->{$conf_name}=$default_config->{$conf_name};
		} elsif (defined($self->{config}->{$conf_name})) {
			$self->{config}->{$conf_name}=$config->{$conf_name};
		}
	}
}

sub DESTROY {
	my $self=shift;
	close($self->{Filehandle});
}

#Methoden für nicht-magisches Interface

sub log_block {
	my $self=shift;
	my $comment=shift;
}

sub log_line {
	my $self=shift;
	my @data=shift;
}

#magisches Interface
sub log {
	my $self=shift;
	my ($datum,$column,$description)=@_;
	
	if ((defined $self->{magic_log}->{column}->[$column]->{status})
		&& ($self->{magic_log}->{column}->[$column]->{status} eq 'fresh')) {
		#spalte enthält wert, der noch nicht geloggt worden ist
		unless ($self->{magic_log}->{started}) {
			#header müssen erst noch erzeugt werden
			$self->{magic_log}->{started}=1;
			my $cc=$self->{config}->{comment_char};
			my $nl=$self->{config}->{line_sep};
			my $header_text="$cc Data recorded by $0 on ".localtime(time).$nl;
			for (0..$#{$self->{magic_log}->{column}}) {
				$header_text.=sprintf("%s column %u: %s%s",$cc,$_,$self->{magic_log}->{column}->[$_]->{description},$nl);
			}
			print {$self->{Filehandle}} $header_text;
		}
		my $num_unfresh=0;
		# weiss nimmer was das soll
		for (@{$self->{magic_log}->{column}}) {
			if ($_->{status} eq 'set') {
				$num_unfresh++;
			}
		}
		
		#ist das die letzte Spalte?
		if ($column == $#{$self->{magic_log}->{column}}) {
			#ausgeben
			for my $col_num (0..$#{$self->{magic_log}->{column}}) {
				print {$self->{Filehandle}} $self->{magic_log}->{column}->[$col_num]->{datum};
				if ($col_num < $#{$self->{magic_log}->{column}}) {
					print {$self->{Filehandle}} $self->{config}->{col_sep};
				}
				$self->{magic_log}->{column}->[$col_num]->{status}='set';
			}
			print {$self->{Filehandle}} $self->{config}->{line_sep};
		} else {
		#	warn "Du Bauer hast irgendwas verbockt: $column $datum\n";
			$self->{magic_log}->{column}->[$column]->{status}='fresh';
			$self->{magic_log}->{column}->[$column]->{datum}=$datum;
		}			
	} else {
		#spalte momentan leer
		unless ($self->{magic_log}->{column}->[$column]->{status}) {
			$self->{magic_log}->{column}->[$column]->{description}=$description;
		}
		$self->{magic_log}->{column}->[$column]->{status}='fresh';
		$self->{magic_log}->{column}->[$column]->{datum}=$datum;
	}
}

1;
__END__

=head1 NAME

Lab::Measurement - Perl extension for logging measured data 

=head1 SYNOPSIS

	use Lab::Measurement;
	my $logger=new Lab::Measurement('data.dat');
	for (1..10) {
		$logger->log($_,0,'Outer loop');
		for (1..100) {
			$logger->log($_,1,'Inner loop');
		}
	}

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new($filename,[$config])

=head1 METHODS

=head2 configure($config)

	my $default_config={
		col_sep		=> "\t",
		line_sep	=> "\n",
		block_sep	=> "\n",
	};

=head2 log($datum,$column,$description)

=head1 SEE ALSO

=head1 AUTHOR/COPYRIGHT

This is $Id: Datalog.pm,v 1.2 2005/01/31 22:44:16 manonegra Exp $

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
