#!/usr/bin/perl

use 5.008;
use strict;
use ExtUtils::MakeMaker;

# If you have Swig installed, un-comment the next line 
# to re-create the wrapper code.
# If you do so, also un-comment the 'clean' section below
# to delete the swig-generated files when doing 'make clean'.

#system("swig -perl5 -module Lab::VISA visa.i");

WriteMakefile(
#   'clean'             => {
#       FILES => 'VISA.pm visa_wrap.c'
#   },

# Adjust the 'LIBS' and 'INC' pathes according to your local setup!
# First two lines are for Windows, second two lines are for Linux.
    (($^O =~ /MSWin32/)
    ?   ('LIBS'         => ['"-lC:\\Programme\\IVI Foundation\\VISA\\WinNT\\lib\\msc\\visa32.lib"'],
         'INC'          => '"-IC:\\Programme\\National Instruments\\Shared\\CVI\\include "',
        )
    :   ('LIBS'         => ['-lvisa'],                           # stdc++ is not anymore necessary here
         'INC'          => '-I/usr/local/vxipnp/linux/include/',
        )
    ),
    'NAME'              => 'Lab::VISA',
    'VERSION_FROM'      => 'VISA.pm',
    'PREREQ_PM'         => {},
    'OBJECT'            => q/$(O_FILES)/,
    'DEFINE'            => '',

    (($] >= 5.005)
    ?   (ABSTRACT_FROM  => 'VISA.pod',
         AUTHOR         => 'Daniel Schroeer <schroeer@cpan.org>') : ()),

);
