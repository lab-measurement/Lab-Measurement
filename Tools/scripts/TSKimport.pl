#!/usr/bin/perl

use strict;
use Lab::Data::Writer;
use Getopt::Long;

my $archive;
GetOptions("archive=s" => \$archive);  # flag

unless (2==scalar @ARGV) {
	print "This programm can join the datafiles of a multidim sweep with GPplus\nusage: $0 <one_filename> <new_name>\n";
	exit;
}
my ($filename,$destname)=@ARGV;


unless (defined($archive)) {
	print "Do you want to put the source files to an archive directory below $destname?\n";
	print "([no]|copy|move) ";
	chomp($archive=<STDIN>);
}
$archive=0 unless ($archive =~ /(copy)|(move)/);

my $importer=new Lab::Data::Writer;
my ($newpath,$newname,$num_files,$total_lines,$num_col,$blocknum,$archive_dir)=
	$importer->import_gpplus(
		filename	=> $filename,
		newname		=> $destname,
		archive		=> $archive,
	);

if ($newname) {
	print "Import successfull: $num_files files; $total_lines lines; ";
	print "$num_col columns; $blocknum blocks.\n";
	print "New data file $newpath$newname.DATA\nNew meta file $newpath$newname.META.\n";
	if ($archive) {
		print "Archive ($archive) at $archive_dir/.\n";
	}
} else {
	print "Import not successfull: $newpath\n";
}