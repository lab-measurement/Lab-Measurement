#!/usr/bin/perl

use strict;
use File::Basename;
use File::Spec;

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
    Instrument/lib/Lab/Instrument/KnickS252.pm
    Instrument/lib/Lab/Instrument/Yokogawa7651.pm
    Instrument/lib/Lab/Instrument/Dummysource.pm
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
\usepackage{listings}
\usepackage[ps2pdf,linktocpage,colorlinks=true,citecolor=blue,pagecolor=magenta,pdftitle={Lab::VISA documentation},pdfauthor={Daniel Schröer},pdfsubject=Manual]{hyperref}
\lstset{language=Perl,basicstyle=\footnotesize\ttfamily,breaklines=true,
        commentstyle=\rmfamily,
        keywordstyle=\color{red}\bfseries,stringstyle=\sffamily,
        identifierstyle=\color{blue}}

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
    my $parser = MyPod2LaTeX->new();
    $parser->AddPreamble(0);
    $parser->AddPostamble(0);
    $parser->LevelNoNum(2);
    $parser->ReplaceNAMEwithSection(1);
    $parser->TableOfContents(0);
    $parser->StartWithNewPage(0);
    $parser->select('!(AUTHOR.*|SEE ALSO|CAVEATS.*)');
    
    unless (-f $_) {
        warn "File $_ doesn't exist";
    } else {
        my $basename = fileparse($_,qr{\.(pod|pm)});
        $parser->Head1Level(0) if ($basename =~ /Tutorial/);
        $parser->parse_from_file ($_,qq(makedoku_temp/$basename.tex));
        for ($basename) {
            if      (/VISA/) { print MAIN "\\chapter{The Lab::VISA package}\n"}
            elsif   (/Instrument/) { print MAIN "\\chapter{The Lab::Instruments package}\n"}
            elsif   (/Measurement/) { print MAIN "\\chapter{The Lab::Tools package}\n"}
            else {print MAIN "\\cleardoublepage\n"}
        }
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

rename('makedoku_temp/documentation.pdf','documentation.pdf') or warn "umbenennen geht nicht: $!";
if (chdir "makedoku_temp") {
    unlink(<*>) or warn "files löschen geht nicht $!";
    chdir "..";
}
rmdir 'makedoku_temp' or warn "tempdir löschen geht nicht: $!";

package MyPod2LaTeX;
use strict;
use base qw/ Pod::LaTeX /;

sub verbatim {
  my $self = shift;
  my ($paragraph, $line_num, $parobj) = @_;
  if ($self->{_dont_modify_any_para}) {
    $self->_output($paragraph);
  } else {
    return if $paragraph =~ /^\s+$/;
    $paragraph =~ s/\s+$//;
    my @l = split("\n",$paragraph);
    foreach (@l) {
      1 while s/(^|\n)([^\t\n]*)(\t+)/
	$1. $2 . (" " x 
		  (8 * length($3)
		   - (length($2) % 8)))
	  /sex;
    }
    $paragraph = join("\n",@l);
    $self->_output('\begin{lstlisting}' . "\n$paragraph\n". '\end{lstlisting}'."\n");
  }
}


