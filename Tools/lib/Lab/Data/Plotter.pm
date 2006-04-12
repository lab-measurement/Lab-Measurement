#$Id$

package Lab::Data::Plotter;

use strict;
use Lab::Data::Meta;
use Data::Dumper;

our $VERSION = sprintf("0.%04d", q$Revision$ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    return $self;
}

sub start_live_plot {
    my ($self,$meta,$plot)=@_;
    my $gpipe=$self->_start_plot($meta,$plot);
    
    $self->{live_plot}->{pipe}=$gpipe;
    $self->{live_plot}->{meta}=$meta;
    $self->{live_plot}->{plot}=$plot;
}

sub _start_plot {
    my ($self,$meta,$plot)=@_;
    die "plot \"$plot\" undefined" unless (defined($meta->plot($plot)));
    my $gpipe=$self->get_gnuplot_pipe();
    
    my $xaxis=$meta->plot_xaxis($plot);
    my $yaxis=$meta->plot_yaxis($plot);
    
    my $gp;
    
    $gp.='set xlabel "'.($meta->axis_label($xaxis)).' ('.($meta->axis_unit($xaxis)).")\"\n";
    $gp.='set ylabel "'.($meta->axis_label($yaxis))." (".($meta->axis_unit($yaxis)).")\"\n";
    
    my $xmin=(defined $meta->axis_min($xaxis)) ? $meta->axis_min($xaxis) : "*";
    my $xmax=(defined $meta->axis_max($xaxis)) ? $meta->axis_max($xaxis) : "*";
    my $ymin=(defined $meta->axis_min($yaxis)) ? $meta->axis_min($yaxis) : "*";
    my $ymax=(defined $meta->axis_max($yaxis)) ? $meta->axis_max($yaxis) : "*";
    $gp.="set xrange [$xmin:$xmax]\n";
    $gp.="set yrange [$ymin:$ymax]\n";

    if ($meta->plot_logscale($plot)) {
        $gp.="set logscale ".$meta->plot_logscale($plot)."\n";
    }
    
    $gp.=qq(set title "Dataset ').$meta->dataset_title()."' (Sample '".$meta->sample()."')\"\n";
    my $h=0.95;
    for (split "\n",$meta->dataset_description()) {
        $gp.=qq(set label "$_" at graph 0.02, graph $h\n);
        $h-=0.04;
    }

    print $gpipe $gp;
    return $gpipe;
}

sub update_live_plot {
    my $self=shift;
    return unless (defined $self->{live_plot});

    my $meta=$self->{live_plot}->{meta};
    my $plot=$self->{live_plot}->{plot};
    my $pipe=$self->{live_plot}->{pipe};
    
    my $xaxis=$meta->plot_xaxis($plot);
    my $yaxis=$meta->plot_yaxis($plot);
    
    my $xexp=_flatten_exp($meta,$xaxis);
    my $yexp=_flatten_exp($meta,$yaxis);

    my $datafile=$meta->get_abs_path().$meta->data_file();
    
    print $pipe qq(plot "$datafile" using ($xexp):($yexp) title "$plot" with lines\n);
}        

sub _flatten_exp {
    my ($meta,$axis)=@_;
    $_=$meta->axis_expression($axis);
    while (/\$A\d+/) {
        s/\$A(\d+)/($meta->axis_expression($1))/e;
    }
    while (/\$C\d+/) {
        s/\$C(\d+)/'$'.($1+1)/e;
    }
    $_;
}

sub stop_live_plot {
    my $self=shift;
    return unless (defined $self->{live_plot});

    close $self->{live_plot}->{pipe};
    undef $self->{live_plot};
}

sub plot {
    my ($self,$meta,$plot)=@_;
    
    die "Plot what?" unless ($meta && $plot);
    
    unless (ref $meta eq 'Lab::Data::Meta') {
        die "fuck you" unless (-e $meta);
        $meta=Lab::Data::Meta->new_from_file($meta);
    }
    
    my $gpipe=$self->_start_plot($meta,$plot);

    my $xaxis=$meta->plot_xaxis($plot);
    my $yaxis=$meta->plot_yaxis($plot);
    
    my $xexp=_flatten_exp($meta,$xaxis);
    my $yexp=_flatten_exp($meta,$yaxis);

    my $datafile=$meta->get_abs_path().$meta->data_file();
    
    print $gpipe qq(plot "$datafile" using ($xexp):($yexp) title "$plot" with lines\n);
    
    return $gpipe;
}

sub available_plots {
    my ($self,$meta)=@_;
    
    unless (ref $meta eq 'Lab::Data::Meta') {
        die "fuck you" unless (-e $meta);
        $meta=Lab::Data::Meta->new_from_file($meta);
    }
    my %plots=$meta->plot();
    return keys %plots;
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

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
