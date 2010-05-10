#!/usr/bin/perl

use 5.008;
use strict;
use ExtUtils::MakeMaker;

# If you have Swig installed, un-comment the next line 
# to re-create the wrapper code.
# If you do so, also un-comment the 'clean' section below
# to delete the swig-generated files when doing 'make clean'.
# TODO: should just check if swig is in the path

#system("swig -perl5 -module Lab::VISA visa.i");

WriteMakefile(
#   'clean'             => {
#       FILES => 'VISA.pm visa_wrap.c'
#   },

# Important: you have to adjust the 'LIBS' and 'INC' paths according to your local setup!
# The correct values may depend on your exact version of LabView, VISA, GPIB drivers, 
# the phase of the moon and the local neutrino density...
# First two lines are for Windows, second two lines are for Linux.
# TODO: find out how to figure these out automatically.

    (($^O =~ /MSWin32/)
    ?   ('LIBS'         => ['"-lC:\\VXIPNP\\WinNT\\lib\\msc\\visa32.lib"'],
         'INC'          => '"-IC:\\VXIPNP\\WinNT\\include "',
        )
    :   ('LIBS'         => ['-lvisa'],
         'INC'          => '-I/usr/local/include/',
        )
    ),
    'NAME'              => 'Lab::VISA',
    'VERSION_FROM'      => 'VISA.pm',
    'OBJECT'            => q/$(O_FILES)/,
    'META_MERGE'        => {
        resources => {
            homepage    =>      'http://labvisa.de',
            bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-VISA',
            MailingList =>      'lab-visa-users@mailman.uni-regensburg.de',
        },
    },

    (($] >= 5.005)
    ?   (ABSTRACT_FROM  => 'VISA.pod',
         AUTHOR         => 'Daniel Schroeer <schroeer@cpan.org>') : ()),

);
