#!/usr/bin/perl

use	5.008;
use	strict;
use	ExtUtils::MakeMaker;

# If you have Swig installed, uncomment the next line 
# to re-create the wrapper code

#`swig -perl5	-module	Lab::VISA	-c++ visa.i`;

WriteMakefile(
	'NAME'				=> 'Lab::VISA',
	'VERSION_FROM'		=> 'visa.i',
	'PREREQ_PM'			=> {},
	'OBJECT'			=> q/$(O_FILES)/,
	'DEFINE'			=> '',

#	'clean'				=> {
#		FILES	=> 'VISA.pm	visa_wrap.cxx'
#	},

	(($] >=	5.005)
	?	(ABSTRACT_FROM	=> 'VISA.pod',
		 AUTHOR			=> 'Daniel Schröer <daniel.schroeer@physik.uni-muenchen.de.de>') : ()),

	# Adjust these pathes according to your local setup!
	# First two lines are for Windows,
	# second two lines are for Linux
	(($^O	=~ /MSWin32/)
	?	('LIBS'			=> ['-lC:\\VXIPNP\\WinNT\\lib\\msc\\visa32.lib'],
		 'INC'			=> '-IC:\\VXIPNP\\WinNT\\include "-IC:\\Program Files\\Microsoft Visual Studio 8\\VC\\PlatformSDK\\Include"',)
	:	('LIBS'			=> ['-lvisa	-lstdc++'],
		 'INC'			=> '-I/usr/local/vxipnp/linux/include/',)),

);
