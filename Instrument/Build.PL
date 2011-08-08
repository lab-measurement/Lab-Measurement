#!/usr/bin/perl

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Instrument',
    dist_abstract     => 'High-level instrument drivers for Lab::Measurement',
    license           => 'perl',
    requires          => {
        'Lab::Bus' => '2.90',
        'Lab::Connection' => '2.90',
        'Lab::Exception' => '2.90',
        'Time::HiRes'   => 0,
    },
    test_files        => [ 't/3_source.t', 't/4_dummysource.t' ],
    script_files      => [],
    create_readme     => 0,
    dist_author       => 'Daniel Schröer <schroeer@cpan.org>',
    meta_merge        => {
        resources       => {
            homepage      => 'http://www.labmeasurement.de/',
            bugtracker    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-Instrument',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
        }
    },
);
$build->create_build_script;
