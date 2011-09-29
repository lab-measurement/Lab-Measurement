#$Id$

package Lab::Measurement;

use strict;
use warnings;
#use encoding::warnings;
use Data::Dumper;
use Lab::Data::Writer;
use Lab::Data::Meta;
use Lab::Data::Plotter;

our $VERSION="1.41";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless ($self, $class);

    my %params=@_;
        #sample         => '',
        #title          => '',  # single line
        #filename       => '',
        #filename_base  => '',  # for auto_naming
        #description    => '',  # multi line
        #
        #columns        => [],
        #axes           => [],
        #plots          => {},
        #constants      => [],
        
        #live_plot      => '',
        #live_refresh   => '',
        #live_latest    => '',
        
        #writer_config  => {},

    # Filenamen finden
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
        
    # Meta erzeugen
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
    $meta->constant($params{constants});
    my ($filename,$path,$suffix)=($writer->get_filename(),$writer->configure('output_meta_ext'));
    $meta->save("$path$filename.$suffix");
    
    # Liveplot starten
    if ($params{live_plot}) {
        my %options;
        if ($params{live_latest}) {
            $options{live_latest}=$params{live_latest};
        }
        $self->{live_plotter}=new Lab::Data::Plotter($meta,\%options);
        $self->{live_plotter}->start_live_plot($params{live_plot},$params{live_refresh});
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
    my ($self,$label)=@_;
    my $num=$self->{writer}->log_start_block();
    my $now=now_string();
    $self->{meta}->block_timestamp($num,$now);
    $self->{meta}->block_label($num,$label) if ($label);
    print "Started block $num at $now";
    print " ($label)" if ($label);
    print "\n";
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
        #   warn "Du Bauer hast irgendwas verbockt: $column $datum\n";
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

Lab::Measurement - Log, describe and plot data on the fly

=head1 SYNOPSIS

  use Lab::Measurement;
  
  my $measurement=new Lab::Measurement(
      sample            => $sample,
      title             => $title,
      filename_base     => 'qpc_pinch_off',
      description       => $comment,

      live_plot         => 'QPC current',

      columns           => [
          {
              'unit'            => 'V',
              'label'           => 'Gate voltage',
              'description'     => 'Applied to gates via low path filter.',
          },
          {
              'unit'            => 'V',
              'label'           => 'Amplifier output',
              'description'     => "Voltage output by current amplifier set to $amp.",
          }
      ],
      axes              => [
          {
              'unit'            => 'V',
              'expression'      => '$C0',
              'label'           => 'Gate voltage',
              'min'             => ($start_voltage < $end_voltage) ? $start_voltage : $end_voltage,
              'max'             => ($start_voltage < $end_voltage) ? $end_voltage : $start_voltage,
              'description'     => 'Applied to gates via low path filter.',
          },
          {
              'unit'            => 'A',
              'expression'      => "abs(\$C1)*$amp",
              'label'           => 'QPC current',
              'description'     => 'Current through QPC',
          },
          {
              'unit'            => '2e^2/h',
              'expression'      => "(\$A1/$v_sd)/$g0)",
              'label'           => "Total conductance",
          },
          {
              'unit'            => '2e^2/h',
              'expression'      => "(1/(1/abs(\$C1)-1/$U_Kontakt)) * ($amp/($v_sd*$g0))",
              'label'           => "QPC conductance",
              'min'             => -0.1,
              'max'             => 5
          },

      ],
      plots             => {
          'QPC current'    => {
              'type'          => 'line',
              'xaxis'         => 0,
              'yaxis'         => 1,
              'grid'          => 'xtics ytics',
          },
          'QPC conductance'=> {
              'type'          => 'line',
              'xaxis'         => 0,
              'yaxis'         => 3,
              'grid'          => 'ytics',
          }
      },
  );

  $measurement->start_block();

  my $stepsign=$step/abs($step);
  for (my $volt=$start_voltage;$stepsign*$volt<=$stepsign*$end_voltage;$volt+=$step) {
      $knick->set_voltage($volt);
      usleep(500000);
      my $meas=$hp->read_voltage_dc(10,0.0001);
      $measurement->log_line($volt,$meas);
  }

  my $meta=$measurement->finish_measurement();

=head1 DESCRIPTION

This module simplifies the task of running a measurement, writing the data
to disk and keeping track of necessary meta information that usually later
you don't find in your lab book anymore.

If your measurements don't come out nice, it's not because you were using the wrong software.

=head1 CONSTRUCTORS

=head2 new

  $measurement=new Lab::Measurement(%config);

where C<%config> can contain

  sample        => '',  # see Meta
  title         => '',  # single line
  filename      => '',
  filename_base => '',  # for auto_naming
  description   => '',  # multi line
  
  columns       => [],
  axes          => [],
  plots         => [],  # See Meta
  
  live_plot     => '',  # Name of plot that is to be plotted live
  live_refresh  => '',
  live_latest   => '',
  
  writer_config => {},  # Configuration options for Lab::Data::Writer

=head1 METHODS

=head2 start_block

  $block_num=$measurement->start_block($label);

=head2 log_line

  $measurement->log_line(@data);

=head2 finish_measurement

  $meta=$measurement->finish_measurement();

=head2 now_string

  $now=$measurement->now_string();

=head2 log($datum,$column,$description)

magic log. deprecated.

=head1 SEE ALSO

=over 4

=item L<Lab::Data::Meta>

=item L<Lab::Data::Writer>

=item L<Lab::Data::Plotter>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004-2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
