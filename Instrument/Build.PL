#!/usr/bin/perl
#$Id$

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'Lab::Instrument', 
    license     => 'perl',
    requires    => {
        'Lab::VISA'   => 0,
    },
    script_files    	=> [],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schroeer <daniel@daimla1.de>');
$build->create_build_script;
