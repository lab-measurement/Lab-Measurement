#!/usr/bin/perl
#$Id: Build.PL 85 2005-11-10 23:35:43Z schroeer $

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'Lab::Tools', 
    dist_version=> '0.02',
    license     => 'perl',
    requires    => {
    },
    script_files    	=> ['scripts/lecktester.pl','scripts/yoko_goto.pl','scripts/knick_goto.pl'],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schroeer <daniel@daimla1.de>');
$build->create_build_script;
