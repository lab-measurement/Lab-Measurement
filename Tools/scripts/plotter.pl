#!/usr/bin/perl

use strict;
use Lab::Data::Plotter;
use Getopt::Long;
use Pod::Usage;

my %options=(#	=> default
	list_plots	=> 0,
	dump		=> '',
	eps			=> '',
);

GetOptions(\%options,
    'list_plots!',
	'dump=s',
	'eps=s',
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

my $plot=shift(@ARGV) or pod2usage(1);

my $gp=$plotter->plot($plot,%options);

my $a=<stdin>;

__END__

=head1 NAME

plotter.pl - Plot data with GnuPlot

=head1 SYNOPSIS

plotter.pl [OPTIONS] METAFILE [PLOT]

=head1 DESCRIPTION

This is a commandline tool to plot data that has been recorded using
the L<Lab::Measurement|Lab::Measurement> module.

=head1 OPTIONS AND ARGUMENTS

The file C<METAFILE> contains the meta information for the data that is
to be plotted. The name C<PLOT> of the plot that you want to draw must
be supplied, unless you use the C<--list_plots> option, that lists all
available plots defined in the C<METAFILE>.

=over 2

=item --help|-?

Print short usage information.

=item --man

Show manpage.

=item --list_plots

List available plots defined in C<METAFILE>.

=item --dump=filename

Do not plot now, but dump a gnuplot file C<filename> instead.

=item --eps=filename

Don't plot on screen, but create eps file C<filename>.

=back

=head1 SEE ALSO

=over 2

=item gnuplot(1)

=item L<Lab::Measurement>

=item L<Lab::Data::Plotter>

=item L<Lab::Data::Meta>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$.

Copyright 2004 Daniel Schröer.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
