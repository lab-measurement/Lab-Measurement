#!/usr/bin/perl -w

#$Id$

package Lab::Data::Importer;

use strict;
use Carp;
use Data::Dumper;
use File::Basename;
use Lab::Data::Meta;

my $default_config = {
	output_data_ext		=> "DATA",
	output_meta_ext		=> "META",
	output_col_sep		=> "\t",
	output_line_sep		=> "\n",
	output_block_sep	=> "\n",
	output_comment_char	=> "# ",
};

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
	
	my ($config,$basepathname)=@_;
	
	unless (ref $config =~ /HASH/) {
		$basepathname=$config;
		$config={};
	}
	$self->configure($config);

	$self->{Data}=undef;
	$self->{Description}=Lab::XMLtree->new($description_def);
	
	if ($basepathname) {
		my ($basename,$path,$suffix)=fileparse($basepathname,qr{\..*});
		$self->filename_path($path);
		$self->filename_base($basename);
	}
	
    return $self;
}

sub configure {
	my $self=shift;
	my $config=shift;

	for my $conf_name (keys %{$default_config}) {
		unless ((defined($self->{Config}->{$conf_name})) || (defined($config->{$conf_name}))) {
			$self->{Config}->{$conf_name}=$default_config->{$conf_name};
		} elsif (defined($self->{config}->{$conf_name})) {
			$self->{Config}->{$conf_name}=$config->{$conf_name};
		}
	}
}

sub import_gpplus {
	my $self=shift;
	my @files=@_;
	my ($basename,$path,$suffix)=fileparse($files[0],qr{\..*});
	$basename=~s/([^_])_\d+/$1/;
	if (my ($data,$desc)=$self->_load_gpplus_data(@files)) {
		$self->{Data}=$data;
		$self->{Description}->merge_tree($desc);
		$self->filename_base($basename);
		unless ($self->dataset_title()) {
			$self->dataset_title($basename);
		}
		return 1;
	}
	return 0;
}

sub save_data {
	my $self=shift;
	open(DATAOUT, ">".$self->filename_path().$self->filename_base().".".$self->{Config}->{output_data_ext}) or die;
	for my $blocknum (0..$#{$self->{Data}}) {
		print DATAOUT $self->{Config}->{output_comment_char}," Block $blocknum\n";
		for my $line (0..$#{$self->{Data}->[$blocknum]}) {
			for my $col (0..$#{$self->{Data}->[$blocknum]->[$line]}) {
				print DATAOUT	$self->{Data}->[$blocknum]->[$line]->[$col],
								($col == $#{$self->{Data}->[$blocknum]->[$line]}) ?
									"" : $self->{Config}->{output_col_sep};
			}
			print DATAOUT $self->{Config}->{output_line_sep};
		}
		print DATAOUT $self->{Config}->{output_block_sep};
	}
	close DATAOUT;
}

sub save_description {
	my $self=shift;
	my $filename=shift;
	
	$self->{Description}->save_xml($filename,$self->{Description},"data_description");
}

# generalized data loader bräuchte
# blocksep => [FILE,\n,...]		(wobei er einfach alle filenames für FILE in liste bekommt)
# linessep =>
# datasep
#
# regex,
#  der Datenzeile matcht
#  der Kommentarzeile matcht

sub _load_gpplus_data {
	my $self=shift;
	my @files=@_;
	
	my $data;
	my $desc;#			bzw. parse results
	my $blocknum=0;
	my $linenum=0;
	my $numcol;
	my $ok=0;
	for (@files) {
		if (open IN,"<$_") {
			while (<IN>) {
				$_=~s/[\n\r]+$//;
				if (/([\d\-+\.Ee];)/) {
					my @value=split ";";
					for (0..$#value) {
#hier
						$data->[$blocknum]->[$linenum]->[$_]=$value[$_];
#was ist mit update_minmax?
						if (!(defined $desc->{column}->[$_]->{min}) || ($value[$_] < $desc->{column}->[$_]->{min})) {
							$desc->{column}->[$_]->{min}=$value[$_];
						}							
						if (!(defined $desc->{column}->[$_]->{max}) || ($value[$_] > $desc->{column}->[$_]->{max})) {
							$desc->{column}->[$_]->{max}=$value[$_];
						}							
					}
					if (($linenum==0) && ($blocknum==0)) {
						$numcol=$#value;
						for (0..$numcol) {
							$desc->{column}->[$_]->{label}='column '.($_+1);
						}
					} elsif ($numcol!=$#value) {
						die	"spaltenzahl scheisse in zeile $linenum von block $blocknum.\n".
							"sollte ".1+$numcol." sein. so habe ich keinen bock und sterbe jetzt"
							if ($#value != $numcol);
					}
					$linenum++;
				} elsif (/^Saved at ([\d:]{8}) on ([\d.]{8})/) {
					#Zeit und Datum werden von GPplus pro File/Block gespeichert
					my ($time,$date)=($1,$2);
					$desc->{block}->[$blocknum]->{comment}="Saved at $time on $date";
					$desc->{block}->[$blocknum]->{timestamp}="$date-$time";
				} elsif ($blocknum == 0) {
					#Kommentar
					$desc->{dataset_description}.=$_."\n" if ($_ !~ /DATA MEASURED/);
				} else {
					#ignorierter Kommentar: GPplus schreibt gleichen Kommentar in jedes File
				}
			}
			close IN;
			$blocknum++;
			if ($linenum > 0) { $ok=1 }
			$linenum=0;
		}
	}
	if ($ok) { return ($data,$desc) }
	else { return undef }
}

sub update_minmax {
	my $self=shift;
	my ($col,$val)=@_;
	if ((!(defined $self->{Description}->{column}->[$col]->{min}))
		|| ($val < $self->{Description}->{column}->[$col]->{min})) {
		$self->{Description}->{column}->[$col]->{min}=$val;
	}							
	if ((!(defined $self->{Description}->{column}->[$col]->{max}))
		|| ($val > $self->{Description}->{column}->[$col]->{max})) {
		$self->{Description}->{column}->[$col]->{max}=$val;
	}							
}

sub get_num_rows {
	my $self=shift;
	my $blocknum=shift;
	my $n=0;
	if ($blocknum eq 'all') {
		$n+=$#{$_}+1 for (@{$self->{Data}});
	} else {
		$n=1+$#{$self->{Data}->[$blocknum]};
	}
	$n;
}

sub get_num_cols {
	my $self=shift;
	#return scalar @{$self->column};
	return scalar @{$self->{Description}->{column}};
}	

sub get_num_blocks {
	my $self=shift;
	#herrliche konsistenz
	return $#{$self->{Data}}+1;
}

1;

__END__

=head1 NAME

Lab::Data::Importer - A dataset

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
