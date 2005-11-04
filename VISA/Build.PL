#!/usr/bin/perl
#$Id$

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name => 'VISA', 
    extra_linker_flags  => '-lvisa -lstdc++',
    license     => 'perl',
    requires    => {
        'SOAP::Lite'        => 0,
        'HTML::Entities'    => 0,
        'Text::Autoformat'  => 0,
        'Encode'            => 0,
        'Exporter'          => 0,
    },
    script_files    	=> ['wsws.pl'],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schroeer <daniel@daimla1.de>');
$build->create_build_script;
