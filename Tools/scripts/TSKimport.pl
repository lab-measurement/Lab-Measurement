#!/usr/bin/perl

use strict;
use Lab::Data::Writer;

unless (2==scalar @ARGV) {
	print "This programm can join the datafiles of a multidim sweep with GPplus\nusage: $0 <one_filename> <new_name>\n";
	exit;
}
my ($filename,$destname)=@ARGV;

my $archive;
GetOptions("archive=s" => \$archive);  # flag

unless (defined($archive)) {
	print "Do you want to put the source files to an archive directory below $destname?\n";
	print "([no]|copy|move) ";
	chomp(my $archive=<STDIN>);
}
$archive=0 unless ($archive =~ /copy|move/);

my $importer=new Lab::Data::Writer;
my ($newpath,$newname,$num_files,$total_lines,$num_col,$blocknum)=
	$importer->import_gpplus(
		filename	=> $filename,
		newname		=> $destname,
		archive		=> $archive,
	);

if ($newpath) {
	print "Imported a total of $total_lines data lines from $num_files files.\n";
	print "Each line contains $num_col columns. Data is grouped into $blocknum blocks.\n";
	print "New files are at $newpath$newname.DATA\nand $newpath$newname.META.\n";
} else {
	print "Error!\n";
}