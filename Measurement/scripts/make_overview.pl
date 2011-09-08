#!/usr/bin/perl

use strict;
use warnings;
use Lab::Data::Plotter;
use Lab::Data::Meta;
use File::Basename;
use Encode;
use Cwd;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $datum = sprintf "%02d.%02d.%04d %02d:%02d",$mday,$mon+1,$year+1900,$hour,$min;
my $directory = cwd();

my $starttex=<<TEXINTRO;
\\documentclass[a4paper,10pt]{article}
\\usepackage[latin1]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{ae}
\\usepackage{graphicx}
\\usepackage{verbatim}
\\usepackage{lscape}

\\begin{document}

\\begin{titlepage}
\\begin{flushleft}
\\sffamily
{\\Huge Measurement data overview}
\\vspace{1cm}

{\\normalsize Working directory:\\\\}
{\\footnotesize \\verb!$directory!}
\\vspace{2mm}\\rule{\\textwidth}{1pt}\\vfill
Generated $datum using \\verb!Lab::Measurement!
\\end{flushleft}
\\end{titlepage}
\\tableofcontents
\\clearpage
TEXINTRO

open LIST,"<filelist.txt";
open LATEX,">overview.tex" or die;
print LATEX $starttex;

while (<LIST>) {
    chomp(my $a=$_);
    print "processing line \"$a\"\n";
    next if ($a =~ /^\s*#/);
    next if ($a =~ /^\s*$/);
    if ($a =~ /^\s*%%\s*(.*)/) {
        print LATEX "\\subsection{$1}\n";
        next;
    }        
    if ($a =~ /^\s*%\s*(.*)/) {
        print LATEX "\\clearpage\\section{$1}\n";
        next;
    }        
    my ($plotname,$file)=split /\t/,$a;
    my $newname=$file;
    $newname=~s/[^a-zA-Z0-9_\-]/_/g;
    $newname.="$plotname.eps";
    my $meta=Lab::Data::Meta->new_from_file($file);
    unless (-e ".autoplot-$newname") {
        my $plotter=new Lab::Data::Plotter($meta,{
            fulllabels  => 0,
            eps         => ".autoplot-$newname"
        });
        $plotter->plot($plotname);
    }
    my $description= $meta->dataset_description();
    $description= decode("UTF-8", $description) if ($^O =~ /Win/);
    
    $description=~s/_/\\_/g;
    $description=~s/\\\\\\_/\\_/g;
    
    my @ul;

    unshift(@ul,map {sprintf("\\item %s\n",$_)} split("\n",$description));
    
    $description="\\begin{itemize}".join(" ",@ul)."\\end{itemize}";
    
    my $tex=<<INCFIGURE;
\\begin{minipage}[t]{0.6\\textwidth}
\\includegraphics[width=0.7\\textwidth,angle=270]{.autoplot-$newname}
\\end{minipage}
\\begin{minipage}[t]{0.5\\textwidth}
\\footnotesize{$description}
\\end{minipage}

\\vspace*{3mm}
\\rule{\\textwidth}{1pt}
\\vspace*{3mm}

INCFIGURE
    print LATEX $tex;
}

print LATEX <<FOOTER;
\\appendix
\\clearpage
\\section{File list}
    {\\small\\verbatiminput{filelist.txt}}
\\end{document}
FOOTER

close LATEX;
close LIST;


1;

=pod

=encoding utf-8

=head1 NAME

make_overview.pl - Generate a LaTeX overview file with plots of all measurements in a directory 

=head1 SYNOPSIS

  huettel@pc55508 ~ $ make_overview.pl

Evaluates C<filelist.txt> in the current directory, reads the specified metafiles, generates 
the specified plots and a LaTeX file C<overview.tex>.

=head1 SYNTAX of filelist.txt

  % Chapter 1 title
  %% Section 1.1 title
  Plotname	MYMEASUREMENT.META
  Plotname	MYMEASUREMENT2.META
  % Chapter 2 title
  Plotname	ANOTHERMEASUREMENT.META

Pretty simple, huh? The only important thing is - the separator between the plot name and the 
file name has to be a TAB.

=head1 CAVEATS/BUGS

none known so far :)

=head1 SEE ALSO

=over 4

=item * L<Lab::Data::Meta>

=item * L<Lab::Data::Plotter>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2006-2007 Daniel Schröer
            2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

