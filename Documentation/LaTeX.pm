package Documentation::LaTeX;

use strict;
use base 'Documentation::LabVISAdoc';
use File::Basename;
use Cwd;

sub start {
    my ($self, $title, $authors) = @_;
    
    open $self->{index_fh}, ">", "$$self{tempdir}/documentation.tex" or die;
    print {$self->{index_fh}} $self->_get_preamble($title, $authors);
}

sub start_section {
    my ($self, $level, $title) = @_;
    my $levelname = qw(chapter section subsection subsubsection paragraph subparagraph)[$level - 2];
    print {$self->{index_fh}} "\\$levelname\{$title}\n";
}

sub process_element {
    my ($self, $podfile, @sections) = @_;

    unless (-f $podfile) {
        warn "File $podfile doesn't exist";
    } else {
        my $basename = fileparse($podfile,qr{\.(pod|pm)});
        my $parser = MyPod2LaTeX->new();
        $parser->AddPreamble(0);
        $parser->AddPostamble(0);
        $parser->ReplaceNAMEwithSection(1);
        $parser->TableOfContents(0);
        $parser->StartWithNewPage(0);
        $parser->select('!(AUTHOR.*|SEE ALSO|CAVEATS.*)');
        $parser->Head1Level($#sections);
        $parser->LevelNoNum($#sections + 1 + ($basename =~ /Tutorial/));
        $parser->parse_from_file ($podfile, qq($$self{tempdir}/$basename.tex));
        print {$self->{index_fh}} "\\input{$basename}\n";
        print {$self->{index_fh}} "\\cleardoublepage\n";
    } 
}

sub finish {
    my $self = shift;
    print {$self->{index_fh}} $self->_get_postamble();
    close $self->{index_fh};
    
    my $basedir = getcwd();
    chdir $self->{tempdir};
    for (1..2) {
        system('pdflatex -interaction=batchmode documentation.tex');
    }
    chdir $basedir;
    
    rename("$$self{tempdir}/documentation.pdf","$$self{docdir}/documentation.pdf") or warn "umbenennen geht nicht: $!";
    if (chdir $self->{tempdir}) {
        unlink(<*>) or warn "files löschen geht nicht $!";
        chdir $basedir;
    }
    rmdir $self->{tempdir} or warn "tempdir löschen geht nicht: $!";
}

sub _get_preamble {
    my ($self, $title, $authors) = @_;
    return '\documentclass[twoside,BCOR4mm,openright,pointlessnumbers,headexclude,a4paper,11pt,final]{scrreprt}   %bzw. twoside,openright,pointednumbers
\pagestyle{headings}
\usepackage[latin1]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage{textcomp}
\usepackage{listings}
\usepackage{graphicx}
\usepackage[linktocpage,colorlinks=true,citecolor=blue,pagecolor=magenta,pdftitle={Lab::VISA documentation},pdfauthor={Daniel Schröer},pdfsubject=Manual]{hyperref}
\lstset{language=Perl,basicstyle=\footnotesize\ttfamily,breaklines=true,
        commentstyle=\rmfamily,
        keywordstyle=\color{red}\bfseries,stringstyle=\sffamily,
        identifierstyle=\color{blue}}

\begin{document}

\begin{titlepage}
\begin{flushleft}
\newcommand{\Rule}{\rule{\textwidth}{1pt}}
\sffamily
{\Large '.$authors.'}
\vspace{5mm}

\Rule
\vspace{4mm}
{\Huge '.$title.'}
\vspace{5mm}\Rule

\vfill
\begin{center}
\includegraphics[width=12cm]{../dokutitle.pdf}
\end{center}
\vfill
\today\ ($ $Revision: 595 $ $)

\end{flushleft}
\end{titlepage}
\cleardoublepage
\pdfbookmark[0]{\contentsname}{toc}
\tableofcontents
';
}

sub _get_postamble {
    return <<POSTAMBLE
\\end{document}
POSTAMBLE
}

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
    $self->_output('\leavevmode\begin{lstlisting}' . "\n$paragraph\n". '\end{lstlisting}'."\n");
  }
}

1;

