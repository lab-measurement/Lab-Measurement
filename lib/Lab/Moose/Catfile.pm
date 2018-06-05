package Lab::Moose::Catfile;

use warnings;
use strict;

# ABSTRACT: Export custom catfile which avoids backslashes

# PDL::Graphics::Gnuplot <= 2.011 cannot handle backslashes on windows.

=head1 SYNOPSIS

 use Lab::Moose::Catfile;
 my $dir = our_catfile($dir1, $dir2, $basename);

=cut

our @ISA    = qw(Exporter);
our @EXPORT = qw/our_catfile/;

sub our_catfile {
    if ( @_ == 0 ) {
        return;
    }
    return join( '/', @_ );
}

1;
