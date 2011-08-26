#!/usr/bin/perl

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Measurement',
    dist_abstract     => 'Bus drivers, Instrument drivers, and measurement scripts',
    license           => 'perl',
    requires          => {
	'Exception::Class'   => '1.0',
        'Time::HiRes'        => 0,
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
        'Term::ReadKey'      => 0,
        'Switch'             => 0,
    },
    script_files => 'scripts',
    share_dir => {
        dist => [ 'examples' ],
    },
    create_readme     => 0,
    dist_author       => ['Daniel Schröer <schroeer@cpan.org>',
                          'Andreas K. Huettel <mail@akhuettel.de>',
                          'Daniela Taubert <daniela.taubert@physik.uni-muenchen.de>', 
                          'Florian Olbrich <florian.olbrich@physik.uni-r.de>'
                         ],
    meta_merge        => {
        resources       => {
            homepage      => 'http://www.labmeasurement.de/',
            bugtracker    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-Measurement',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
        }
    },
);
$build->create_build_script;
