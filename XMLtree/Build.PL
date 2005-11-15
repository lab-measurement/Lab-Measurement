#!/usr/bin/perl
#$Id: Build.PL 85 2005-11-10 23:35:43Z schroeer $

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'Lab::XMLtree', 
    license     => 'perl',
    requires    => {
    },
    script_files    	=> [],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schroeer <daniel@daimla1.de>');
$build->create_build_script;
