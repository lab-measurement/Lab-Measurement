#!/usr/bin/perl

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Connection',
    dist_abstract     => 'Instrument connection drivers for Lab::Measurement',
    license           => 'perl',
    requires          => {
        'Lab::Exception' => '2.90',
        'Lab::Bus' => '2.90',
        'Time::HiRes'   => 0,
    },
    test_files        => [],
    script_files      => [],
    create_readme     => 0,
    dist_author       => 'Daniel Schröer <schroeer@cpan.org>',
    meta_merge        => {
        resources       => {
            homepage      => 'http://labvisa.de',
            bugtracker    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-Connection',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
        }
    },
);
$build->create_build_script;
