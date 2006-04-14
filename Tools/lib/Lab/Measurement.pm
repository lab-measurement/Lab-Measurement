#$Id$

package Lab::Measurement;

use strict;
use warnings;
use Data::Dumper;
use Lab::Data::Writer;
use Lab::Data::Meta;
use Lab::Data::Plotter;
#use Time::HiRes qw/usleep gettimeofday/;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;

	my $self = {};
    bless ($self, $class);

	my %params=@_;
		#sample			=> '',
		#title			=> '',  # single line
		#filename		=> '',
		#filename_base	=> '',	# for auto_naming
		#description	=> '',  # multi line
		#
		#columns		=> [],
		#axes			=> [],
	    #plots       	=> [],
		
		#live_plot  	=> '',
		
		#writer_config	=> {},

	# filenamen finden
	if ($params{filename_base}) {
        my $fnb=$params{filename_base};
        my $last=(sort {$b <=> $a} grep {s/$fnb\_(\d+)\..*/$1/} glob "$fnb\_*")[0];
        $last=0 unless $last;
        $params{filename}=$fnb."_".(sprintf "%03u",$last+1);
    }

    my $desc_add=$params{filename}."; started at ".now_string()."\n";
    $desc_add =~ s/_/\\\\_/g;
    $params{description}.=$desc_add;

	# Writer erzeugen, Log öffnen
	my $writer=new Lab::Data::Writer($params{filename},$params{writer_config});
	# header schreiben
	$writer->log_comment("Sample $params{sample}");
	$writer->log_comment($params{title});
	$writer->log_comment($params{description});
    $writer->log_comment('Recorded with $Id$');
		
	# meta erzeugen
    my $meta=new Lab::Data::Meta({
        data_complete           => 0,
        sample                  => $params{sample},
        dataset_title           => $params{title},
        dataset_description     => $params{description},
        data_file               => ($writer->get_filename)[0].".".$writer->configure('output_data_ext'),
    });
	$meta->column($params{columns});
	$meta->axis($params{axes});
	$meta->plot($params{plots});
	my ($filename,$path,$suffix)=($writer->get_filename(),$writer->configure('output_meta_ext'));
    $meta->save("$path$filename.$suffix");
	
	if ($params{live_plot}) {
        $self->{live_plotter}=new Lab::Data::Plotter($meta);
        $self->{live_plotter}->start_live_plot($params{live_plot});
    }
    
	$self->{writer}=$writer;
	$self->{meta}=$meta;
	
	return $self;
}

sub DESTROY {
	my $self=shift;
	if ($self->{writer}) {
		$self->finish_measurement();
	}
}

sub log_line {
	my $self=shift;
	$self->{writer}->log_line(@_);
	
	if ($self->{live_plotter}) {
		$self->{live_plotter}->update_live_plot();
	}
}

sub start_block {
	my $self=shift;
	my $num=$self->{writer}->log_start_block();
    $self->{meta}->block_timestamp($num,now_string());
}

sub finish_measurement {
	my $self=shift;
	$self->{meta}->data_complete(1);
	my ($filename,$path,$suffix)=($self->{writer}->get_filename(),$self->{writer}->configure('output_meta_ext'));
    $self->{meta}->save("$path$filename.$suffix");
	if ($self->{live_plotter}) {
		$self->{live_plotter}->stop_live_plot();
		delete $self->{live_plotter};
	}
	delete $self->{writer};
    return delete $self->{meta};
}

sub now_string {
	my ($sec,$min,$hour,$mday,$mon,$year)=localtime(time);
	return sprintf "%4d/%02d/%02d-%02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec;
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
			my $last_col=$#{$self->{magic_log}->{column}};
			$self->log_line(map{
				$self->{magic_log}->{column}->[$_]->{status}='set';
				$self->{magic_log}->{column}->[$_]->{datum}
			} (0..$last_col));
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

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
