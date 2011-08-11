package Documentation::LabVISAdoc;

use strict;
use File::Basename;
use Cwd;
use YAML;
use File::Path qw(make_path);
use Data::Dumper;
$Data::Dumper::Indent = 1;

sub new {
    my ($proto, $docdir, $tempdir, $keeptemp) = @_;
    my $self = bless {
        docdir      => $docdir,
        tempdir     => $tempdir,
        keeptemp    => $keeptemp,
    }, ref($proto) || $proto;
    
    unless (-d $$self{docdir}) {
        make_path($$self{docdir});
    }
    unless (-d $$self{tempdir}) {
        make_path($$self{tempdir});
    }
    
    return $self;
}

sub process {
    my ($self, $yamlfile) = @_;
    
    open YAML, "<", $yamlfile || die "Can't open $yamlfile: $!\n";
    my $yml = join "", <YAML>;
    close YAML;
    my $dokudef = Load($yml);
    #print Dumper($dokudef);

    $self->start($dokudef->{title}, $dokudef->{authors});
    $self->walk_one_section({ $dokudef->{title} => $dokudef->{toc} }, ());
    $self->finish();
    
    my $basedir = getcwd();

    unless ($self->{keeptemp}) {
      if (chdir $self->{tempdir}) {
          unlink(<*>);
          chdir $basedir;
      }
      rmdir $self->{tempdir} or warn sprintf("Cannot delete temp directory %s: %s\n", $self->{tempdir}, $!);
    } 
}

sub walk_one_section {
    my ($self, $section, @sections) = @_;
    my $title = (keys %$section)[0];
    $self->start_section($#sections + 2, $title) if (@sections);
    push(@sections, $title);
    for my $element (@{$section->{$title}}) {
        unless (ref($element)) {
            $self->process_element($element, {}, @sections);
        }
        elsif (ref($element) eq 'HASH') {
            my $key0 = (keys %$element)[0];
            if (ref($element->{$key0}) eq 'HASH') {
                # element with additional parameters
                my $params = $element->{$key0};
                $self->process_element($key0, $params, @sections);
            }
            else {
                $self->walk_one_section($element, @sections);
            }
        }
        else {
            die "You have messed up the toc file at ".(join "/", @sections)."/$element";
        }
    }
}

# Documentation::LabVISADoc is sort of an abstract class
# the following abstract methods are to be overwritten

sub start {
    my ($self, $title, $authors) = @_;
}

sub start_section {
    my ($self, $level, $title) = @_;
    # where level is [2..]
}

sub process_element {
    my ($self, $podfile, $params, @sections) = @_;
}

sub finish {
    my $self = shift;
}

1;
