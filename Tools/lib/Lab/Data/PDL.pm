#!/usr/bin/perl

#rename to PDLtools;
package TSKTools;

use strict;
use PDL;

sub TSKload {
    my $basename=shift;
    $basename=~s/_$//;

    my @files=sort {
        ($a =~ /$basename\_(\d+)\.TSK/)[0] <=> ($b =~ /$basename\_(\d+)\.TSK/)[0]
    } glob $basename."_*.TSK";
    (my $path)=($basename =~ m{((/?[^/]+/)+)?[^/]+$})[0];
    $basename =~ s{(/?[^/]+/)+}{};

    my $cols;
    my $blocknum=-1;
    for (@files) {
        $blocknum++;
        print "\rProcessing file: $_    ";
        my @fcols;
        open IN,"<$_" or die $!;
        while (<IN> !~ /DATA MEASURED/) {}
        while (<IN>) {
            s/[\n\r]+$//g;
            my @values=split ";";
            for (0..$#values) {
                push(@{$fcols[$_]},$values[$_]);
            }
        }
        for my $colnum (0..$#fcols) {
            $cols=zeroes(scalar @fcols,scalar @files,scalar @{$fcols[$colnum]}) unless (defined $cols);
            (my $pdl = $cols->slice("$colnum,($blocknum),:")) .= pdl(@{$fcols[$colnum]})->reshape(1,scalar @{$fcols[$colnum]});
        } 
        close IN;
    }
    print $cols->info("\rDim: %D Memory: %M                         \n");
    return $cols;
}

sub coord_transform {
    my ($piddle,$o,$t)=@_;
    # performs a coordinate transform
    # of the $piddle (in place)
    # the piddle is assumed to be in column-ordered style
    # as created by TSKload
    #
    # ^a_i is the basis of the old columns
    # ^b_i is the basis of the new columns
    #
    # you supply the coefficients to
    # express ^b in terms of ^a:
    # @t=(t_11,t_12,...,t_21,t_22,...,t_nn)
    # with ^b_i = sum_j t_ij ^a_j
    #
    # example:
    # 3 columns named x,y,color
    # transform data to a new coordinate system
    # xx = 4  +   0.3 * x  +  0.1 * y  +  0 * color
    # yy = 5  +  -0.2 * x  +  1.8 * y  + ..
    # cc = 0  +   color    + ..
    # ($piddle,
    #   [ 4   , 5   , 0 ],
    #   [ 0.3 , 0.1 , 0 ,
    #    -0.2 , 1.8 , 0 ,
    #     0   , 0   , 1 ]
    # )
    my $off=pdl($o);
    my $mat=pdl($t)->reshape(sqrt(@$t),sqrt(@$t));
    my $lines=$piddle->clump(2,3);
    $lines=$off+$mat*$lines;
}

1;
