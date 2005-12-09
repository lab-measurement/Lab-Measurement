#!/usr/bin/perl

use 5.008;
use strict;
use ExtUtils::MakeMaker;

# If you have Swig installed, un-comment the next line 
# to re-create the wrapper code.
# If you do so, also un-comment the 'clean' section below
# to delete the swig-generated files when doing 'make clean'.

#`swig -perl5 -module Lab::VISA -c++ visa.i`;

WriteMakefile(
#   'clean'             => {
#       FILES => 'VISA.pm visa_wrap.cxx'
#   },

# Adjust the 'LIBS' and 'INC' pathes according to your local setup!
# First two lines are for Windows, second two lines are for Linux.
    (($^O =~ /MSWin32/)
    ?   ('LIBS'         => ['-lC:\\VXIPNP\\WinNT\\lib\\msc\\visa32.lib'], # needs full path on my setup
         'INC'          => '-IC:\\VXIPNP\\WinNT\\include '.               # next one is for windows sdk
                           '"-ID:\\Microsoft Platform SDK\\Include"',)
    :   ('LIBS'         => ['-lvisa -lstdc++'],                           # stdc++ is necessary here
         'INC'          => '-I/usr/local/vxipnp/linux/include/',)),

    'NAME'              => 'Lab::VISA',
    'VERSION_FROM'      => 'README',
    'PREREQ_PM'         => {},
    'OBJECT'            => q/$(O_FILES)/,
    'DEFINE'            => '',

    (($] >= 5.005)
    ?   (ABSTRACT_FROM  => 'VISA.pod',
         AUTHOR         => 'Daniel Schroeer (SCHROEER) <daniel.schroeer@physik.uni-muenchen.de>') : ()),

);
