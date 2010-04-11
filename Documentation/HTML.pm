package Documentation::HTML;

use strict;
use File::Basename;
use Syntax::Highlight::Engine::Simple::Perl;

sub new {
    my $proto=shift;
    my $self = bless {
        docdir      => 'Documentation',
        'list_open' => 0,
        highlighter => Syntax::Highlight::Engine::Simple::Perl->new(),
    }, ref($proto) || $proto;
    return $self;
}

sub start_index {
    my ($self, $title, $authors) = @_;
    unless (-d $$self{docdir}) {
        mkdir $$self{docdir};
    }
    unless (-d "$$self{docdir}/html") {
        mkdir "$$self{docdir}/html";
    }
    open $self->{index_fh}, ">", "$$self{docdir}/index.html" or die;
    print {$self->{index_fh}} $self->_get_index_header($title, $authors);
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
    my ($self, $podfile, @sections) = @_;
    my $basename = fileparse($podfile,qr{\.(pod|pm)});
    
    my $parser = MyPodXHTML->new();
    my $html;
    $parser->output_string(\$html);
    $parser->parse_file($podfile);
    open OUTFILE, ">", "$$self{docdir}/html/$basename.html" or die;
        print OUTFILE $self->_get_header($basename, @sections);
        print OUTFILE $html;
        print OUTFILE $self->_get_footer();
    close OUTFILE;
    
    my $source = $self->{highlighter}->doFile(
        file       => $podfile,
        tab_width => 4,
        encode    => 'iso-8859-1'
    );
    open SRCFILE, ">", "$$self{docdir}/html/$basename\_source.html" or die;
        print SRCFILE $self->_get_source_header($basename, @sections);
        print SRCFILE "<pre>\n$source</pre>\n";
        print SRCFILE $self->_get_footer();
    close SRCFILE;
    
    unless ($self->{list_open}) {
        print {$self->{index_fh}} "<ul>\n";
        $self->{list_open} = 1;
    }
    print {$self->{index_fh}} qq(<li><a class="index" href="html/$basename.html">$basename</a></li>\n);
}

sub finish_index {
    my $self = shift;
    if ($self->{list_open}) {
        print {$self->{index_fh}} "</ul>\n";
        $self->{list_open} = 0;
    }
    print {$self->{index_fh}} $self->_get_footer();
    close $self->{index_fh};
}

sub _get_header {
    my ($self, $basename, @sections) = @_;
    my $title = "$sections[0]: $basename";
    my $headlines = (@sections) ? 
            qq(<h1><a href="../index.html">).shift(@sections)
            .qq(</a>: <span class="basename">$basename</span></h1>\n)
        : "";
    my $header = <<HEADER;
<?xml version="1.0" encoding="iso-8859-1" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
	<head>
   		<link rel="stylesheet" type="text/css" href="../doku.css">
   		<title>$title</title>
 	</head>
 	<body>
 		$headlines
   		<p>(<a href="$basename\_source.html">Source code</a>)</p>
HEADER
    return $header;
}

sub _get_index_header {
    my ($self, $title, $authors) = @_;
    my $header = <<HEADER;
<?xml version="1.0" encoding="iso-8859-1" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
	<head>
   		<link rel="stylesheet" type="text/css" href="doku.css">
   		<title>Index</title>
 	</head>
 	<body>
 	    <h1>$title</h1>
 	    <p>$authors</p>
HEADER
    return $header;
}

sub _get_source_header {
    my ($self, $basename, @sections) = @_;
    my $title = "$sections[0]: $basename";
    my $headlines = (@sections) ? 
            qq(<h1><a href="../index.html">).shift(@sections)
            .qq(</a>: <span class="basename">$basename</span></h1>\n)
        : "";
    my $header = <<HEADER;
<?xml version="1.0" encoding="iso-8859-1" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
	<head>
   		<link rel="stylesheet" type="text/css" href="../doku.css">
   		<title>$title</title>
 	</head>
 	<body>
 		$headlines
   		<p>(<a href="$basename.html">Documentation</a>)</p>
HEADER
    return $header;
}

sub _get_footer {
    return <<FOOTER;
 	</body>
</html>
FOOTER
}





package MyPodXHTML;
use strict;
use base qw/ Pod::Simple::XHTML /;
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
    } else {
        $section = ''
    }

    return ($self->perldoc_url_prefix || '')
        . encode_entities($to) . $section
        . ($self->perldoc_url_postfix || '');
}




1;