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

=head1 NAME

blunaweb - create web page from bluna log data

=head1 SYNOPSIS

blunaweb [OPTIONS] [LOGFILE]

=head1 DESCRIPTION

This program is intended to be started by cron or a web request. Won't plot anything if LOGFILE is not given, but do the indexing and deleting.

The desired time span from the log file data can be specified with --time_span, --start_time and --end_time.
A maximum of two of the three may be specified.

=over 

=item * If start_time and end_time are given, only data from that period is shown.

=item * If time_span=HOURS and either start_time or end_time is given, the HOURS hours after
or before start_time and end_time are shown respectively.

=item * If only end_time is given, start_time will default to the start of the log file.

=item * If only start_time or time_span are given, end_time will default to now.

=item * If nothing is specified, all data is plotted.

=back

All option names can be abbreviated as long as they remain unique, eg. -last 24 -keep.

=over

=item --time_span=HOURS|--last=HOURS

Plot HOURS hours. Real numbers work, eg. --last=2.5

=item --start_time=TIME

Only plot data younger than TIME. TIME must be in format yyyy-mm-dd_hh:mm:ss. 

=item --end_time=TIME

Only plot data older than TIME. TIME must be in format yyyy-mm-dd_hh:mm:ss. 

=item --temp,--notemp

Create temporary file that can be deleted later with option --delete_temp (default). Otherwise create permanent file.

=item --delete_temp=HOURS

Delete all temporaray files where end date is older than HOURS hours. --delete 0 deletes all. Only integers here.

=item --make_index, --index, --noindex

Recreate the index page (default).

=item --keep_data, --nokeep_data

Keep the data file that was generated for this plot, otherwise delete it (default).

=item --htmldir=DIRECTORY

Directory to store the html files in. Default is html/.

=item --imagedir=DIRECTORY

Directory to store the image files in (relative to htmldir). Default is images/.

=item --datadir=DIRECTORY

Directory to store the data files in. Default is data/.

=item --webblunaweb=URL

Add link to webblunaweb. Default is no link.

=item --verbose[=level]

More bla.

=item --help

Show usage information and quit.

=item --man

Show this manpage and quit.

=head1 SEE ALSO

Uses gnuplot(1). See the code.

=head1 AUTHOR/COPYRIGHT

This is $Id$.

Copyright 2004 Daniel Schröer.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
