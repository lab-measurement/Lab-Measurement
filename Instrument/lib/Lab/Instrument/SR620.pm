package Lab::Instrument::SR620;

use strict;
use Lab::Instrument;
use Lab::VISA;
use Time::HiRes qw (usleep);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{vi}=new Lab::Instrument(@_);
	print "The SR620 driver is heavily work in progress and does not work yet. :(";
    return $self
}

# next step: settings for histogram measurement. 
# before readout of data set SR620 like Emiliano in his VisualC-program:
# would be much better to do this in the program and not here...
# I always try to explain what is done with manual page where command is described!


sub init_freq_counter {
    my $self=shift;
    printf "Treiber: initialize SR620 \n";
# anfangs gedacht zum richtigen Kommunzieren PC-SR620, wohl aber nicht nötig dank Davids Änderung
# der C:\Perl\site\lib\Lab\Measurement.pl, wo bei Query eine Auszeit eingefügt wurde, um die Antwort
# des SR abzuwarten, wozu sich der PC wohl vorher zu wenig Zeit gelassen hat. 
    #my $xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR, 0xA);
    #if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while setting read termination character: $xstatus";}
    #
    #$xstatus=Lab::VISA::viSetAttribute($self->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_FALSE);
    #if ($xstatus != $Lab::VISA::VI_SUCCESS) { die "Error while enabling read termination character: $xstatus";}
    
    #$self->{vi}->Clear();
    $self->{vi}->Write(sprintf("*CLS%d\n"));         # clears all status registers p39
    #$self->{vi}->Write("*CLS\n");         # clears all status registers p39
    $self->{vi}->Query("LOCL1\n");
    #printf "Set Auto off\n";
    #$self->{vi}->Write(sprintf("MODE%d\n",0));        # type of operation: time measurement p32
    $self->{vi}->Write(sprintf("AUTM%d\n",0));        # no auto-measurement = no repeat p31 
    $self->{vi}->Write(sprintf("SIZE%d\n",1000));    # number of measurements
    #printf "Treiber: set size 1000 \n";
    #$self->{vi}->Write(sprintf("SRCE%d\n",0));        # set source = start signal to input A, B is end signal in our setup p32
    #$self->{vi}->Write(sprintf("ARMM%d\n",1));        # +time-measurement p31
    #$self->{vi}->Write(sprintf("GSCL%d\n",2,250));   # set graph scale to histogram and 250 bins p35
    #$self->{vi}->Write(sprintf("DREL%d\n",1));        # set display resolution to REL ?? p32
    #$self->{vi}->Write(sprintf("*AUTS%d\n"));         # autoscale graph p35
 #   $self->{vi}->Write("SRCE0\n");        # set source = start signal to input A, B is end signal in our setup p32
 #   $self->{vi}->Write("ARMM1\n");        # +time-measurement p31
 #   $self->{vi}->Write("GSCL 2,250\n");   # set graph scale to histogram and 250 bins p35
 #   $self->{vi}->Write("DREL1\n");        # set display resolution to REL ?? p32
 #   $self->{vi}->Write("AUTS\n");         # autoscale graph p35
    printf "init done\n";
}

# some additional change to the number of measurements
sub set_histo{
    my $self=shift;
    my $numhisto=shift;
    printf "set size %d \n",$numhisto;
    $self->{vi}->Write(sprintf("SIZE%d\n",$numhisto));     # number of measurements
    
    printf "done!, $numhisto \n";
    
}

# this starts one measurement
sub start_measurement{
    my $self=shift;
    #my $duration=shift;
   # printf "Treiber: starte Messung, wait time $duration seconds\n";
    $self->{vi}->Write(sprintf("STRT\n"));     # startet die Messung
    #usleep(150000);
    #printf "done!\n";    
}

# start of measurement section: different kinds of readouts:
sub measure {
    
    # get meas?0-value, so the mean of the measurement
    my $self = shift;
    my $tmp=$self->{vi}->Query(sprintf("MEAS?%d\n",0));
    #printf "$tmp";
    chomp $tmp;
    return $tmp;
}

# start of measurement section: different kinds of readouts:
sub read_mean {
    
    # get XAVG-value, so the mean of the measurement
    my $self = shift;
    usleep(1000);
    my $tmp=$self->{vi}->Query(sprintf("XAVG?\n"));
  #  my $tmp=$self->{vi}->Query("XAVG?\n");         # old try, not working
    #printf "$tmp";
    return $tmp;
}

sub read_measure {

    # get all the important values of the measurement, except for full histogram
    my $self=shift;
      
    my $tmpall=$self->{vi}->Query(sprintf("XALL?\n"));   
  #  my $tmpall=$self->{vi}->Query("XALL?\n");      # old try, not working
    printf "$tmpall";
    return $tmpall;
}

# funktionniert noch nicht! Bricht mittendrin ab, trotz viel Verbessern!
#sub read_histo {
#
#    my $self=shift;
#    print "Treiber:Start Histogramm\n";
#    my $temp;
#    for(my $j=1;$j<=250;$j++){ 
#
#        #my $q = "HSPT?$j";
#        #print "query string \'$q\' ";
#        
#        $temp=$self->{vi}->Query(sprintf("HSPT?%d\n",$j));
# #       my $temp=$self->{vi}->Query("$q\n");
#      #  usleep(100);
#       chomp $temp;
#        print "$j gives \'$temp\'\n";
#    };
#    print "Treiber: histo fertig \n";
#    return $temp;
#}

# funktionniert noch nicht! Die Ausgabe als array stimmt noch nicht sowie
# die Ausgabe als 4byte binary integer ist nicht berücksichtigt.
#sub read_histodisplay {
#
#    my $self = shift;
#    my @temp=[];
#    print "Treiber:Start Histodisplay\n";
#    
#    for(my $j=0;$j<=9;$j++){ 
#
#        #my $q = "XHST?$j";
#        #print "query string \'$q\' ";
#        
#        $temp[$j]=$self->{vi}->Query(sprintf("XHST?%d\n",$j));
# #       my $temp=$self->{vi}->Query("$q\n");
#        usleep(100);
#        #chomp $temp[$j];
#        print "gives \'$temp[$j]\'\n";
#    };
#    return @temp;
#    print "Treiber: histo fertig \n";
#}

# jetzt die Funktion, die wir eigentlich brauchen, um die vollen Daten auszulesen:
# bdmpj, den binary dump mode, der alle Daten einer Einzelmessung ausspuckt.
# leider funktionniert auch das nicht... Zudem müssen die ausgegebenen binary data
# umgewandelt werden wie auf S. 34 des Handbuchs beschrieben.

sub read_bdmp {
 
    my $self = shift;
    $self->{vi}->Write(sprintf("LOCL%d\n",1));
    my @result;
    my $numhisto=shift;
        $self->{vi}->Write(sprintf("BDMP%d\n",$numhisto));     # number of measurements
	for (my $j=0;$j<$numhisto;$j++){
	my $tmp0=$self->{vi}->BrutalRead(8);
	#print "\n$tmp0\n";
	my @tmp=unpack("b8b8",$tmp0);#b*
	my $tmp2= bin2dec($tmp[1]);
	print "\ntmp2=$tmp2\n";
	push(@result,@tmp);
	print "\n@tmp\n";
  }
    return @result;
    print "Treiber: bdmp fertig \n";

}

sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub remoteend {
    my $self=shift;
  #  $self->{vi}->Query("LOCL0");
}

1;


=head1 NAME

Lab::Instrument::SR620 - Stanford Research 620 Frequency Counter

=head1 CAVEATS/BUGS

This driver is heavily work in progress and does not work yet. :(

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2009 Tom Geiger and Andreas K. Hüttel (L<http://www.akhuettel.de/>)

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut


