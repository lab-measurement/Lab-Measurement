#!/usr/bin/perl

use strict;
use Pod::Latex;
use File::Basename;

my @files=qw!
    VISA/lib/Lab/VISA/Tutorial.pod
    VISA/VISA.pod
    Instrument/lib/Lab/Instrument.pm
    Instrument/lib/Lab/Instrument/HP34401A.pm
    Instrument/lib/Lab/Instrument/HP34970A.pm
    Instrument/lib/Lab/Instrument/IPS120_10.pm
    Instrument/lib/Lab/Instrument/Agilent81134A.pm
    Instrument/lib/Lab/Instrument/SR780.pm
    Instrument/lib/Lab/Instrument/Source.pm
    Instrument/lib/Lab/Instrument/Dummysource.pm
    Instrument/lib/Lab/Instrument/KnickS252.pm
    Instrument/lib/Lab/Instrument/Yokogawa7651.pm
    Tools/lib/Lab/Measurement.pm
    Tools/lib/Lab/Data/Meta.pm
    Tools/lib/Lab/Data/Plotter.pm
    Tools/lib/Lab/Data/Writer.pm
    Tools/lib/Lab/Data/PDL.pm
    Tools/lib/Lab/Data/XMLtree.pm
!;
#    Tools/lib/Lab/Data/Dataset.pm

unless (-d 'makedoku_temp') {
    mkdir 'makedoku_temp';
}

my $preamble='
\documentclass[twoside,BCOR4mm,openright,pointlessnumbers,headexclude,a4paper,11pt,final]{scrreprt}   %bzw. twoside,openright,pointednumbers
\pagestyle{headings}
\usepackage[latin1]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{ae}
\usepackage{textcomp}
\usepackage[ps2pdf,linktocpage,colorlinks=true,citecolor=blue,pagecolor=magenta,pdftitle={Lab::VISA documentation},pdfauthor={Daniel Schröer},pdfsubject=Manual]{hyperref}

\begin{document}

\begin{titlepage}
\begin{flushleft}
\newcommand{\Rule}{\rule{\textwidth}{1pt}}
\sffamily
{\Large Daniel Schröer}
\vspace{5mm}

\Rule
\vspace{4mm}
{\Huge Documentation for Lab::VISA}
\vspace{5mm}\Rule

\vfill

\end{flushleft}
\end{titlepage}
\cleardoublepage
\pdfbookmark[0]{\contentsname}{toc}
\tableofcontents
';

my $postamble='
\end{document}
';

open MAIN,'>makedoku_temp/documentation.tex' or die;
print MAIN $preamble;

for (@files) {
    my $parser = Pod::LaTeX->new();
    $parser->AddPreamble(0);
    $parser->AddPostamble(0);
    $parser->LevelNoNum(5);
    $parser->ReplaceNAMEwithSection(1);
    $parser->TableOfContents(0);
    $parser->StartWithNewPage(0);
    $parser->select('!(AUTHOR.*|SEE ALSO)');
    
    unless (-f $_) {
        warn "File $_ doesn't exist";
    } else {
        my $basename = fileparse($_,qr{\.(pod|pm)});
        $parser->Head1Level(0) if ($basename =~ /Tutorial/);
        $parser->parse_from_file ($_,qq(makedoku_temp/$basename.tex));
        print MAIN "\\chapter{The Lab::VISA package}\n" if ($basename =~ /VISA/);
        print MAIN "\\chapter{The Lab::Instruments package}\n" if ($basename =~ /Instrument/);
        print MAIN "\\chapter{The Lab::Tools package}\n" if ($basename =~ /Measurement/);
        print MAIN "\\input{$basename}\n";
    } 
}
print MAIN $postamble;
close MAIN;

chdir 'makedoku_temp';
for (1..3) {
    system('latex documentation.tex');
}
system('dvips -P pdf -t A4 documentation');
system('ps2pdf documentation.ps');
chdir '..';

rename 'makedoku_temp/documentation.pdf','documentation.pdf';
unlink <makedoku_temp\\*.*>;# or die "geht nicht $!";
rmdir 'makedoku_temp';
