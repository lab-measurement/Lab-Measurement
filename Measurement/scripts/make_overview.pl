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
\\documentclass[a4paper,10pt,final]{scrreprt}
\\usepackage[latin1]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{ae}
\\usepackage{graphicx}
\\usepackage{verbatim}
\\usepackage{lscape}
\\newcommand{\\gate}[1]{\\ensuremath{\\textrm{\\##1}}}

\\begin{document}

\\begin{titlepage}
\\begin{flushleft}
\\sffamily
{\\Large Measurement data overview}
\\vspace{5mm}

{\\huge \verb!$directory!}
\\vspace{2mm}\\rule{\\textwidth}{1pt}\\vfill
Generated $datum
\\end{flushleft}
\\end{titlepage}
\\tableofcontents
TEXINTRO

open LIST,"<filelist.txt";
open LATEX,">overview.tex" or die;
print LATEX $starttex;

my $parity=0;
while (<LIST>) {
    chomp(my $a=$_);
    next if ($a =~ /^\s*#/);
    next if ($a =~ /^\s*$/);
    if ($a =~ /^\s*%%\s*(.*)/) {
        print LATEX "\\section{$1}\n";
        next;
    }        
    if ($a =~ /^\s*%\s*(.*)/) {
        print LATEX "\\chapter{$1}\n";
        $parity=1;
        next;
    }        
    my ($plotname,$file)=split /\t/,$a;
    my $newname=$file;
    $newname=~s/[^a-zA-Z0-9_\-]/_/g;
    $newname.="$plotname.eps";
    my $meta=Lab::Data::Meta->new_from_file($file);
    unless (-e "bilder/$newname") {
        my $plotter=new Lab::Data::Plotter($meta,{
            fulllabels  => 0,
            eps         => "bilder/$newname"
        });
        $plotter->plot($plotname);
    }
    my $description= $meta->dataset_description();
    $description= decode("UTF-8", $description) if ($^O =~ /Win/);
    
    $description=~s/_/\\_/g;
    $description=~s/\\\\\\_/\\_/g;
    
    my (@ul,@rl);

    my @gates;
    while ($description =~ s/\s*(G[\da-z]+)=([\-\.\d]+)\s+\(([^\)]+)\);?\s*//) {
        push(@gates,[$1,$2,$3]);
    }
    push(@rl,map {sprintf("\\item \$\\gate{%s} = %s\\,\\mathrm V\$ (%s)\n",@$_)} @gates);

    if ($description =~s/\s*V\\_{SD,DC}\s*=\s*([\-\.\d]+)\s*V?\s*;?//i) {
        push(@rl,"\\item \$V_\\mathrm{SD,DC}=$1\\,\\mathrm V\$\n");
    }

    if ($description =~s/\s*Ca\.?\s+([\d]+)\s*mK//i) {
        push(@rl,"\\item \$$1\\,\\mathrm{mK}\$\n");
    }

    if ($description =~s/\n([^;]+); started at ([^\n]*)//i) {
        unshift(@rl,"\\item $1\n\\item $2\n");
    }

    if ($description =~s/Lock-In:\s*(.*)\n//i) {
        push(@ul,"\\item Lock-In settings: $1\n");
    }
    
    if ($description =~s/Ithaco:\s*(.*)\n//i) {
        push(@ul,"\\item Current amplifier settings: $1\n");
    }

    unshift(@ul,map {sprintf("\\item %s\n",$_)} split("\n",$description));
    
    my $gate_description="\\begin{itemize}".join(" ",@rl)."\\end{itemize}";
    
    $description="\\begin{itemize}".join(" ",@ul)."\\end{itemize}";
    
    my $tex=<<INCFIGURE;
\\begin{minipage}[t]{0.6\\textwidth}
\\includegraphics[width=0.7\\textwidth,angle=270]{bilder/$newname}
\\end{minipage}
\\begin{minipage}[t]{0.5\\textwidth}
\\footnotesize{$gate_description}
\\end{minipage}

\\footnotesize{$description}

\\rule{\\textwidth}{1pt}

INCFIGURE
    if ($parity) {
        $tex.="\\clearpage\n\n";
    }
    $parity=($parity+1) & 1;
    print LATEX $tex;
}

print LATEX <<FOOTER;
\\appendix
\\chapter{Filelist}
\\begin{landscape}
    {\\small\\verbatiminput{filelist.txt}}
\\end{landscape}
\\end{document}
FOOTER

close LATEX;
close LIST;


1;

=pod

=encoding utf-8

=head1 NAME

make_overview.pl - Generate a LaTeX overview file with plots of all measurements in a directory 

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

