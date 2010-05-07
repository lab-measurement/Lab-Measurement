package Documentation::HTML;

use strict;
use base 'Documentation::LabVISAdoc';
use File::Basename;
use Syntax::Highlight::Engine::Simple::Perl;

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{list_open} = 0;
    $self->{highlighter} = Syntax::Highlight::Engine::Simple::Perl->new();
    return $self;
}

sub start {
    my ($self, $title, $authors) = @_;
    open $self->{index_fh}, ">", "$$self{docdir}/toc.html" or die $!;
    
    print {$self->{index_fh}} $self->_get_header($title);
 	print {$self->{index_fh}} qq{
 	    <h1><a href="../index.html">Lab::VISA</a> Documentation</h1>
 	    <p>$authors</p>
 	};
}

sub start_section {
    my ($self, $level, $title) = @_;
    if ($self->{list_open}) {
        print {$self->{index_fh}} "</ul>\n";
        $self->{list_open} = 0;
    }
    print {$self->{index_fh}} "<h$level>$title</h$level>\n";
}

sub process_element {
    my ($self, $podfile, $params, @sections) = @_;
    my $basename = fileparse($podfile,qr{\.(pod|pm)});
    my $hascode = ($podfile =~ /\.(pl|pm)$/);
    
    # pod page
    my $parser = MyPodXHTML->new();
    my $title = "$sections[0]: $basename";
    my $html;
    $parser->output_string(\$html);
    $parser->parse_file($podfile);
    open OUTFILE, ">", "$$self{docdir}/$basename.html" or die;
        print OUTFILE $self->_get_header($title);
        print OUTFILE qq(<h1><a href="toc.html">$sections[0]</a>: <span class="basename">$basename</span></h1>\n);
        print OUTFILE $hascode ? qq{<p>(<a href="$basename\_source.html">Source code</a>)</p>} : "";
        print OUTFILE $html;
        print OUTFILE $self->_get_footer();
    close OUTFILE;
    
    # highlighted source file
    if ($hascode) {
        my $source = $self->{highlighter}->doFile(
            file      => $podfile,
            tab_width => 4,
            encode    => 'iso-8859-1'
        );
        my $title = "$sections[0]: $basename";
        open SRCFILE, ">", "$$self{docdir}/$basename\_source.html" or die;
            print SRCFILE $self->_get_header($title);
            print SRCFILE qq(<h1><a href="toc.html">$sections[0]</a>: <span class="basename">$basename</span></h1>\n);
            print SRCFILE qq{<p>(<a href="$basename.html">Documentation</a>)</p>};
            print SRCFILE "<pre>$source</pre>\n";
            print SRCFILE $self->_get_footer();
        close SRCFILE;
    }
    
    # link in toc page
    unless ($self->{list_open}) {
        print {$self->{index_fh}} "<ul>\n";
        $self->{list_open} = 1;
    }
    print {$self->{index_fh}} qq(<li><a class="index" href="$basename.html">$basename</a></li>\n);
}

sub finish {
    my $self = shift;
    if ($self->{list_open}) {
        print {$self->{index_fh}} "</ul>\n";
        $self->{list_open} = 0;
    }
 	print {$self->{index_fh}} q{<p><a href="documentation.pdf">This documentation as PDF</a></p>};
    print {$self->{index_fh}} $self->_get_footer();
    close $self->{index_fh};
}

sub _get_header {
    my ($self, $title) = @_;
    return <<HEADER;
<?xml version="1.0" encoding="iso-8859-1" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
	<head>
   		<link rel="stylesheet" type="text/css" href="../doku.css"/>
   		<title>$title</title>
 	</head>
 	<body>
<!--    <div id="header"><img id="logo" src="../header.png" alt=""/></div> -->
HEADER
}

sub _get_footer {
    return <<FOOTER;
 	</body>
</html>
FOOTER
}


package MyPodXHTML;
use strict;
use base 'Pod::Simple::XHTML';
use HTML::Entities;

sub new {
    my $self = shift->SUPER::new();
    $self->html_header('');
    $self->html_footer('');
    $self->html_h_level(2);
    return $self;
}

sub resolve_pod_page_link {
    my ($self, $to, $section) = @_;
    return undef unless defined $to || defined $section;
    if ($to =~ /^Lab/) {
        return (split '::', $to)[-1].".html";
    }
    if (defined $section) {
        $section = '#' . $self->idify($section, 1);
        return $section unless defined $to;
    }
    else {
        $section = ''
    }

    return ($self->perldoc_url_prefix || '')
        . encode_entities($to) . $section
        . ($self->perldoc_url_postfix || '');
}

1;