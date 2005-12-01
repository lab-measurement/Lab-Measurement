#!/usr/bin/perl -w

#$Id$

package Lab::Dataset;

use 5.008;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Basename;
use Lab::XMLtree;
require Exporter;

our @ISA = qw(Exporter);

our $VERSION = sprintf("1.%04d", q$Revision$ =~ / (\d+) /);

our $AUTOLOAD;

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

my $description_def = {
	filename_base			=> ['PSCALAR'],#	PSCALAR! Dient als basename für DATA und META
	filename_path			=> ['PSCALAR'],#	PSCALAR! Dient als speicherpfad für DATA und META

	dataset_title			=> ['SCALAR'],
	dataset_description		=> ['SCALAR'],
	data_file				=> ['SCALAR'],#		relativ zur descriptiondatei

	block					=> [
		'ARRAY',
		'id',
		{
			original_filename	=> ['SCALAR'],
			timestamp			=> ['SCALAR'],
			comment				=> ['SCALAR']
		}
	],
	column					=> [
		'ARRAY',
		'id',
		{
			unit		=> ['SCALAR'],
			label		=> ['SCALAR'],
			description	=> ['SCALAR'],
			min			=> ['PSCALAR'],
			max			=> ['PSCALAR']
		}
	],
	axis					=> [
		'HASH',
		'label',
		{
#			column		=> ['SCALAR'],	# entfernt, da schwachsinnig. soll per expression auch mehrere spalten abdecken können
			unit		=> ['SCALAR'],
			logscale	=> ['SCALAR'],
			expression	=> ['SCALAR'],
			min			=> ['SCALAR'],
			max			=> ['SCALAR'],
			description	=> ['SCALAR']
		}
	],
};

my $default_config = {
	keep_data_in_memory	=> 1,
	log_data			=> 0,	# bei new_row sofort ausgeben in immer geöffnetes Filehandle
		
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

sub open_dataset {
	my $self=shift;
	my $filename=shift;
	
	my ($basename,$path,$suffix)=fileparse($filename,qr{\..*});
	if (my ($data,$desc)=$self->_load_raw_data("$path$basename.raw")) {
		$self->{Data}=$data;
		$self->{Description}->merge_tree($desc);
		
		if (my $loaded_desc=Lab::XMLtree->read_xml($description_def,"$path$basename.description")) {
			# diese description in die vorhandene einmergen
			$self->{Description}->merge_tree($loaded_desc);
		}
		$self->filename_base($basename);
		unless ($self->dataset_title()) {
			$self->dataset_title($basename);
		}
		return 1;
	}
	return 0;
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

sub to_string {
	return shift->{Description}->to_string();
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

#lädt ein Datenfile in meinem (".RAW"-) Format
#Argument fully qualified $filename
sub _load_raw_data {
	my $self=shift;
	my $filename=shift;
	my $data;
	my $desc;#			bzw. parse results
	my $numcol;
	my $ok=0;
	if (open IN,"<$filename") {
		my $blocknum=0;
		my $linenum=0;
		while (<IN>) {
			chomp;
			unless ($_) {
				$blocknum++;
				$linenum=0;
			} elsif (/^([\d\-+\.Ee]+\t?)+$/) {
				my @value=split "\t";
				for (0..$#value) {		
					$data->[$blocknum]->[$linenum]->[$_]=$value[$_];
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
						"sollte ".1+$numcol." sein. so habe ich keinen bock und sterbe jetzt\n"
						if ($#value != $numcol);
				}
				$linenum++;
			} else {
				# kommentarzeile
#				$desc->{dataset_description}.=$_."\n";
				# so wird ein vorhandener kommentar natürlich jedesmal wieder in der description angehängt
			}
		}
		close IN;
		if (($linenum >0) || ($blocknum >0)) {$ok=1}
	}
	if ($ok) { return ($data,$desc) }
	else { return undef }
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
						$data->[$blocknum]->[$linenum]->[$_]=$value[$_];
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

sub getset_data {
	my $self=shift;
	my ($block_num, $row, $col, $val) = @_;
	if (defined $val) {
		$self->{Data}->[$block_num]->[$row]->[$col]=$val;
		$self->update_minmax($col,$val);
	} else {
		if (defined $self->{Data}->[$block_num]->[$row]->[$col]) {
			return $self->{Data}->[$block_num]->[$row]->[$col];
		}
		warn "Somebody asks for nonexisting data: block $block_num, row $row, col $col";
		return "";
	}
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

sub new_block {
	my $self=shift;
}

sub new_row {
	my $self=shift;
	my @values=@_;
	
	if ($#values != $self->get_num_cols) {
		warn "Wrong number of data values";
	}
	for my $col (0..$#values) {
		my $block=$self->get_num_blocks()-1;
		$self->getset_data(
			$block,
			$self->get_num_rows_in_block($block),
			$col,
			$values[$col]
		);
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

sub AUTOLOAD {
    my $self = shift;
    my @parms=@_;
    my $type = ref($self) or croak "$self is not an object";
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

	return $self->{Description}->$name(@parms);
}

sub DESTROY {
}

1;

__END__

=head1 NAME

Lab::Dataset - A dataset

=head1 SYNOPSIS

=head1 DESCRIPTION

    my $description_def = {
        filename_base           => ['PSCALAR'],#    PSCALAR! Dient als basename für DATA und META
        filename_path           => ['PSCALAR'],#    PSCALAR! Dient als speicherpfad für DATA und META
    
        dataset_title           => ['SCALAR'],
        dataset_description     => ['SCALAR'],
        data_file               => ['SCALAR'],#     relativ zur descriptiondatei
    
        block                   => [
            'ARRAY',
            'id',
            {
                original_filename   => ['SCALAR'],
                timestamp           => ['SCALAR'],
                comment             => ['SCALAR']
            }
        ],
        column                  => [
            'ARRAY',
            'id',
            {
                unit        => ['SCALAR'],
                label       => ['SCALAR'],
                description => ['SCALAR'],
                min         => ['PSCALAR'],
                max         => ['PSCALAR']
            }
        ],
        axis                    => [
            'HASH',
            'label',
            {
                column      => ['SCALAR'],
                unit        => ['SCALAR'],
                logscale    => ['SCALAR'],
                expression  => ['SCALAR'],
                min         => ['SCALAR'],
                max         => ['SCALAR'],
                description => ['SCALAR']
            }
        ],
    };

=head1 CONSTRUCTOR

=head2 new([$config][,$basepathname])

=head1 METHODS

=head2 configure($config)

    my $default_config={
        keep_data_in_memory => 1,
        log_data            => 0,       # bei new_row sofort ausgeben in immer geöffnetes Filehandle
            
        output_data_ext     => "DATA",
        output_meta_ext     => "META",
        output_col_sep      => "\t",
        output_line_sep     => "\n",
        output_block_sep    => "\n",
        output_comment_char => "#",
    };

=head2 open_dataset($filename)

=head2 import_gpplus(@files)

=head2 to_string()

=head2 save_description($filename)

=head2 getset_data($block_num, $row, $col, $val)

=head2 get_num_rows($blocknum)

=head2 get_num_cols()

=head2 get_num_blocks()

=head2 Description Methods done via AUTOLOAD

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
