package Documentation::HTML;

use strict;
use File::Basename;

sub new {
    my $proto=shift;
    my $self = bless {
        docdir      => 'Documentation',
        'list_open' => 0,
    }, ref($proto) || $proto;
    return $self;
}

sub start_index {
    my $self = shift;
    unless (-d $$self{docdir}) {
        mkdir $$self{docdir};
    }
    unless (-d "$$self{docdir}/html") {
        mkdir "$$self{docdir}/html";
    }
    open $self->{index_fh}, ">", "$$self{docdir}/index.html" or die;
    print {$self->{index_fh}} $self->_get_header("Index");
    print {$self->{index_fh}} "<h1>Lab::VISA Documentation</h1>\n";
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
    my $title = ((@sections) ? "$sections[0]: " : "").$basename;
    my $headers = (@sections) ? 
            qq(<h1><a href="../index.html">).shift(@sections)
            .qq(</a>: <span class="basename">$basename</span></h1>\n)
        : "";
    my $header = <<HEADER;
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
	<head>
   		<link rel="stylesheet" type="text/css" href="../doku.css">
   		<link rel="stylesheet" type="text/css" href="doku.css">
   		<title>$title</title>
 	</head>
 	<body>
 		$headers
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