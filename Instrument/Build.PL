#!/usr/bin/perl
#$Id$

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name         => 'Lab::Instrument',
    dist_version_from   => 'README',
    license             => 'perl',
    requires            => {
        'Lab::VISA'   => '1.11',
        'Time::HiRes' => 0,
    },
    test_files          => ['t/2_visa-instrument.t','t/3_source.t','t/4_dummysource.t'],
    script_files    	=> [],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schroeer <schroeer@cpan.org>');
$build->create_build_script;
