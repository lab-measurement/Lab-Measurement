#!/usr/bin/perl

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name   => 'Lab::Tools',
    dist_abstract => 'Tools to obtain and handle data with Lab::Measurement',
    dist_version => '2.90',
    license       => 'perl',
    requires      => {
        'XML::DOM'           => 0,
        'XML::Generator'     => 0,
        'XML::Twig'          => 0,
        'Data::Dumper'       => 0,
        'Encode'             => 0,
        'Cwd'                => 0,
        'Time::HiRes'        => 0,
        'File::Basename'     => 0,
        'File::Copy'         => 0,
        'encoding::warnings' => 0,
    },
    recommends   => {
        'Lab::VISA'          => '2.90',
        'Lab::Instrument'    => '2.90',
    },
    script_files => 'scripts',
    create_readme => 0,
    dist_author   => 'Daniel Schröer <schroeer@cpan.org>',
    meta_merge    => {
        resources => {
            homepage    => 'http://www.labmeasurement.de/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-Tools',
            MailingList => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
        }
    },
);
$build->create_build_script;
