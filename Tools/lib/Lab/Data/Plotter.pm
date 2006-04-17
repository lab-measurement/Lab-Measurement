#$Id$

package Lab::Data::Plotter;

use strict;
use Lab::Data::Meta;
use Data::Dumper;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $meta=shift;
    unless (ref $meta eq 'Lab::Data::Meta') {
        die "fuck you" unless (-e $meta);
        $meta=Lab::Data::Meta->new_from_file($meta);
    }
    
    my $self = bless {
        meta    => $meta
    }, $class;
    
    return $self;
}

sub start_live_plot {
    my ($self,$plot)=@_;
    $self->{live_plot}->{pipe}=$self->_start_plot($plot);
    $self->{live_plot}->{plot}=$plot;
}

sub update_live_plot {
    my $self=shift;
    return unless (defined $self->{live_plot});

    $self->_plot($self->{live_plot}->{pipe},$self->{live_plot}->{plot});
}        

sub stop_live_plot {
    my $self=shift;
    return unless (defined $self->{live_plot});

    close $self->{live_plot}->{pipe};
    undef $self->{live_plot};
}

sub plot {
    my ($self,$plot)=@_;
    
    die "Plot what?" unless ($self->{meta} && $plot);
    
    my $gpipe=$self->_start_plot($plot);
    $self->_plot($gpipe,$plot);
    
    return $gpipe;
}

sub _start_plot {
    my ($self,$plot)=@_;
    die "plot \"$plot\" undefined" unless (defined($self->{meta}->plot($plot)));

    my $gpipe=$self->get_gnuplot_pipe();
    
    my $xaxis=$self->{meta}->plot_xaxis($plot);
    my $yaxis=$self->{meta}->plot_yaxis($plot);
    
    my $gp="";
    
    for (@{$self->{meta}->constant()}) {
        $gp.=($_->{name})."=".($_->{value})."\n";
    }    
    
    $gp.="set encoding iso_8859_1\n";
    
    $gp.='set xlabel "'.($self->{meta}->axis_label($xaxis)).' ('.($self->{meta}->axis_unit($xaxis)).")\"\n";
    $gp.='set ylabel "'.($self->{meta}->axis_label($yaxis))." (".($self->{meta}->axis_unit($yaxis)).")\"\n";
    
    if (defined $self->{meta}->plot_grid($plot)) {
        $gp.="set grid ".($self->{meta}->plot_grid($plot))."\n";
    }
    my $xmin=(defined $self->{meta}->axis_min($xaxis)) ? $self->{meta}->axis_min($xaxis) : "*";
    my $xmax=(defined $self->{meta}->axis_max($xaxis)) ? $self->{meta}->axis_max($xaxis) : "*";
    my $ymin=(defined $self->{meta}->axis_min($yaxis)) ? $self->{meta}->axis_min($yaxis) : "*";
    my $ymax=(defined $self->{meta}->axis_max($yaxis)) ? $self->{meta}->axis_max($yaxis) : "*";
    $gp.="set xrange [$xmin:$xmax]\n";
    $gp.="set yrange [$ymin:$ymax]\n";

    if ($self->{meta}->plot_logscale($plot)) {
        $gp.="set logscale ".$self->{meta}->plot_logscale($plot)."\n";
    }
    
    $gp.=qq(set title "Dataset ').$self->{meta}->dataset_title()."' (Sample '".$self->{meta}->sample()."')\"\n";
    my $h=0.95;
    for (split "\n",$self->{meta}->dataset_description()) {
        $gp.=qq(set label "$_" at graph 0.02, graph $h\n);
        $h-=0.04;
    }

    print $gpipe $gp;
    return $gpipe;
}

sub _plot {
    my ($self,$gpipe,$plot)=@_;

    my $xaxis=$self->{meta}->plot_xaxis($plot);
    my $yaxis=$self->{meta}->plot_yaxis($plot);
    
    my $xexp=$self->_flatten_exp($xaxis);
    my $yexp=$self->_flatten_exp($yaxis);

    my $datafile=$self->{meta}->get_abs_path().$self->{meta}->data_file();
    
    print $gpipe qq(plot "$datafile" using ($xexp):($yexp) title "$plot" with lines\n);
}

sub _flatten_exp {
    my ($self,$axis)=@_;
    $_=$self->{meta}->axis_expression($axis);
    while (/\$A\d+/) {
        s/\$A(\d+)/($self->{meta}->axis_expression($1))/e;
    }
    while (/\$C\d+/) {
        s/\$C(\d+)/'$'.($1+1)/e;
    }
    $_;
}

sub available_plots {
    my $self=shift;
    
    my %plots=$self->{meta}->plot();
    my @names=(keys %plots);
    
    for (@names) {
        my $xlabel=$self->{meta}->axis_label($plots{$_}->{xaxis});
        my $ylabel=$self->{meta}->axis_label($plots{$_}->{yaxis});
        
        $plots{$_}="$ylabel vs. $xlabel";
    }
    return %plots;
}

sub get_gnuplot_pipe {
	my $self=shift;
    my $gpname;
	if ($^O =~ /MSWin32/) {
		$gpname="pgnuplot";
	} else {
		$gpname="gnuplot -noraise";
	}
	if (open my $GP,"| $gpname") {
		my $oldfh = select($GP);
		$| = 1;
		select($oldfh);
		return $GP;
	}
	return undef;
}

1;

__END__

=head1 NAME

Lab::Data::Plotter - Plot data with Gnuplot

=head1 SYNOPSIS

  use Lab::Data::Plotter;
  
  my $plotter=new Lab::Data::Plotter($metafile);
  
  my %plots=$plotter->available_plots();
  my @names=keys %plots;
  
  $plotter->plot($names[0]);

=head1 DESCRIPTION

This module can plot data with GnuPlot. It plots data from C<.DATA> files
and takes into account the data information in the corresponding C<.META> file.

The module also offers the possibility to plot data live, while it is
being aquired.

=head1 CONSTRUCTOR

=head2 new

  $plotter=new Lab::Data::Plotter($meta);

Creates a Plotter object. C<$meta> is either an object of type
L<Lab::Data::Meta|Lab::Data::Meta> or a filename that points to a C<.META> file.

=head1 METHODS

=head2 available_plots

  my %plots=$plotter->available_plots();

=head2 plot

  $plotter->plot($plot);

=head2 start_live_plot

  $plotter->start_live_plot($plot);

=head2 update_live_plot

  $plotter->update_live_plot();

=head2 stop_live_plot

  $plotter->stop_live_plot();

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
