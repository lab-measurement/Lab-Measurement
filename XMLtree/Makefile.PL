#$Id$

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'XMLtree',
    VERSION_FROM      => 'lib/XMLtree.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XMLtree.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Schröer <daniel.schroeer@physik.uni-muenchen.de>') : ()),
);
