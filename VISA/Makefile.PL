#!/usr/bin/perl

use 5.008;
use strict;
use ExtUtils::MakeMaker;

`swig -perl5 -c++ visa.i`;

WriteMakefile(
	'NAME'			=> 'VISA',
	'VERSION_FROM'	=> 'visa.i',			# finds $VERSION
	'PREREQ_PM'		=> {},					# e.g., Module::Name => 1.1
	($] >= 5.005 ?							## Add these new keywords supported since 5.005
		(ABSTRACT_FROM	=> 'VISA.pod',		# retrieve abstract from module
		 AUTHOR			=> 'Daniel Schröer <daniel.schroeer@physik.uni-muenchen.de.de>') : ()),
	'LIBS'			=> ['-lvisa -lstdc++'],				# e.g., '-lm'
	'OBJECT'		=> q/$(O_FILES)/,
	'DEFINE'		=> '',					# e.g., '-DHAVE_SOMETHING'
	'INC'			=> '-I.',				# e.g., '-I. -I/usr/include/other'
	'clean'			=> {
		FILES	=> 'VISA.pm visa_wrap.cxx'},
);
