#!/usr/bin/perl

use strict;
use Lab::Data::Meta;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

my %options=(#  => default
);

GetOptions(\%options,
    'help|?',
    'man',
);

pod2usage(1) if $options{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $options{man};

my $metafile=shift(@ARGV) or pod2usage(1);

my $meta=Lab::Data::Meta->new_from_file($metafile);

print "\n----------------------------------------------------\n";
print $meta->data_file(),"\n";
print $meta->dataset_title()," (Sample ",$meta->sample(),")";
print "\n----------------------------------------------------\n";
print $meta->dataset_description(),"\n";

print "Constants:\n";
my @const=$meta->constant();
my $num=1;
for (@const) {
    print "(",$num++,") ",$_->{name}," = ",$_->{value},"\n";
}

print "\nColumns:\n";
my @cols=$meta->column();
$num=1;
for (@cols) {
    print "(",$num++,") ",$_->{label}," (",$_->{description},")\n";
}

print "\nAxes:\n";
my @axes=$meta->axis();
$num=1;
for (@axes) {
    print "(",$num++,") ",$_->{label}," (",$_->{description},")\n";
}

print "\nAvailable plots:\n";
my %plots=$meta->plot();
$num=1;
for (sort keys %plots) {
    my $xlabel=$meta->axis_label($plots{$_}->{xaxis});
    my $ylabel=$meta->axis_label($plots{$_}->{yaxis});

    print "(",$num++,") $_: $ylabel vs. $xlabel\n";
}

__END__

=head1 NAME

metainfo.pl - Show info from meta file.

=head1 SYNOPSIS

metainfo.pl [OPTIONS] METAFILE

=head1 DESCRIPTION

This is a commandline tool to...

=head1 OPTIONS AND ARGUMENTS

The file C<METAFILE> contains meta information about one dataset.
This information is printed.

=head1 SEE ALSO

=over 2

=item gnuplot(1)

=item L<Lab::Measurement>

=item L<Lab::Data::Plotter>

=item L<Lab::Data::Meta>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$.

Copyright 2004 Daniel Schröer.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
