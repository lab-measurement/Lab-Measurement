#!/usr/bin/perl
#$Id: Build.PL 85 2005-11-10 23:35:43Z schroeer $

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name         => 'Lab::Tools', 
    dist_version        => '1.2',
    dist_abstract       => 'Tools to obtain and work with data in the laboratory',
    license             => 'perl',
    requires            => {
        'XML::DOM'          => 0,
        'XML::Generator'    => 0,
        'Data::Dumper'      => 0,
        'Encode'            => 0,
        'File::Basename'    => 0,
        'Cwd'               => 0,
        'Time::HiRes'       => 0,
        'File::Basename'    => 0,
        'File::Copy'        => 0,
        'encoding::warnings'=> 0,
    },
    script_files    	=> [
	'scripts/yoko_goto.pl',
	'scripts/knick_goto.pl',
	'scripts/hp_read.pl',
	'scripts/plotter.pl',
	'scripts/metainfo.pl'
    ],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schröer <schroeer@cpan.org>');
$build->create_build_script;
