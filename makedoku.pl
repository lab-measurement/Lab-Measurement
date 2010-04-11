#!/usr/bin/perl

use strict;
use YAML qw(LoadFile);
use Documentation::LaTeX;
use Documentation::HTML;
use Data::Dumper;
$Data::Dumper::Indent = 1;

my $dokudef = LoadFile('dokutoc.yaml');
#print Dumper($dokudef);

my $processor = ($ARGV[0] =~ /html/) ? new Documentation::HTML() : new Documentation::LaTeX();   

$processor->start_index($dokudef->{title}, $dokudef->{authors});

for my $section (@{$dokudef->{toc}}) {
    walk_one_section($section, $dokudef->{title});
}

$processor->finish_index();

sub walk_one_section {
    my ($section, @sections) = @_;
    my $title = (keys %$section)[0];
    $processor->start_section($#sections + 2, $title);
    push(@sections, $title);
    for my $element (@{$section->{$title}}) {
        unless (ref($element)) {
            $processor->process_element($element, @sections);
        }
        elsif (ref($element) eq 'HASH') {
            walk_one_section($element, @sections);
        }
        else {
            die "You have messed up the toc file at ".(join "/", @sections)."/$element";
        }
    }
}
