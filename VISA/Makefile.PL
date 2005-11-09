#!/usr/bin/perl

use 5.008;
use strict;
use ExtUtils::MakeMaker;

#`swig -perl5 -module Lab::VISA -c++ visa.i`;

WriteMakefile(
	'NAME'			=> 'Lab::VISA',
	'VERSION_FROM'	=> 'visa.i',
	'PREREQ_PM'		=> {},
	($] >= 5.005 ?
		(ABSTRACT_FROM	=> 'VISA.pod',
		 AUTHOR			=> 'Daniel Schröer <daniel.schroeer@physik.uni-muenchen.de.de>') : ()),
	'LIBS'			=> ['-lvisa -lstdc++'],
	'OBJECT'		=> q/$(O_FILES)/,
	'DEFINE'		=> '',
	'INC'			=> '-I.',
	'clean'			=> {
#		FILES	=> 'VISA.pm visa_wrap.cxx'
	},
);
