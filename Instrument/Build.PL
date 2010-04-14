#!/usr/bin/perl
#$Id$

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name         => 'Lab::Instrument',
    dist_version_from   => 'README',
    license             => 'perl',
    requires            => {
        'Lab::VISA'   => '2.03',
        'Time::HiRes' => 0,
    },
    test_files          => ['t/3_source.t','t/4_dummysource.t'],
    script_files    	=> [],
    create_readme   	=> 0,
    dist_author     	=> 'Daniel Schroeer <schroeer@cpan.org>',
	dist_abstract		=> 'Lab::Instrument offers an abstract interface to an instrument that is connected via GPIB, serial connection, ethernet, USB, or whatever else the NI-VISA library supports. In addition Oxford Instruments IsoBus is also supported.');
$build->create_build_script;
