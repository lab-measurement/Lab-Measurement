#!/usr/bin/perl

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Instrument',
    dist_abstract     => 'Instrument and bus drivers for Lab::Measurement',
    license           => 'perl',
    requires          => {
	'Exception::Class' => '1.0',
        'Time::HiRes'   => 0,
    },
    test_files        => [ 't/3_source.t', 't/4_dummysource.t' ],
    script_files      => [],
    create_readme     => 0,
    dist_author       => ['Daniel Schröer <schroeer@cpan.org>',
                          'Andreas K. Huettel <mail@akhuettel.de>',
                          'Daniela Taubert', 
                          'Florian Olbrich'
                         ],
    meta_merge        => {
        resources       => {
            homepage      => 'http://www.labmeasurement.de/',
            bugtracker    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-Instrument',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
        }
    },
);
$build->create_build_script;
