#!/usr/bin/perl
#$Id$

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'VISA', 
    extra_linker_flags  => '-lvisa -lstdc++',
    license     => 'perl',
    requires    => {
    },
    script_files    	=> ['wsws.pl'],
    create_readme   	=> 0,
    dist_author     	=> 'Daniel Schroeer <daniel@daimla1.de>');
$build->create_build_script;
