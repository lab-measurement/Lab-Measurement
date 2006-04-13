#!/usr/bin/perl

use strict;
use Lab::Data::Plotter;
use Getopt::Long;
use Pod::Usage;

my %options=(#	=> default
	list_plots	=> 0,
	eps_file	=> '',
);

GetOptions(\%options,
    'list_plots!',
    'eps_file=s',
	'help|?',
    'man',
);
pod2usage(1) if $options{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $options{man};

my $metafile=shift(@ARGV) or pod2usage(1);

my $plotter=new Lab::Data::Plotter($metafile);

if ($options{list_plots}) {
    print "Available plots in $metafile:\n";
    my %plots=$plotter->available_plots();
    for (keys %plots) {
        print qq/-> $_ ($plots{$_})\n/;
    }
    exit;
}

my $gp=$plotter->plot(@ARGV);

my $a=<stdin>;

__END__

=head1 NAME

plotter.pl - Plot data with GnuPlot

=head1 SYNOPSIS

plotter.pl [OPTIONS] METAFILE [PLOT]

=head1 DESCRIPTION

Kabla.

=head1 OPTIONS AND ARGUMENTS

viele blöde argumente

zu viele optionen

=head1 SEE ALSO

Uses gnuplot(1). See the code.

=head1 AUTHOR/COPYRIGHT

This is $Id$.

Copyright 2004 Daniel Schröer.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
