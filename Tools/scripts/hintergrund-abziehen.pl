#!/usr/bin/perl
#$Id$

# Eierlegende Wollmilchsau. Öffnet RAW-File mit SD-Sweeps über Kondopeak und
# findet linkes und rechtes Minimum und dazwischenliegendes Maximum. Dann wird von
# den Kurven ein Untergrund abgezogen, und zwar entweder eine Gerade, die die
# beiden Minima verbindet, oder der Wert der Geraden am Ort des Maximums (im
# Programm ändern). Bei erster Variante werden also beide Minima auf Null
# geschoben, während bei zweiter Variante die Kurvenform unverändert bleibt.
#
# Anschließend werden Minima und Maximum erneut gesucht, die Halbwertsbreite des
# Peaks bestimmt, das Integral unter der Kurven zwischen den Maxima (oder zwei
# einstellbaren Werten; im Programm ändern) gebildet und alle Werte ausgegeben.

use strict;

my $filenamebase=$ARGV[0];

my $filename=$filenamebase.'.RAW';
my $outname1=$filenamebase.'.clean';
my $outname2=$filenamebase.'.points';
my $outname3=$filenamebase.'.peaks';

my $data=[[[]]];
my $blocknum=0;
my $linenum=0;

#Daten einlesen
open FILE,"<$filename";
while (chomp(my $line=<FILE>)) {
	unless ($line =~ /^#/) {
		if ($line eq "") {
			$blocknum++;
			$linenum=0;
		} else {
			@{$data->[$blocknum]->[$linenum++]}=split"\t",$line;
		}
	}
}
close FILE;

open NEW_DATA_FILE ,">$outname1";
open META_DATA_FILE ,">$outname2";
open OUT_FILE ,">$outname3";
for $blocknum (0..$#{$data}) {
	#Minima finden
	my ($min1,$min2)=find_min($data->[$blocknum]);
	
	#Maximum zwischen Minima finden
	my $max=find_max($data->[$blocknum],$min1,$min2);

	#Höhe des Endes
	my $ende=find_ende_max($data->[$blocknum]);
	
	#Untergrund abziehen
	my $lineslope=($min2->[1]-$min1->[1])/($min2->[0]-$min1->[0]);
	my $line_at_max=$lineslope*$max->[0]+$min1->[1]-$lineslope*$min1->[0];
	for $linenum (0..$#{$data->[$blocknum]}) {
		my ($mag,$vdc,$cond)=@{$data->[$blocknum]->[$linenum]};

		my $lineval=$lineslope*$vdc+$min1->[1]-$lineslope*$min1->[0];

#		gerade abziehen
#		$data->[$blocknum]->[$linenum]->[2]=$cond-$lineval;
#		konst wert abziehen (gerade am maximum)
		$data->[$blocknum]->[$linenum]->[2]=$cond-$line_at_max;
	}

	#Minima nochmal finden
	($min1,$min2)=find_min($data->[$blocknum]);

	#Maximum zwischen neuen Minima nochmal finden
	my $max2=find_max($data->[$blocknum],$min1,$min2);
	
	#Halbwertbreite finden
	my $halfmaxcond=($max2->[1])/2;
	my ($lastcond,$left,$right);
	for $linenum (0..$#{$data->[$blocknum]}) {
		my ($mag,$vdc,$cond)=@{$data->[$blocknum]->[$linenum]};
		if (($vdc>$min1->[0]) && ($vdc<$max2->[0])) {
			if (($cond > $halfmaxcond) && ($lastcond < $halfmaxcond)) {#
				$left->[0]=$vdc;
				$left->[1]=$cond;
			}
		} elsif (($vdc<$min2->[0]) && ($vdc>$max2->[0])) {
			if (($cond < $halfmaxcond) && ($lastcond > $halfmaxcond)) {
				$right->[0]=$vdc;
				$right->[1]=$cond;
			}
		}
		$lastcond=$cond;
	}
	
	#Integral zwischen Minima bilden
	my $integral=integrate($data->[$blocknum],$min1,$min2);
#	$integral=$integral/($min2->[0]-$min1->[0]);
	
	#daten ausgeben
	my $blockmag;
	for $linenum (0..$#{$data->[$blocknum]}) {
		my ($mag,$vdc,$cond)=@{$data->[$blocknum]->[$linenum]};
		$blockmag=$mag;
		print NEW_DATA_FILE "$mag\t$vdc\t$cond\n";
	}
	print NEW_DATA_FILE "\n";

	print META_DATA_FILE "$max2->[0]\t$max2->[1]\n";
	print META_DATA_FILE "$min1->[0]\t$min1->[1]\n";
	print META_DATA_FILE "$min2->[0]\t$min2->[1]\n";
	print META_DATA_FILE "$left->[0]\t$left->[1]\n";
	print META_DATA_FILE "$right->[0]\t$right->[1]\n";
	print META_DATA_FILE "\n";
	
	print OUT_FILE "$blockmag\t$max2->[0]\t$max2->[1]\t",$right->[0]-$left->[0],"\t$integral\t$ende\n";
}
close NEW_DATA_FILE;
close META_DATA_FILE;
close OUT_FILE;

print "\nPlot the corrected data and characteristic points:\n";
printf(qq(plot "%s" using 2:3 every :1::0::%i with lines, "%s" using 1:2 every :1::0::%i\n),$outname1,$#{$data},$outname2,$#{$data});
print "\nPlot the peak height:\n";
printf(qq(plot "%s" using 1:3 with linespoints\n),$outname3);
print "\nPlot the peak width:\n";
printf(qq(plot "%s" using 1:4 with linespoints\n),$outname3);
print "\nPlot the peak center position:\n";
printf(qq(plot "%s" using 1:2 with linespoints\n),$outname3);
print "\nPlot the peak integral:\n";
printf(qq(plot "%s" using 1:5 with linespoints\n),$outname3);
print "\nPlot right side:\n";
printf(qq(plot "%s" using 1:6 with linespoints\n),$outname3);

sub find_min {
	my $data=shift;
	my ($min1,$min2);
	for $linenum (0..$#{$data}) {
		my ($mag,$vdc,$cond)=@{$data->[$linenum]};
		if ($vdc <0) {
			unless ((defined $min1->[1]) && ($min1->[1] < $cond)) {
				$min1->[1]=$cond;
				$min1->[0]=$vdc;
			}
		} else {
			unless ((defined $min2->[1]) && ($min2->[1] < $cond)) {
				$min2->[1]=$cond;
				$min2->[0]=$vdc;
			}
		}
	}
	return ($min1,$min2);
}

sub find_max {
	my ($data,$min1,$min2)=@_;
	my $max;
	for $linenum (0..$#{$data}) {
		my ($mag,$vdc,$cond)=@{$data->[$linenum]};
		if (($vdc > ($min1->[0])) && ($vdc < ($min2->[0]))) {
			unless ((defined $max->[1]) && ($max->[1] > $cond)) {
				$max->[1]=$cond;
				$max->[0]=$vdc;
			}
		}
	}
	return $max;
}

sub find_ende_max {
	my $data=shift;
	my $ende_max;
	for $linenum ($#{$data}-4..$#{$data}) {
		my ($mag,$vdc,$cond)=@{$data->[$linenum]};
		$ende_max+=$cond;
	}
	return($ende_max/5);
}

sub integrate {
	my ($data,$min1,$min2)=@_;
	my $integral;
	for $linenum (0..$#{$data}) {
		my ($mag,$vdc,$cond)=@{$data->[$linenum]};
#		if (($vdc > ($min1->[0])) && ($vdc < ($min2->[0]))) {
		if (($vdc > -0.05) && ($vdc < 0.15)) {
			$integral+=$cond;
		}
	}
	return $integral;
}			
