#!/usr/bin/perl

use strict;
use Documentation::LaTeX;
use Documentation::HTML;
use Getopt::Long;
use Pod::Usage;

my %options = (
    toc     => "dokutoc.yml",
    docdir  => "Homepage/docs",
    tempdir => "Homepage/temp",
    keeptemp=> "",
);
GetOptions( \%options, "docdir=s", "tempdir=s", "keeptemp", 'help|?' );

my @jobs;
for (@ARGV) {
    push @jobs, "LaTeX" if /pdf|all/i;
    push @jobs, "HTML"  if /html|web|all/i;
}

pod2usage(
    -verbose  => 99,
    -sections => "SYNOPSIS|DESCRIPTION|COMMANDS|OPTIONS"
  )
  if ( $options{help} || !@jobs );

for ( map "Documentation::$_", @jobs ) {
    my $processor = new { $_ }( $options{docdir}, $options{tempdir}, $options{keeptemp} );
    $processor->process( $options{toc} );
}

#copy('Homepage/index.html', 'Homepage/index.php');

=head1 NAME

makedoku.pl - Compile documentation for Lab::VISA

=head1 SYNOPSIS

makedoku.pl [options] command [command..]

=head1 DESCRIPTION

This program compiles HTML and PDF Documentation for Lab::VISA from various sources. The actual
contents are defined in the file specified with option --toc.

=head1 COMMANDS

Command names are case insensitive.

=over

=item html

Create documentation in HTML format.

=item pdf

Create documentation in PDF format.

=item all

Create documentation in html and pdf.

=back

=head1 OPTIONS

All option names can be abbreviated as long as they remain unique.

=over

=item --toc=FILE

The table of contents, defined in YAML. Defaults to C<dokutoc.yml>.

=item --docdir=DIRECTORY

Directory to create the documentation in. Defaults to C<Homepage/docs>.

=item --tempdir=DIRECTORY

Directory to create temporary trash in. Will be deleted after execution. Defaults to C<Homepage/temp>.

=back

=head1 AUTHOR/COPYRIGHT

Copyright 2010 Daniel Schröer (schroeer@cpan.org), 2011 Andreas K. Hüttel (mail@akhuettel.de)

=cut

