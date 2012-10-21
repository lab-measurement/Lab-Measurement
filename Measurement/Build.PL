#!/usr/bin/perl

use strict;
use utf8;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Measurement',
    dist_abstract     => 'Test and measure with Perl',
    license           => 'perl',
    requires          => {
	'Exception::Class'   => '1.0',
        'Time::HiRes'        => 0,
        'XML::DOM'           => 0,
        'XML::Generator'     => 0,
        'XML::Twig'          => 0,
        'Data::Dumper'       => 0,
        'Encode'             => 0,
        'TeX::Encode'        => 0,
        'Cwd'                => 0,
        'Time::HiRes'        => 0,
        'File::Basename'     => 0,
        'File::Copy'         => 0,
        'encoding::warnings' => 0,
        'Term::ReadKey'      => 0,
        'Switch'             => 0,
        'Clone'              => '0.31',
	'Module::Build'      => '0',
    },
    conflicts         => {
        'Lab::Instrument'    => '< 2.91',
        'Lab::Tools'         => '< 2.91',
    },
    script_files => [ 'scripts', 'lib/Lab/XPRESS/Xpression.pl' ],
    create_readme     => 0,
    dist_author       => ['Daniel Schröer <schroeer@cpan.org>',
                          'Andreas K. Hüttel <mail@akhuettel.de>',
                          'Daniela Taubert <daniela.taubert@physik.uni-muenchen.de>', 
                          'Florian Olbrich <florian.olbrich@devtek.de>',
                          'Alois Dirnaichner <alois.dirnaichner@physik.uni-r.de>'
                         ],
    meta_merge        => {
        resources       => {
            homepage      => 'http://www.labmeasurement.de/',
            bugtracker    => 'https://www.labmeasurement.de/bugs/',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
            repository    => 'git://gitorious.org/lab-measurement/lab.git',
        }
    },
);
$build->create_build_script;
