package Documentation::LabVISAdoc;

use strict;
use File::Basename;
use Cwd;

sub new {
    my $proto=shift;
    my $self = bless {
        docdir      => shift,
        tempdir     => shift,
    }, ref($proto) || $proto;
    unless (-d $$self{docdir}) {
        mkdir $$self{docdir};
    }
    unless (-d $$self{tempdir}) {
        mkdir $$self{tempdir};
    }
    return $self;
}

sub process {
    my ($self, $dokudef) = @_;
    $self->start($dokudef->{title}, $dokudef->{authors});
    $self->walk_one_section({ $dokudef->{title} => $dokudef->{toc} });
    $self->finish();
    
    my $basedir = getcwd();
    if (chdir $self->{tempdir}) {
        unlink(<*>);
        chdir $basedir;
    }
    rmdir $self->{tempdir} or warn "tempdir löschen geht nicht: $!";
    
}

sub walk_one_section {
    my ($self, $section, @sections) = @_;
    my $title = (keys %$section)[0];
    $self->start_section($#sections + 2, $title) if (@sections);
    push(@sections, $title);
    for my $element (@{$section->{$title}}) {
        unless (ref($element)) {
            $self->process_element($element, @sections);
        }
        elsif (ref($element) eq 'HASH') {
            $self->walk_one_section($element, @sections);
        }
        else {
            die "You have messed up the toc file at ".(join "/", @sections)."/$element";
        }
    }
}

# the following are to be overwritten

sub start {
    my ($self, $title, $authors) = @_;
}

sub start_section {
    my ($self, $level, $title) = @_;
    # wherein level is [2..]
}

sub process_element {
    my ($self, $podfile, @sections) = @_;
}

sub finish {
    my $self = shift;
}

1;