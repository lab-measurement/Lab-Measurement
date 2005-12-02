#!/usr/bin/perl

use strict;

my (@x,@y,@z);
for (1..3) {
    print "Enter vertex $_ x,y,z: ";
    chomp(my $in=<STDIN>);
    ($x[$_],$y[$_],$z[$_])=split ",",$in;
}

#@x=(undef,1,2,-3);@y=(undef,-1,-0.2,0.001);@z=(undef,1.1,2,0);

my $y32=$y[3]-$y[2];
my $y31=$y[3]-$y[1];
my $y21=$y[2]-$y[1];

my $x32=$x[3]-$x[2];
my $x31=$x[3]-$x[1];
my $x21=$x[2]-$x[1];

my $a= -($z[1]*$y32 - $z[2]*$y31 + $z[3]*$y21)/
        ($y[1]*$x32 - $y[2]*$x31 + $y[3]*$x21);
        
my $b=  ($z[1]*$x32 - $z[2]*$x31 + $z[3]*$x21)/
        ($y[1]*$x32 - $y[2]*$x31 + $y[3]*$x21);

my $C=  ($z[1]*($x[2]*$y[3]-$x[3]*$y[2]) + $z[2]*($x[3]*$y[1]-$x[1]*$y[3]) + $z[3]*($x[1]*$y[2]-$x[2]*$y[1]))/
        ($y[1]*$x32 - $y[2]*$x31 + $y[3]*$x21);

print "Ebene: z=ax+by+C\n",
      "mit a=$a\nb=$b\nC=$C\n\n";

for (1..3) {
    print "Test: $z[$_]=",$a*$x[$_]+$b*$y[$_]+$C,"\n";
}
