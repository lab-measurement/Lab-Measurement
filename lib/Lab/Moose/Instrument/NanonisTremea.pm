package Lab::Moose::Instrument::NanonisTremea;

use v5.20;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Carp;
use namespace::autoclean;

use Lab::Moose::Instrument qw/     
    validated_getter validated_setter setter_params /;


extends 'Lab::Moose::Instrument';


sub nt_string {
  my $s = shift;
  return (pack "N", length($s)) . $s;
}

sub nt_int {
  my $i = shift;
  return pack "N!", $i;
}

sub nt_uint16 {
  my $i = shift;
  return pack "n", $i;
}

sub nt_uint32 {
  my $i = shift;
  return pack "N", $i;
}


sub nt_float32 {
  my $f = shift;
  return pack "f>", $f;
}

sub nt_float64 {
  my $f = shift;
  return pack "d>", $f;
}

sub returnFormatter {
    my $expBody= shift;
    my $body= shift;
    my $diff = $expBody - (length($body)-40);
    my $padding;
    if ($diff!=0){
        $padding = "\0"x $diff;
      }
    $body=$body.$padding;
    return $body;
}

sub  nt_header {
    my ($self,$command,$b_size,$response) =@_;
    
    $command = lc($command);

    my ($pad_len) = 32 - length($command);
   
    my($template)="A".length($command);

    for (1..$pad_len){

        $template=$template."x"
    }
    my $cmd= pack($template,$command);
    my $bodysize= nt_int($b_size);
    my $rsp= nt_uint16($response);
    return $cmd.$bodysize.$rsp.nt_uint16(0);
}

sub strArrayUnpacker {
    my ($self, $elementNum, $strArray) = @_;
    my $position = 0;
    my %unpckStrArray;
  for(0..$elementNum-1){
      my $strlen = unpack("N!",substr $strArray,$position,4);
      $position+=4;
      my $string =  substr $strArray,$position,$strlen;
      $position+=$strlen;
      $unpckStrArray{$_}=$string;
  }
  return %unpckStrArray;
}

sub intArrayUnpacker {
  my ($self,$elementNum,$intArray) = @_;
  my $position = 0;
  my @intArray;
  for(0...$elementNum-1){
    my $int = unpack("N!", substr $intArray,$position,4);
    push @intArray, $int;
    $position+=4;
  }

  return @intArray;
}





=head1 1DSweep
=cut






sub oneDSwp_AcqChsSet { 
    my $self = shift;
    my @channels; 
    foreach(@_){
        push @channels,$_;
    }
    my $command_name="1dswp.acqchsset";
    my $bodysize= (2 + $#channels)*4;
    my $head= $self->nt_header($command_name,$bodysize,0);
    #Create body
    my $body= nt_int($#channels+1);
    foreach(@channels){
        $body= $body.nt_int($_);
    }
    $self->write(command=>$head.$body);
}


sub oneDSwp_AcqChsGet {
    #######not working for some reason
    my $self = shift;
    my $command_name="1dswp.acqchsget";
    my $bodysize = 0;
    my $head= $self->nt_header($command_name,$bodysize,1);
    $self->write(command=>$head);

    my $return = $self->read();
    #my $channelNum = unpack("N!",substr $return,40,4);
    print(length($return));
    #my @channels = $self->intArrayUnpacker($channelNum,(substr $return,44));
    #print(join(",",@channels));
}

sub oneDSwp_SwpSignalSet {
    my ($self, $channelName) = @_;
    my $strlen = length($channelName);
    my $command_name="1dswp.swpsignalset";
    my $bodysize = $strlen+4;
    $strlen=nt_int($strlen);
    my $head= $self->nt_header($command_name,$bodysize,0);
    $self->write(command=>$head.$strlen.$channelName);
    sleep(1);
}

sub oneDSwp_SwpSignalGet {
    my $self = shift;
    my $option= "select";
    $option = shift if (scalar(@_)>0);
    my $command_name="1dswp.swpsignalget";
    my $head= $self->nt_header($command_name,0,1);
    $self->write(command=>$head);
    my $response = $self->read();
    my $strlen= unpack("N!",substr $response,40,4);

    if (($option eq "select") == 1){
        my $selected = substr $response,44,$strlen;
        print($selected,"\n");
    }
    elsif (($option eq "info")==1){
      my $elementNum = unpack("N!", substr $response,48+$strlen,4);
      my $strArray= substr $response,52+$strlen;
      my %channels = $self->strArrayUnpacker($elementNum,$strArray);
      return %channels;
    }
    else{
      return "Invalid Options!"
    }


     

}

sub oneDSwp_LimitsSet {
  my $self = shift;
  my ($Lower_limit,$Upper_limit,)= @_;
  my $command_name= "1dswp.limitsset";
  my $bodysize = 8;
  my $head = $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Lower_limit);
  $body=$body.nt_float32($Upper_limit);
  $self->write(command=>$head.$body)
}

sub oneDSwp_LimitsGet {
  my $self = shift;
  my $command_name= "1dswp.limitsget";
  my $bodysize = 0;
  my $rbodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read();
  $return= returnFormatter($rbodysize,$return);
  my $Lower_limit= substr $return,40,4;
  $Lower_limit= unpack("f>",$Lower_limit);
  my $Upper_limit= substr $return,44,4;
  $Upper_limit= unpack("f>",$Upper_limit);
  return($Lower_limit,$Upper_limit);
  
}

sub oneDSwp_PropsSet {
  my $self = shift;
  my ($Initial_Settling_time_ms,$Maximum_slew_rate,$Number_of_steps,$Period_ms,$Autosave,$Save_dialog_box,$Settling_time_ms)= @_;
  my $command_name= "1dswp.propsset";
  my $bodysize = 26;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_Settling_time_ms);
  $body=$body.nt_float32($Maximum_slew_rate);
  $body=$body.nt_int($Number_of_steps);
  $body=$body.nt_uint16($Period_ms);
  $body=$body.nt_int($Autosave);
  $body=$body.nt_int($Save_dialog_box);
  $body=$body.nt_float32($Settling_time_ms);
  $self->write(command=>$head.$body);
}

sub oneDSwp_PropsGet {
  my $self = shift;
  my $command_name= "1dswp.propsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);

  my $return = $self->binary_read(); 
  my $rbodysize = 26;
  $return= returnFormatter($rbodysize,$return);
  my $Initial_Settling_time_ms= substr $return,40,4;
  $Initial_Settling_time_ms= unpack("f>",$Initial_Settling_time_ms);
  my $s= substr $return,44,4;
  $s= unpack("f>",$s);
  my $Number_of_steps= substr $return,48,4;
  $Number_of_steps= unpack("N!",$Number_of_steps);
  my $Period_ms= substr $return,52,2;
  $Period_ms= unpack("n",$Period_ms);
  my $Autosave= substr $return,54,4;
  $Autosave= unpack("N",$Autosave);
  my $Save_dialog_box= substr $return,58,4;
  $Save_dialog_box= unpack("N",$Save_dialog_box);
  my $Settling_time_ms= substr $return,62,4;
  $Settling_time_ms= unpack("f>",$Settling_time_ms);
  return($Initial_Settling_time_ms,$s,$Number_of_steps,$Period_ms,$Autosave,$Save_dialog_box,$Settling_time_ms);
}

sub oneDSwp_Start {
     my ($self,$get,$direction,$name,$reset,$timeout) = @_;
     my $command_name= "1dswp.start";
     my $name_len= length($name);
     my $bodysize = 16 +$name_len;
     
     $get = 1 if $get != 0;
     $direction = 1 if $direction != 0;
     $reset = 1 if $reset != 0;
     my $head= $self->nt_header($command_name,$bodysize,$get);
     my $body = nt_uint32($get);
     $body = $body.nt_uint32($direction);
     $body = $body.nt_int($name_len);
     $body = $body.$name;
     $body = $body.nt_uint32($reset);
     $self->write(command=>$head.$body);

    if($get==1){
        my $return = $self->binary_read(timeout=>$timeout);
        my $channelSize = unpack("N!",substr($return,40,4));
        my $channelNum =unpack("N!",substr($return,44,4));
        my %channels = $self->strArrayUnpacker($channelNum,substr($return,48,$channelSize));
        $channels{0}=$channels{0}."*";
        my $newPos = 48 +$channelSize;
        my $rowNum = unpack("N!",substr($return,$newPos,4));
        my $colNum = unpack("N!",substr($return,$newPos+4,4));
        my $rawData = substr($return,$newPos+8,$rowNum*$colNum*4);
        my %data;
        my $pos = 0;
        for(my $row = 0;$row<$rowNum;$row++){
          my @rowBuffer;
          for(my $col = 0;$col<$colNum;$col++){
            push  @rowBuffer , unpack("f>",substr($rawData,$pos,4));
            $pos +=4;
          }
          #print("$channels{$row}:".join(",",@rowBuffer)."\n");
          $data{$channels{$row}} = [@rowBuffer];
        }
        return %data;
    }
    else{
      print("Sweep Started.");
      return 0;
    }






}

sub oneDSwp_Stop {
  my $self = shift;
  my $command_name= "1dswp.stop";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}


sub oneDSwp_Open {
  my $self = shift;
  my $command_name= "1dswp.open";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}






=head1 3DSwp
=cut 



sub threeDSwp_AcqChsSet {
  my $self = shift;
  my $Number_of_Channels= shift;
  my $command_name = "3dswp.acqchsset";
  my $bodysize = 4*($Number_of_Channels+1);
  my $header = $self->nt_header($command_name,$bodysize,0);
  my $body = nt_int($Number_of_Channels);
  while(scalar(@_)!=0){
    $body =$body.nt_int(shift);
  }
  $self->write(command=>$header.$body);
}

sub threeDSwp_AcqChsGet {

  my $self = shift;
  my $command_name = "3dswp.acqchsget";
  $self->write(command=>$self->nt_header($command_name,0,1));

  my $return= $self->binary_read();
  my $Number_of_Channels = unpack("N!", substr($return,40,4));
  my $pos = 4*($Number_of_Channels);
  my @indexes = $self->intArrayUnpacker($Number_of_Channels,substr($return,44,$pos));
  $pos +=44;
  my $Channel_names_size = unpack("N!",substr($return,$pos,4));
  my $Channel_num = unpack("N!",substr($return,$pos+4,4));
  my %names = $self->strArrayUnpacker($Channel_num,substr($return,$pos+8,$Channel_names_size));
  my %combined;

  for(my $idx = 0; $idx<scalar(@indexes);$idx++){
      $combined{$indexes[$idx]}=$names{$idx} 
  }
  return(%combined);
}

sub threeDSwp_SaveOptionsSet {
    my $self = shift ;
    my $Series_Name = shift;
    my $DT_Folder_opt = shift;
    my $Comment = shift;
    my @Module_Names = @_ ;

    print(join(",",@Module_Names)."\n");

}

sub threeDSwp_Start {
  my $self = shift;
  my $command_name= "3dswp.start";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}

sub threeDSwp_Stop {
  my $self = shift;
  my $command_name= "3dswp.stop";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}

sub threeDSwp_Open {
  my $self = shift;
  my $command_name= "3dswp.open";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}

sub threeDSwp_StatusGet {
  my $self = shift;
  my $command_name= "3dswp.statusget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Status= substr $return,40,4;
  $Status= unpack("N",$Status);
  return($Status);
}

=head2 3DSwp.SwpChannel
=cut

sub threeDSwp_SwpChSignalSet {
  my $self = shift;
  my $Sweep_channel_index = shift;
  my $command_name= "3dswp.swpchsignalset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head.nt_int($Sweep_channel_index));
}

sub threeDSwp_SwpChLimitsSet {
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.swpchlimitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
}

sub threeDSwp_SwpChLimitsGet {
  my $self = shift;
  my $command_name= "3dswp.swpchlimitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Start= substr $return,40,4;
  $Start= unpack("f>",$Start);
  my $Stop= substr $return,44,4;
  $Stop= unpack("f>",$Stop);
  return($Start,$Stop);
}

sub threeDSwp_SwpChPropsSet {
  my $self = shift;
  my ($Number_of_points,$Number_of_sweeps,$Backward_sweep,$End_of_sweep_action,$End_of_sweep_arbitrary_value,$Save_all)= @_;
  my $command_name= "3dswp.swpchpropsset";
  my $bodysize = 24;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Number_of_points);
  $body=$body.nt_int($Number_of_sweeps);
  $body=$body.nt_int($Backward_sweep);
  $body=$body.nt_int($End_of_sweep_action);
  $body=$body.nt_float32($End_of_sweep_arbitrary_value);
  $body=$body.nt_int($Save_all);
  $self->write(command=>$head.$body);
}

sub threeDSwp_SwpChPropsGet {
  my $self = shift;
  my $command_name= "3dswp.swpchpropsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Number_of_points= substr $return,40,4;
  $Number_of_points= unpack("N!",$Number_of_points);
  my $Number_of_sweeps= substr $return,44,4;
  $Number_of_sweeps= unpack("N!",$Number_of_sweeps);
  my $Backward_sweep= substr $return,48,4;
  $Backward_sweep= unpack("N",$Backward_sweep);
  my $End_of_sweep_action= substr $return,52,4;
  $End_of_sweep_action= unpack("N",$End_of_sweep_action);
  my $End_of_sweep_arbitrary_value= substr $return,56,4;
  $End_of_sweep_arbitrary_value= unpack("f>",$End_of_sweep_arbitrary_value);
  my $Save_all= substr $return,60,4;
  $Save_all= unpack("N",$Save_all);
  return($Number_of_points,$Number_of_sweeps,$Backward_sweep,$End_of_sweep_action,$End_of_sweep_arbitrary_value,$Save_all);
}

sub threeDSwp_SwpChTimingSet {
  my $self = shift;
  my ($Initial_settling_time_s,$Settling_time_s,$Integration_time_s,$End_settling_time_s,$Maximum_slw_rate)= @_;
  my $command_name= "3dswp.swpchtimingset";
  my $bodysize = 20;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($Settling_time_s);
  $body=$body.nt_float32($Integration_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($Maximum_slw_rate);
  $self->write(command=>$head.$body);
}

sub threeDSwp_SwpChTimingGet {
  my $self = shift;
  my $command_name= "3dswp.swpchtimingget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Initial_settling_time_s= substr $return,40,4;
  $Initial_settling_time_s= unpack("f>",$Initial_settling_time_s);
  my $Settling_time_s= substr $return,44,4;
  $Settling_time_s= unpack("f>",$Settling_time_s);
  my $Integration_time_s= substr $return,48,4;
  $Integration_time_s= unpack("f>",$Integration_time_s);
  my $End_settling_time_s= substr $return,52,4;
  $End_settling_time_s= unpack("f>",$End_settling_time_s);
  my $Maximum_slw_rate= substr $return,56,4;
  $Maximum_slw_rate= unpack("f>",$Maximum_slw_rate);
  return($Initial_settling_time_s,$Settling_time_s,$Integration_time_s,$End_settling_time_s,$Maximum_slw_rate);
}

sub threeDSwp_SwpChModeSet {
  my $self = shift;
  my $Channel_name = shift;
  my $name_len = length($Channel_name);
  my $bodysize = 4*($name_len+1);
  my $command_name = "3dswp.swpchmodeset";
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head.nt_int($name_len).$Channel_name);
}

sub threeDSwp_SwpChModeGet {
  my $self = shift;
  my $command_name = "3dswp.swpchmodeget";
  my $head = $self->nt_header($command_name,0,1);
  $self->write(command=>$head);
  my $return= $self->binary_read();
  return substr($return,44,unpack("N!",substr($return,40,4)));
}

=head2 3DSwp.StepChanne1
=cut

sub threeDSwp_StpCh1SignalSet {
  my $self = shift;
  my $Step_channel_1_index = shift;
  my $command_name= "3dswp.stpch1signalset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head.nt_int($Step_channel_1_index));
}

sub threeDSwp_StpCh1LimitsSet {
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.stpch1limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
}

sub threeDSwp_StpCh1LimitsGet {
  my $self = shift;
  my $command_name= "3dswp.stpch1limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Start= substr $return,40,4;
  $Start= unpack("f>",$Start);
  my $Stop= substr $return,44,4;
  $Stop= unpack("f>",$Stop);
  return($Start,$Stop);
}

sub threeDSwp_StpCh1PropsSet {
  my $self = shift;
  my ($Number_of_points,$Backward_sweep,$End_of_sweep_action,$End_of_sweep_arbitrary_value)= @_;
  my $command_name= "3dswp.stpch1propsset";
  my $bodysize = 16;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Number_of_points);
  $body=$body.nt_int($Backward_sweep);
  $body=$body.nt_int($End_of_sweep_action);
  $body=$body.nt_float32($End_of_sweep_arbitrary_value);
  $self->write(command=>$head.$body);
}

sub threeDSwp_StpCh1PropsGet {
  my $self = shift;
  my $command_name= "3dswp.stpch1propsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Number_of_points= substr $return,40,4;
  $Number_of_points= unpack("N!",$Number_of_points);
  my $Backward_sweep= substr $return,44,4;
  $Backward_sweep= unpack("N",$Backward_sweep);
  my $End_of_sweep_action= substr $return,48,4;
  $End_of_sweep_action= unpack("N",$End_of_sweep_action);
  my $End_of_sweep_arbitrary_value= substr $return,52,4;
  $End_of_sweep_arbitrary_value= unpack("f>",$End_of_sweep_arbitrary_value);
  return($Number_of_points,$Backward_sweep,$End_of_sweep_action,$End_of_sweep_arbitrary_value);
}

sub threeDSwp_StpCh1TimingSet {
  my $self = shift;
  my ($Initial_settling_time_s,$End_settling_time_s,$Maximum_slw_rate)= @_;
  my $command_name= "3dswp.stpch1timingset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($Maximum_slw_rate);
  $self->write(command=>$head.$body);
}

sub threeDSwp_StpCh1TimingGet {
  my $self = shift;
  my $command_name= "3dswp.stpch1timingget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Initial_settling_time_s= substr $return,40,4;
  $Initial_settling_time_s= unpack("f>",$Initial_settling_time_s);
  my $End_settling_time_s= substr $return,44,4;
  $End_settling_time_s= unpack("f>",$End_settling_time_s);
  my $Maximum_slw_rate= substr $return,48,4;
  $Maximum_slw_rate= unpack("f>",$Maximum_slw_rate);
  return($Initial_settling_time_s,$End_settling_time_s,$Maximum_slw_rate);
}

=head2 3DSwp.StepChannel2
=cut

sub threeDSwp_StpCh2SignalSet {
  my $self = shift;
  my $Channel_name = shift;
  my $name_len = length($Channel_name);
  my $bodysize = 4*($name_len+1);
  my $command_name = "3dswp.stpch2signalset";
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head.nt_int($name_len).$Channel_name);
}

sub threeDSwp_StpCh2SignalGet {
  my $self = shift;
  my $command_name = "3dswp.stpch2signalget";
  my $head = $self->nt_header($command_name,0,1);
  $self->write(command=>$head);
  my $return= $self->binary_read();
  return substr($return,44,unpack("N!",substr($return,40,4)));
}

sub threeDSwp_StpCh2LimitsSet {
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.stpch2limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
}

sub threeDSwp_StpCh2LimitsGet {
  my $self = shift;
  my $command_name= "3dswp.stpch2limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Start= substr $return,40,4;
  $Start= unpack("f>",$Start);
  my $Stop= substr $return,44,4;
  $Stop= unpack("f>",$Stop);
  return($Start,$Stop);
}

sub threeDSwp_StpCh2PropsSet {
  my $self = shift;
  my ($Number_of_points,$Backward_sweep,$End_of_sweep_action,$End_of_sweep_arbitrary_value)= @_;
  my $command_name= "3dswp.stpch2propsset";
  my $bodysize = 16;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Number_of_points);
  $body=$body.nt_int($Backward_sweep);
  $body=$body.nt_int($End_of_sweep_action);
  $body=$body.nt_float32($End_of_sweep_arbitrary_value);
  $self->write(command=>$head.$body);
}

sub threeDSwp_StpCh2PropsGet {
  my $self = shift;
  my $command_name= "3dswp.stpch2propsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Number_of_points= substr $return,40,4;
  $Number_of_points= unpack("N!",$Number_of_points);
  my $Backward_sweep= substr $return,44,4;
  $Backward_sweep= unpack("N",$Backward_sweep);
  my $End_of_sweep_action= substr $return,48,4;
  $End_of_sweep_action= unpack("N",$End_of_sweep_action);
  my $End_of_sweep_arbitrary_value= substr $return,52,4;
  $End_of_sweep_arbitrary_value= unpack("f>",$End_of_sweep_arbitrary_value);
  return($Number_of_points,$Backward_sweep,$End_of_sweep_action,$End_of_sweep_arbitrary_value);
}

sub threeDSwp_StpCh2TimingSet {
  my $self = shift;
  my ($Initial_settling_time_s,$End_settling_time_s,$Maximum_slw_rate)= @_;
  my $command_name= "3dswp.stpch2timingset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($Maximum_slw_rate);
  $self->write(command=>$head.$body);
}

sub threeDSwp_StpCh2TimingGet {
  my $self = shift;
  my $command_name= "3dswp.stpch2timingget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Initial_settling_time_s= substr $return,40,4;
  $Initial_settling_time_s= unpack("f>",$Initial_settling_time_s);
  my $End_settling_time_s= substr $return,44,4;
  $End_settling_time_s= unpack("f>",$End_settling_time_s);
  my $Maximum_slw_rate= substr $return,48,4;
  $Maximum_slw_rate= unpack("f>",$Maximum_slw_rate);
  return($Initial_settling_time_s,$End_settling_time_s,$Maximum_slw_rate);
}

=head2 3DSwp.Timing
=cut

sub threeDSwp_TimingRowLimitSet {
  #Everythinbg seems set properlly, wierd Behavior on nanonis Software side.
  my $self = shift;
  my ($Row_index,$Maximum_time_seconds,$Channel_index)= @_;
  my $command_name= "3dswp.timingrowlimitset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Row_index);
  $body=$body.nt_int($Maximum_time_seconds); #Gets translated to int software side..I don't know,should be f32.
  $body=$body.nt_int($Channel_index);
  $self->write(command=>$head.$body);
}

sub threeDSwp_TimingRowLimitGet {
  my $self = shift;
  my $Row_index = shift;
  my $command_name= "3dswp.timingrowlimitget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head.nt_int($Row_index));

  my $return = $self->binary_read();
  my $Maximum_time= unpack("f>",substr($return,40,4));
  my $Channel_index = unpack("N!",substr($return,44,4));
  my $Channel_names_size = unpack("N!",substr($return,48,4));
  my $Channel_num= unpack("N!",substr($return,52,4));
  my $strArray = substr $return,56,$Channel_names_size;
  my %channels = $self->strArrayUnpacker($Channel_num,$strArray);

  return($Maximum_time,$Channel_index,%channels);
}

sub threeDSwp_TimingRowMethodsSet {
  my $self = shift;
  my ($Row_index,$Method_lower,$Method_middle,$Method_upper,$Method_alternative)= @_;
  my $command_name= "3dswp.timingrowmethodsset";
  my $bodysize = 20;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Row_index);
  $body=$body.nt_int($Method_lower);
  $body=$body.nt_int($Method_middle);
  $body=$body.nt_int($Method_upper);
  $body=$body.nt_int($Method_alternative);
  $self->write(command=>$head.$body);
}

sub threeDSwp_TimingRowMethodsGet {
  my $self = shift;
  my ($Row_index)= @_;
  my $command_name= "3dswp.timingrowmethodsget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Row_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Method_lower= substr $return,40,4;
  $Method_lower= unpack("N!",$Method_lower);
  my $Method_middle= substr $return,44,4;
  $Method_middle= unpack("N!",$Method_middle);
  my $Method_upper= substr $return,48,4;
  $Method_upper= unpack("N!",$Method_upper);
  my $Method_alternative= substr $return,52,4;
  $Method_alternative= unpack("N!",$Method_alternative);
  return($Method_lower,$Method_middle,$Method_upper,$Method_alternative);
}


sub threeDSwp_TimingRowValsSet {
  #The documentation indicates that this function requires float32 input but actually gets f64 
  my $self = shift;
  my ($Row_index,$MR_from,$LR_value,$MR_value,$MR_to,$UR_value,$AR_value)= @_;
  my $command_name= "3dswp.timingrowvalsset";
  my $bodysize = 52;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Row_index);
  $body=$body.nt_float64($MR_from);
  $body=$body.nt_float64($LR_value);
  $body=$body.nt_float64($MR_value);
  $body=$body.nt_float64($MR_to);
  $body=$body.nt_float64($UR_value);
  $body=$body.nt_float64($AR_value);
  $self->write(command=>$head.$body);
  # my $return = $self->binary_read();
  # print($return."\n");
}

sub threeDSwp_TimingRowValsGet {
  #The documentation indicates that this function returns float32 but actually returns f64 
  my $self = shift;
  my ($Row_index)= @_;
  my $command_name= "3dswp.timingrowvalsget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Row_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $MR_from= unpack("d>",substr($return,40,8));
  my $LR_value = unpack("d>",substr($return,48,8));
  my $MR_value = unpack("d>",substr($return,56,8));
  my $MR_to = unpack("d>",substr($return,64,8));
  my $UR_value = unpack("d>",substr($return,72,8));
  my $AR_value = unpack("d>",substr($return,80,8));
  print(unpack("d>",substr($return,88,8))."\n");
  return($MR_from,$LR_value,$MR_value,$MR_to,$UR_value,$AR_value);

}

sub threeDSwp_TimingEnable {
  my $self = shift;
  my ($Enable)= @_;
  my $command_name= "3dswp.timingenable";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint32($Enable);
  $self->write(command=>$head.$body);
}

sub threeDSwp_TimingSend {
  my $self = shift;
  my $command_name= "3dswp.timingsend";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
=head1 Signals
=cut





sub Signals_MeasNamesGet {
  my $self = shift;
  my $command_name= "signals.measnamesget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $response = $self->read();
  my $channelSize= unpack("N!",substr $response,40,4);
  my $channelNum= unpack("N!",substr $response,44,4);
  # print($channelSize,"\n");
  # print($channelNum,"\n");
  my $strArray = substr $response,48,$channelSize;
  my %channels = $self->strArrayUnpacker($channelNum,$strArray);
  return %channels;
}




__PACKAGE__->meta()->make_immutable();

1;