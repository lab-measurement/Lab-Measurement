#!/usr/bin/perl
#$Id$

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Connector',
    dist_abstract     => 'Interface drivers for Lab::Instrument',
    dist_version_from => 'README',
    license           => 'perl',
    requires          => {
        'Lab::Exception' => '0.1',
        'Lab::VISA' => '0.1',
        'Time::HiRes'   => 0,
    },
    test_files        => [],
    script_files      => [],
    create_readme     => 0,
    dist_author       => 'Daniel Schröer <schroeer@cpan.org>',
    meta_merge        => {
        resources       => {
            homepage      => 'http://labvisa.de',
            bugtracker    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-Connector',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
        }
    },
);
$build->create_build_script;
