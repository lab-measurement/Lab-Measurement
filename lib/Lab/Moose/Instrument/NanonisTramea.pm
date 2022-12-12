package Lab::Moose::Instrument::NanonisTramea;

#ABSTRACT: Nanonis Tramea

use v5.20;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Carp;
use PDL::Core;
use PDL::IO::CSV ":all";
use List::Util qw(max);
use Lab::Moose::Instrument qw/
    validated_getter validated_setter/;
extends 'Lab::Moose::Instrument';

use namespace::autoclean;
=encoding utf8

=head1 SYNOPSIS

 my $tramea = instrument(
     type => 'NanonisTramea',
     connection_type => 'Socket',
     connection_options => { host => '000.000.000.00',
                             port => '0000',
                             write_termchar => ''
                            }
 );


=cut

=head1 FORMATTERS
Collections of functions to pack or unpack numbers and srings for TCP comunication
=cut


=head2 nt_string
=cut
sub nt_string {
  my $s = shift;
  return (pack "N", length($s)) . $s;
}

=head2 nt_int
=cut
sub nt_int {
  my $i = shift;
  return pack "N!", $i;
}

=head2 nt_uint16
=cut
sub nt_uint16 {
  my $i = shift;
  return pack "n", $i;
}

=head2 nt_uint32
=cut
sub nt_uint32 {
  my $i = shift;
  return pack "N", $i;
}

=head2 nt_float32
=cut
sub nt_float32 {
  my $f = shift;
  return pack "f>", $f;
}

=head2 nt_float64
=cut
sub nt_float64 {
  my $f = shift;
  return pack "d>", $f;
}

=head2 nt_header

    my $header =  $tramea->nt_header($command,$body_size,$response);

  Function to format Header of tcp message.
  C<command> refers to command name as reported in the Nanonis Tramea documentation
  C<body_size> refers to the size of the message body, not including the header itself.
  C<response> Must have value of either 0 or 1. If value is the nanonis Software will send a response according to documentation.

=cut

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

=head2 _end_of_com

=cut

sub _end_of_com
{
  my $self = shift;
  my $response = $self->binary_read();
  my $response_bodysize = unpack("N!",substr($response,36,4));
  if($response_bodysize>0)
  {
    print(substr($response,40,$response_bodysize)."\n");
    die  "(Proto) Error returned by nanonis software"
  }
  return $response
}

=head2 strArrayUnpacker

  my %strArray = $tramea->strArrayUnpacker($element_number, $string_array);

Returns an hash that has as keys the indexes of the strings in the array and as items the strings themselves.
C<element_number> refers to the ammount of strings about to be in the array.
C<string_array> refers to the binary of the strings array.

=cut

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

=head2 intArrayUnpacker

  my @int_array = $tramea->intArrayUnpacker($element_number, $int_array);

Unpacks binary array of int and returns into perl Array type.
C<element_number> refers to the expected number of elements in the array.
C<int_array> refers to the int array binary.

=cut
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

=head2 float32ArrayUnpacker

  my $floeat32_array = $tramea->float32ArrayUnpacker($element_number, $float32_array);

Unpacks binary array of float32 and returns into perl Array type.
C<element_number> refers to the expected number of elements in the array.
C<float32_array> refers to float32 array binary.

=cut
sub float32ArrayUnpacker {
  my ($self,$elementNum,$Array) = @_;
  my $position = 0;
  my @floatArray;
  for(0...$elementNum-1){
    my $float = unpack("f>", substr $Array,$position,4);
    push @floatArray, $float;
    $position+=4;
  }

  return @floatArray;
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
    my $self = shift;
    my $command_name="1dswp.acqchsget";
    my $bodysize = 0;
    my $head= $self->nt_header($command_name,$bodysize,1);
    $self->write(command=>$head);

    my $return = $self->binary_read();
    my $channelNum = unpack("N!",substr $return,40,4);
    my @channels = $self->intArrayUnpacker($channelNum,(substr $return,44));
    return(@channels);
}

sub oneDSwp_SwpSignalSet {
    my ($self, $channelName) = @_;
    my $strlen = length($channelName);
    my $command_name="1dswp.swpsignalset";
    my $bodysize = $strlen+4;
    $strlen=nt_int($strlen);
    my $head= $self->nt_header($command_name,$bodysize,1);
    $self->write(command=>$head.$strlen.$channelName);
}

sub oneDSwp_SwpSignalGet {
    my $self = shift;
    my $option= "select";
    if (scalar(@_)>0){
      $option = shift;
    }
    my $command_name="1dswp.swpsignalget";
    my $head= $self->nt_header($command_name,0,1);
    $self->write(command=>$head);
    my $response = $self->binary_read();
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
  my $return = $self->binary_read();
  $return = $self->binary_read();
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
  
  if($get!= 0){
   $get = 1;
  }
  if($direction!= 0){
   $direction = 1; 
  }
  if($reset!= 0){
   $reset = 1; 
  }
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
    for(my $row = 0;$row<$rowNum;$row++)
    {
      my @rowBuffer;
      for(my $col = 0;$col<$colNum;$col++)
      {
        push  @rowBuffer , unpack("f>",substr($rawData,$pos,4));
        $pos +=4;
      }
      $data{$channels{$row}} = [@rowBuffer];
    }
    return %data;
    }
    else{
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
  my $channels_ref = shift;
  my @channels = @{$channels_ref};
  my $Number_of_Channels= scalar @channels;
  my $command_name = "3dswp.acqchsset";
  my $bodysize = 4*($Number_of_Channels+1);
  my $header = $self->nt_header($command_name,$bodysize,1);
  my $body = nt_int($Number_of_Channels);
  for(my $i = 0;$i<$Number_of_Channels;$i++)
  {
    $body=$body.nt_int($channels[$i]);
  }
  $self->write(command=>$header.$body);
  $self->_end_of_com();
  #This sleep here solves "some issue" with threeDSwp_AcqChsSet, 
  #even if it sends a response baclo, software bhaves wierdly if another command is sent too soon
  #sleep(0.1);

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
  my $self = shift;
  my $Series_Name= shift;
  my $Create_Date_Time =shift;
  my $Comment = shift;
  my @Modules_Names= ();
  if(scalar(@_) >0)
  {
    my $Modules_Names_ref = shift;
    @Modules_Names = @{$Modules_Names_ref};
  }
  my $command_name = "3dswp.saveoptionsset";
  my $bodysize = 20;
  my $body = nt_int(0);
  if(length($Series_Name)!=0)
  {
    $body=nt_int(length($Series_Name));
    $body=$body.$Series_Name;
    $bodysize+=length($Series_Name);
  }
  if($Create_Date_Time >0)
  {
    $Create_Date_Time =1;
  }
  elsif ($Create_Date_Time<0)
  {
    $Create_Date_Time = -1;
  }
  $body= $body.nt_int($Create_Date_Time);
  if(length($Comment)!=0)
  {
    $body = $body.nt_int(length($Comment)).$Comment;
    $bodysize+= length($Comment);
  }
  else
  {
    $body=$body.nt_int(0);
  }
  if (scalar(@Modules_Names) != 0)
  {
    my $buffer_size = 0; 
    my $buffer_body = "";
    foreach(@Modules_Names)
    {
      $buffer_body = $buffer_body.nt_int(length($_)).$_;
      $buffer_size+= 4+length($_);
    }
    $body = $body.nt_int($buffer_size);
    $body = $body.nt_int(scalar(@Modules_Names));
    $body = $body.$buffer_body;
    $bodysize += 8 + $buffer_size;
  }
  else
  {
    $body= $body.nt_int(0).nt_int(0);
  }
  
  $self->write(command=>$self->nt_header($command_name,$bodysize,1).$body);
  $self->_end_of_com();
}

sub threeDSwp_SaveOptionsGet {
    my $self = shift;
    my $command_name = "3dswp.saveoptionsget";
    $self->write(command=>$self->nt_header($command_name,0,1));

    my $return = $self->binary_read();
    my $pos = unpack("N!",substr($return,40,4));
    my $Series_Name = substr($return,44,$pos);
    $pos+=44;
    my $DT_Folder_opt = unpack("N",substr($return,$pos,4));
    $pos += 12 + unpack("N!",substr($return,$pos+4,4));
    my $strLen = unpack("N!",substr($return,$pos,4));
    my $Comment = substr($return,$pos+4,$strLen);
    $pos+=4+$strLen;
    my $MP_size = unpack("N!",substr($return,$pos,4));
    my $MP_number = unpack("N!",substr($return,$pos+4,4));
    my %Modules_parameters = $self->strArrayUnpacker($MP_number,substr($return,$pos+8,$MP_size));
    my @Modules_param = @Modules_parameters{0...(scalar(keys %Modules_parameters)-1)};
    return($Series_Name,$DT_Folder_opt,$Comment,@Modules_param);

}

sub threeDSwp_Start {
  my $self = shift;
  my $command_name= "3dswp.start";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  $self->_end_of_com();
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
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head.nt_int($Sweep_channel_index));
  $self->_end_of_com();
}

sub threeDSwp_SwpChLimitsSet {
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.swpchlimitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
  $self->_end_of_com();
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
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Number_of_points);
  $body=$body.nt_int($Number_of_sweeps);
  $body=$body.nt_int($Backward_sweep);
  $body=$body.nt_int($End_of_sweep_action);
  $body=$body.nt_float32($End_of_sweep_arbitrary_value);
  $body=$body.nt_int($Save_all);
  $self->write(command=>$head.$body);
  $self->_end_of_com();
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
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($Settling_time_s);
  $body=$body.nt_float32($Integration_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($Maximum_slw_rate);
  $self->write(command=>$head.$body);
  $self->_end_of_com();
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
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head.nt_int($Step_channel_1_index));
  $self->_end_of_com();
}

sub threeDSwp_StpCh1LimitsSet {
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.stpch1limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
  $self->_end_of_com();
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
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Number_of_points);
  $body=$body.nt_int($Backward_sweep);
  $body=$body.nt_int($End_of_sweep_action);
  $body=$body.nt_float32($End_of_sweep_arbitrary_value);
  $self->write(command=>$head.$body);
  $self->_end_of_com();
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
  $self->_end_of_com();
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
  my $bodysize = 4+($name_len);
  my $command_name = "3dswp.stpch2signalset";
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head.nt_int($name_len).$Channel_name);
  $self->_end_of_com();
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
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
  $self->_end_of_com();
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
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Number_of_points);
  $body=$body.nt_int($Backward_sweep);
  $body=$body.nt_int($End_of_sweep_action);
  $body=$body.nt_float32($End_of_sweep_arbitrary_value);
  $self->write(command=>$head.$body);
  $self->_end_of_com();
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

=head2 3DSwp.FilePathsGet
=cut

sub threeDSwp_FilePathsGet {
  my $self = shift;
  my $command_name = "3dswp.filepathsget";
  my $head = 
  $self->write(command=>$self->nt_header($command_name,0,1));
  my $response = $self->binary_read();
  my $strArraySize = unpack("N!", substr $response,40,4);
  my $strNumber = unpack("N!", substr $response, 44, 4 );
  my $strArray = substr $response,48,$strArraySize;
  my %strings = $self->strArrayUnpacker($strNumber,$strArray);
  return %strings;
}

=head1 Signals
=cut

sub Signals_NamesGet {
  my $self =shift;
  my $command_name="signals.namesget";
  my $head = $self->nt_header($command_name,0,1);

  $self->write(command=>$head);

  my $response =$self->read();
  my $strArraySize = unpack("N!", substr $response,40,4);
  my $strNumber = unpack("N!", substr $response, 44, 4 );
  my $strArray = substr $response,48,$strArraySize;
  my %strings = $self->strArrayUnpacker($strNumber,$strArray);
  return %strings;
}

sub Signals_InSlotSet {
  my $self = shift;
  my ($Slot,$RT_signal_index)= @_;
  my $command_name= "signals.inslotset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Slot);
  $body=$body.nt_int($RT_signal_index);
  $self->write(command=>$head.$body);
}

sub Signals_InSlotsGet {
  my $self = shift;
  my $command_name= "signals.inslotsget";
  my $head = $self->nt_header($command_name,0,1);
  $self->write(command=>$head);

  my $response = $self->binary_read();
  my $namesSize= unpack("N!",substr $response,40,4);
  my $namesNumber= unpack("N!",substr $response,44,4);
  my %Strings = $self->strArrayUnpacker($namesNumber,substr($response,48,$namesSize));
  my $idxNumber = unpack("N!",substr $response,48+$namesSize,4);
  my @idxArray = $self->intArrayUnpacker($idxNumber,substr($response,52+$namesSize,4*$idxNumber));
  foreach(keys %Strings){
    $Strings{$_}= join(" RT ",$Strings{$_},$idxArray[$_]);
  }
  return (%Strings);
}

sub Signals_CalibrGet {
  my $self = shift;
  my ($Signal_index)= @_;
  my $command_name= "signals.calibrget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Signal_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Calibration_per_volt= substr $return,40,4;
  $Calibration_per_volt= unpack("f>",$Calibration_per_volt);
  my $Offset_in_physical_units= substr $return,44,4;
  $Offset_in_physical_units= unpack("f>",$Offset_in_physical_units);
  return($Calibration_per_volt,$Offset_in_physical_units);
}

sub Signals_RangeGet {
  my $self = shift;
  my ($Signal_index)= @_;
  my $command_name= "signals.rangeget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Signal_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Maximum_limit= substr $return,40,4;
  $Maximum_limit= unpack("f>",$Maximum_limit);
  my $Minimum_limit= substr $return,44,4;
  $Minimum_limit= unpack("f>",$Minimum_limit);
  return($Maximum_limit,$Minimum_limit);
}

sub Signals_ValGet {
  my $self = shift;
  my ($Signal_index,$Wait_for_newest_data)= @_;
  my $command_name= "signals.valget";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Signal_index);
  $body=$body.nt_uint32($Wait_for_newest_data);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Signal_value= substr $return,40,4;
  $Signal_value= unpack("f>",$Signal_value);
  return($Signal_value);
}

sub Signals_ValsGet {
  #this function behaves differently. 
  #Usualy requested size is actual Byte size, here is element count.

  my $self = shift;
  my @idxArray = @_;
  my $WFND = pop @idxArray;
  my $command_name = "signals.valsget";

  if($WFND > 0){
    $WFND=1;
  }
  else{
    $WFND = 0;
  }

  my $bodysize = 8+ 4 * scalar @idxArray;
  my $head = $self->nt_header($command_name,$bodysize,1);
  my $body = pack("N!",(scalar @idxArray));
  foreach(@idxArray){
    $body = $body.pack("N!",$_);
  }
  $body= $body.pack("N",$WFND);

  $self->write(command=>$head.$body);

  my $response = $self->binary_read();
  my $valuesSize = unpack("N!", substr $response,40,4);
  my @floatArray = $self->float32ArrayUnpacker($valuesSize,substr($response,44,$valuesSize*4));
  return @floatArray;
}

sub Signals_MeasNamesGet {
  my $self = shift;
  my $command_name= "signals.measnamesget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $response = $self->read();
  my $channelSize= unpack("N!",substr $response,40,4);
  my $channelNum= unpack("N!",substr $response,44,4);
  my $strArray = substr $response,48,$channelSize;
  my %channels = $self->strArrayUnpacker($channelNum,$strArray);
  return %channels;
}

sub Signals_AddRTGet() {
  
  my $self = shift;
  my $command_name="signals.addrtget";
  my $head = $self->nt_header($command_name,0,1);
  $self->write(command=>$head);

  my $response = $self->binary_read();
  my $namesSize = unpack("N!",substr $response,40,4);
  my $namesNumber = unpack("N!",substr $response,44,4);
  my %addRtArray = $self->strArrayUnpacker($namesNumber,substr($response,48,$namesSize));
  return %addRtArray;

}

sub Signals_AddRTSet {
  my $self = shift;
  my ($Additional_RT_signal_1,$Additional_RT_signal_2)= @_;
  my $command_name= "signals.addrtset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Additional_RT_signal_1);
  $body=$body.nt_int($Additional_RT_signal_2);
  $self->write(command=>$head.$body);
}

=head1 User
=cut

sub UserIn_CalibrSet {
  my $self = shift;
  my ($Input_index,$Calibration_per_volt,$Offset_in_physical_units)= @_;
  my $command_name= "userin.calibrset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Input_index);
  $body=$body.nt_float32($Calibration_per_volt);
  $body=$body.nt_float32($Offset_in_physical_units);
  $self->write(command=>$head.$body);
}

sub UserOut_ModeSet {
  my $self = shift;
  my ($Output_index,$Output_mode)= @_;
  my $command_name= "userout.modeset";
  my $bodysize = 6;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_uint16($Output_mode);
  $self->write(command=>$head.$body);
}

sub UserOut_ModeGet {
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.modeget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Output_mode= substr $return,40,2;
  $Output_mode= unpack("n",$Output_mode);
  return($Output_mode);
}

sub UserOut_MonitorChSet {
  my $self = shift;
  my ($Output_index,$Monitor_channel_index)= @_;
  my $command_name= "userout.monitorchset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_int($Monitor_channel_index);
  $self->write(command=>$head.$body);
}


sub UserOut_MonitorChGet {
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.monitorchget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Monitor_channel_index= substr $return,40,4;
  $Monitor_channel_index= unpack("N!",$Monitor_channel_index);
  return($Monitor_channel_index);
}

sub UserOut_ValSet {
  my $self = shift;
  my ($Output_index,$Output_value)= @_;
  my $command_name= "userout.valset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_float32($Output_value);
  $self->write(command=>$head.$body);
}

sub UserOut_CalibrSet {
  my $self = shift;
  my ($Output_index,$Calibration_per_volt,$Offset_in_physical_units)= @_;
  my $command_name= "userout.calibrset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_float32($Calibration_per_volt);
  $body=$body.nt_float32($Offset_in_physical_units);
  $self->write(command=>$head.$body);
}


sub UserOut_CalcSignalNameSet {
  my $self = shift;
  my $output_index = shift;
  my $string = shift;
  my $command_name = "userout.calcsignalnameset";
  my $bodysize= 8 + length($string);
  my $head = $self->nt_header($command_name,$bodysize,1);
  my $body = nt_int($output_index).nt_int(length($string)).$string;

  $self->write(command=>$head.$body);
}

sub UserOut_CalcSignalNameGet {

  my $self = shift;
  my $output_index = shift;
  my $command_name = "userout.calcsignalnameget";

  $self->write(command=>$self->nt_header($command_name,4,1).nt_int($output_index));

  my $return = $self->binary_read();
  my $strLen = unpack("N!",substr($return,40,4));
  return substr $return,44,$strLen;

}

sub UserOut_CalcSignalConfigSet {
  my $self = shift;
  my ($Output_index,$Operation_1,$Value_1,$Operation_2,$Value_2,$Operation_3,$Value_3,$Operation_4,$Value_4)= @_;
  my $command_name= "userout.calcsignalconfigset";
  my $bodysize = 28;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_uint16($Operation_1);
  $body=$body.nt_float32($Value_1);
  $body=$body.nt_uint16($Operation_2);
  $body=$body.nt_float32($Value_2);
  $body=$body.nt_uint16($Operation_3);
  $body=$body.nt_float32($Value_3);
  $body=$body.nt_uint16($Operation_4);
  $body=$body.nt_float32($Value_4);
  $self->write(command=>$head.$body);
}

sub UserOut_CalcSignalConfigGet {
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.calcsignalconfigget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Operation_1= substr $return,40,2;
  $Operation_1= unpack("n",$Operation_1);
  my $Value_1= substr $return,42,4;
  $Value_1= unpack("f>",$Value_1);
  my $Operation_2= substr $return,46,2;
  $Operation_2= unpack("n",$Operation_2);
  my $Value_2= substr $return,48,4;
  $Value_2= unpack("f>",$Value_2);
  my $Operation_3= substr $return,52,2;
  $Operation_3= unpack("n",$Operation_3);
  my $Value_3= substr $return,54,4;
  $Value_3= unpack("f>",$Value_3);
  my $Operation_4= substr $return,58,2;
  $Operation_4= unpack("n",$Operation_4);
  my $Value_4= substr $return,60,4;
  $Value_4= unpack("f>",$Value_4);
  return($Operation_1,$Value_1,$Operation_2,$Value_2,$Operation_3,$Value_3,$Operation_4,$Value_4);
}

sub UserOut_LimitsSet {
  my $self = shift;
  my ($Output_index,$Upper_limit,$Lower_limit)= @_;
  my $command_name= "userout.limitsset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_float32($Upper_limit);
  $body=$body.nt_float32($Lower_limit);
  $self->write(command=>$head.$body);
}
sub UserOut_LimitsGet {
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.limitsget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Upper_limit= substr $return,40,4;
  $Upper_limit= unpack("f>",$Upper_limit);
  my $Lower_limit= substr $return,44,4;
  $Lower_limit= unpack("f>",$Lower_limit);
  return($Upper_limit,$Lower_limit);
}
sub UserOut_SlewRateSet {
  my $self = shift;
  my ($Output_index,$Slew_Rate)= @_;
  my $command_name= "userout.slewrateset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_float64($Slew_Rate);
  $self->write(command=>$head.$body);
}

sub UserOut_SlewRateGet {
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.slewrateget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->binary_read(); 
  my $Slew_Rate= substr $return,40,8;
  $Slew_Rate= unpack("d>",$Slew_Rate);
  return($Slew_Rate);
}

=head1 Digita Lines 
=cut 

sub DigLines_PropsSet {
  my $self = shift;
  my ($Digital_line,$Port,$Direction,$Polarity)= @_;
  my $command_name= "diglines.propsset";
  my $bodysize = 16;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint32($Digital_line);
  $body=$body.nt_uint32($Port);
  $body=$body.nt_uint32($Direction);
  $body=$body.nt_uint32($Polarity);
  $self->write(command=>$head.$body);
}

sub DigLines_OutStatusSet {
  my $self = shift;
  my ($Port,$Digital_line,$Status)= @_;
  my $command_name= "diglines.outstatusset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint32($Port);
  $body=$body.nt_uint32($Digital_line);
  $body=$body.nt_uint32($Status);
  $self->write(command=>$head.$body);
}

sub DigLines_TTLValGet {
  
  my $self = shift;
  my $port = shift;
  my $command_name = "diglines.ttlvalget";
  my $head = $self->nt_header($command_name,4,1);

  $self->write(command=>$head.nt_uint16($port));

  my $return = $self->binary_read();

  my $intArraySize = unpack("N!",substr($return,40,4));
  my @intArray = $self->intArrayUnpacker($intArraySize,substr($return,44,$intArraySize*4));
  return @intArray;
}

sub DigLines_Pulse {
  #Changing different order of args here, we pass the lines array as last argument
  my $self = shift;
  my $port = shift;
  my $Pulse_width = shift;
  my $Pulse_pause = shift; 
  my $Pulse_number = shift;
  my $Wait_param = shift; 
  my @lines = @_;
  my $command_name = "diglines.pulse";
  my $head = $self->nt_header($command_name,22 + scalar(@lines),0);
  my $body = nt_uint16($port).nt_int(scalar(@lines));
  foreach(@lines){
   $body = $body.pack("c",$_);
  }
  $body = $body.nt_float32($Pulse_width).nt_float32($Pulse_pause);
  $body = $body.nt_int($Pulse_number).nt_uint32($Wait_param);
  $self->write(command=>$head.$body);
}

=head1 Utilities
=cut

sub Util_SessionPathGet {
    my $self = shift;
    my $command_name ="util.sessionpathget";
    my $head = $self->nt_header($command_name,0,1);
    $self->write(command=>$head);

    my $response = $self->binary_read();
    return substr $response,44,unpack("N!",substr $response,40,4);
}

sub Util_SessionPathSet {  
  my $self = shift ;
  my $command_name ="util.sessionpathset" ;
  my $session_path = shift;
  my $save_settings = shift;
  my $bodysize = 8 + length($session_path);
  my $head = $self->nt_header($command_name,$bodysize,1) ;
  $self->write(command=>$head.nt_int(length($session_path)).$session_path.nt_uint32($save_settings));
  $self->_end_of_com();
}

sub Util_SettingsLoad {
  #Not sure if working
  my $self = shift;
  my ($path,$Automatic_Load) = @_;
  my $command_name = "util.settingsload";
  if($Automatic_Load> 0){
    $Automatic_Load = 1;
  }
  else{
    $Automatic_Load = 0;
  }
  my $bodysize = 8 + 4*length($path);
  my $head = $self->nt_header($command_name,$bodysize,0);
  my $body = pack("N!",length($path)).$path.pack("N",$Automatic_Load);
  $self->write( command => $head.$body);
}

sub Util_SettingsSave {
  #Not sure if working 
  my $self = shift;
  my ($path,$Automatic_save) = @_;
  my $command_name = "util.settingssave";

  if($Automatic_save> 0){
    $Automatic_save= 1;
  }
  else{
    $Automatic_save = 0;
  }

  my $bodysize = 8 + 4*length($path);
  my $head = $self->nt_header($command_name,$bodysize,1);
  my $body = pack("N!",length($path)).$path.pack("N",$Automatic_save);
  $self->write( command => $head.$body);
  print($self->binary_read());
}

sub Util_LayoutLoad {
  #Not sure if working
  my $self = shift;
  my ($path,$Automatic_Load) = @_;
  my $command_name = "util.layoutload";
  if($Automatic_Load> 0){
    $Automatic_Load= 1;
  }
  else{
    $Automatic_Load = 0;
  }
  my $bodysize = 8 + 4*length($path);
  my $head = $self->nt_header($command_name,$bodysize,0);
  my $body = pack("N!",length($path)).$path.pack("N",$Automatic_Load);
  $self->write( command => $head.$body);
}

sub Util_LayoutSave {
  #Not sure if working 
  my $self = shift;
  my ($path,$Automatic_save) = @_;
  my $command_name = "util.layoutsave";
  if($Automatic_save> 0){
    $Automatic_save= 1;
  }
  else{
    $Automatic_save = 0;
  }
  my $bodysize = 8 + 4*length($path);
  my $head = $self->nt_header($command_name,$bodysize,1);
  my $body = pack("N!",length($path)).$path.pack("N",$Automatic_save);
  $self->write( command => $head.$body);
  print($self->binary_read());
}

sub Util_Lock {
  my $self = shift;
  my $command_name= "util.lock";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}

sub Util_UnLock {
  my $self = shift;
  my $command_name= "util.unlock";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}

sub Util_RTFreqSet {
  my $self = shift;
  my ($RT_frequency)= @_;
  my $command_name= "util.rtfreqset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($RT_frequency);
  $self->write(command=>$head.$body);
}

sub Util_RTFreqGet {
  my $self = shift;
  my $command_name= "util.rtfreqget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $RT_frequency= substr $return,40,4;
  $RT_frequency= unpack("f>",$RT_frequency);
  return($RT_frequency);
}

sub Util_AcqPeriodSet {
  my $self = shift;
  my ($Acquisition_Period_s)= @_;
  my $command_name= "util.acqperiodset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Acquisition_Period_s);
  $self->write(command=>$head.$body);
}

sub Util_AcqPeriodGet {
  my $self = shift;
  my $command_name= "util.acqperiodget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $Acquisition_Period_s= substr $return,40,4;
  $Acquisition_Period_s= unpack("f>",$Acquisition_Period_s);
  return($Acquisition_Period_s);
}

sub Util_RTOversamplSet {
  my $self = shift;
  my ($RT_oversampling)= @_;
  my $command_name= "util.rtoversamplset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($RT_oversampling);
  $self->write(command=>$head.$body);
}

sub Util_RTOversamplGet {
  my $self = shift;
  my $command_name= "util.rtoversamplget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->binary_read(); 
  my $RT_oversampling= substr $return,40,4;
  $RT_oversampling= unpack("N!",$RT_oversampling);
  return($RT_oversampling);
}
#Some modules are missing
=head1 File
=cut 

sub File_datLoad {
  my $self = shift;
  my $file_path = shift;
  my $header_only = shift;
  my $read_length = shift ;
  my $command_name = "file.datload";
  my $bodysize = 8 + length($file_path);
  my $head = $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head.nt_int(length($file_path)).$file_path.nt_int($header_only));
  my $result_head = $self->read(read_length=>40);
  my $result_size = unpack("N!",substr $result_head,32,4);
  my $result = $self->read(read_length=>$result_size);
  my $Channel_names_size = unpack('N!', substr $result,0,4);
  my $Name_number = unpack('N!', substr $result,4,4);
  my $raw_names = substr $result,8,$Channel_names_size;
  #my $raw_names = $self->read(read_length=>$Channel_names_size);
  my %Channel_names = $self->strArrayUnpacker($Name_number,$raw_names);
  $result = substr($result,-1*(length($result)-8-$Channel_names_size));
  my $Data_rows  = unpack("N!",substr($result,0,4));
  my $Data_cols  = unpack ("N!",substr($result,4,8));
  my $Data_size  = 4*$Data_cols*$Data_rows;
  my @float2Darray = $self->float32ArrayUnpacker($Data_cols*$Data_rows,substr($result,8,$Data_size));
  # my $raw_float_array = $self->read(read_length=>$Data_size);
  # my @float2Darray = $self->float32ArrayUnpacker($Data_cols*$Data_rows,$raw_float_array);
  my $parsed_body = "";
  for(my $index = 0;$index < max(keys %Channel_names);$index++){
    $parsed_body = $parsed_body.$Channel_names{$index}." ;";
  }
  $parsed_body=$parsed_body."\n";
  for (my $index = 0; $index< scalar(@float2Darray);$index++){
    $parsed_body=$parsed_body.$float2Darray[$index]." ;";
    if(($index+1)%$Data_cols == 0){
      $parsed_body=$parsed_body."\n";
    }
  }
  return $parsed_body;
}

=head1 High Level COM
=cut

=head2 Class Variables
=cut

has _Session_Path => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    reader => 'Session_Path',
    writer => '_Session_Path',
    builder =>'_build_Session_Path'
);

sub _build_Session_Path {
  my $self = shift ;
  return $self->Util_SessionPathGet();
}

has sweep_prop_configuration => (
    is=>'rw',
    isa => 'HashRef',
    reader => 'sweep_prop_configuration',
    writer => '_sweep_prop_configuration',
    builder => '_build_sweep_prop_configuration',
);

has sweep_timing_configuration =>(
    is=>'rw',
    isa => 'HashRef',
    reader => 'sweep_timing_configuration',
    writer => '_sweep_timing_configuration',
    builder => '_build_sweep_timing_configuration',
    clearer =>'reset_swp_timing',
    lazy => 1

);

sub _build_sweep_timing_configuration {
  my $self = shift ;
  my %hash;
  my @values = $self->threeDSwp_SwpChTimingGet();
  $hash{initial_settling_time} = $values[0];
  $hash{settling_time} = $values[1];
  $hash{integration_time} = $values[2];
  $hash{end_settling_time} = $values[3];
  $hash{Maximum_slew_rate} = $values[4];
  return \%hash;
}

sub _build_sweep_prop_configuration {
  my $self = shift;
  my %hash;
  $hash{point_number}=2;
  $hash{number_of_sweeps}=1;
  $hash{backwards}=-1;
  $hash{at_end}=-1;
  $hash{at_end_val}=0;
  $hash{save_all}=-1;
  return \%hash;
}

has signals => (
    is=>'ro',
    isa => 'HashRef',
    reader => "signals",
    lazy =>1,
    builder => '_signals_builder',
);

sub _signals_builder {
  my $self = shift;
  my %hash = $self->Signals_InSlotsGet();
  return \%hash;
}

has outputs => (
  is => 'rw',
  isa => 'HashRef',
  reader =>'outputs',
  writer => '_outputs',
  builder => '_outputs_builder'
);

sub _outputs_builder {
  my $self = shift;
  my %hash;
  $hash{0}="Plunger Gate (V)";
  $hash{1}="Source-Drain (V)";
  $hash{2}="Left Gate (V)";
  $hash{3}="Right Gate (V)";
  $hash{4}="Output 5 (V)";
  $hash{5}="Output 6 (V)";
  $hash{6}="Output 7 (V)";
  $hash{7}="Output 8 (V)";
  return \%hash;
}

has step1_prop_configuration => (
    is=>'rw',
    isa => 'HashRef',
    reader => 'step1_prop_configuration',
    writer => '_step1_prop_configuration',
    builder => '_build_step1_prop_configuration',
);

sub _build_step1_prop_configuration {
  my $self = shift;
  my %hash;
  $hash{point_number}=0;
  $hash{backwards}=-1;
  $hash{at_end}=-1;
  $hash{at_end_val}=0;
  return \%hash;
}

has step1_timing_configuration =>(
    is=>'rw',
    isa => 'HashRef',
    reader => 'step1_timing_configuration',
    writer => '_step1_timing_configuration',
    builder => '_build_step1_timing_configuration',
    clearer =>'reset_stp1_timing',
    lazy => 1

);

sub _build_step1_timing_configuration {
  my $self = shift ;
  my %hash;
  my @values = $self->threeDSwp_StpCh1TimingGet;
  $hash{initial_settling_time} = $values[0];
  $hash{end_settling_time} = $values[1];
  $hash{Maximum_slew_rate} = $values[2];
  return \%hash;
}


has step2_prop_configuration => (
    is=>'rw',
    isa => 'HashRef',
    reader => 'step2_prop_configuration',
    writer => '_step2_prop_configuration',
    builder => '_build_step2_prop_configuration',
);

sub _build_step2_prop_configuration {
  my $self = shift;
  my %hash;
  $hash{point_number}=0;
  $hash{backwards}=-1;
  $hash{at_end}=-1;
  $hash{at_end_val}=0;
  return \%hash;
}

has step2_timing_configuration =>(
    is=>'rw',
    isa => 'HashRef',
    reader => 'step2_timing_configuration',
    writer => '_step2_timing_configuration',
    builder => '_build_step2_timing_configuration',
    clearer =>'reset_stp2_timing',
    lazy => 1

);

sub _build_step2_timing_configuration {
  my $self = shift ;
  my %hash;
  my @values = $self->threeDSwp_StpCh2TimingGet;
  $hash{initial_settling_time} = $values[0];
  $hash{end_settling_time} = $values[1];
  $hash{Maximum_slew_rate} = $values[2];
  return \%hash;
}


has sweep_save_configuration => (
    is=>'rw',
    isa => 'HashRef',
    reader => 'sweep_save_configuration',
    writer => '_sweep_save_configuration',
    builder => '_build_sweep_save_configuration',
);

sub _build_sweep_save_configuration {
  my $self = shift;
  my %hash;
  $hash{series_name}="";
  $hash{create_datetime}=-1;
  $hash{comment}="";
  return \%hash;
}

=head2 Class Methods
=cut

sub set_Session_Path {
  my($self,%params) = validated_hash(
    \@_,
    session_path => {isa => 'Str'},
    save_settings => {isa => 'Int',optional => 1}
    );
  
  if($params{session_path} =~ /^([a-zA-Z]:)(([\\]?[\w _!#()-]+)*[\\])?$/)
  {
    if(exists($params{save_settings}))
    {
      $self->Util_SessionPathSet($params{session_path},$params{save_settings});
    }
    else
    {
      $self->Util_SessionPathSet($params{session_path},0);
    }
    $self->_Session_Path($params{session_path});
  }
  else
  {
    die "Invalid path in set_Session_Path: Path is not Windows Directory Path";
  }
}

# Prototype for a file cat
# deprecated from now daa tranfer functionalities 
# sub get_filenames {
#   my($self,%params)= validated_hash(
#     \@_,
#     series_name=> {isa=>"Str", optional=>1},
#     session_path => {isa=>"Str",optional=>1}, 
#     );
#   	if(exists($params{session_path}))
#     {
#       $self->set_Session_Path(value=>$params{session_path});
#     } 
#     if($self->Session_Path() ne '')
#     {
#       opendir my $filedir, $self->Session_Path or die "Can not open directory";
#       my @files = readdir $filedir;
#       my @selected_files;
#       if(exists($params{series_name}))
#       {
#         foreach(@files)
#         {
#           if($_ =~ /^($params{series_name})\d{5}(.dat)/)
#            {
#             push  @selected_files, $_;
#            }
#         }
#         return @selected_files; 
#       }
#       else
#       {
#         foreach(@files)
#         {
#           if($_ =~ /[\w\d]\d{5}(.dat)/)
#            {
#             push  @selected_files, $_;
#            }
#         }
#         return @selected_files;
#       }
#   }
#   else
#   {
#     die "Error: Session_Path is not set";
#   }
# }


sub parse_last {
  my $self = shift ;
  my ($destination_path) = validated_list(\@_, path =>{isa=>'Str'});
  my %files = $self->threeDSwp_FilePathsGet();
  foreach(keys %files){
    my ($filename) = $files{$_} =~ m/([ \w-]+\.dat)/g;
    open(my $fh,'>',$destination_path.$filename) or die "Could not open file'$filename' $!";
    print $fh $self->File_datLoad($files{$_},0,15000);
    close $fh;
    sleep(1);
    print("Parsed $filename\n");
  }  
}

sub sweep_save_configure {
  my ($self, %params) =  validated_hash(
  \@_,
  series_name=>{isa=>"Str",optional =>1},
  create_datetime =>{isa =>"Int",optional =>1}, 
  comment =>{isa=>"Str",optional =>1}
  );
  if(!exists($params{series_name})){
    $params{series_name}=$self->sweep_save_configuration()->{series_name};
  }
  if(!exists($params{create_datetime})){
    $params{create_datetime}=$self->sweep_save_configuration()->{create_datetime};
  }
  if(!exists($params{comment})){
    $params{comment}=$self->sweep_save_configuration()->{comment};
  }
  if($params{create_datetime}!=-1 && $params{create_datetime}!=0 && $params{create_datetime}!=1)
  {
    die "Invalid create_date value in sweep_save_configure: value must be -1,0 or 1!"
  }

  $self->_sweep_save_configuration(\%params);
  $self->threeDSwp_SaveOptionsSet($params{series_name},
                                  $params{create_datetime},
                                  $params{comment})
}

sub sweep_timing_configure {
  my ($self, %params) =  validated_hash(
  \@_,
  initial_settling_time =>{isa=>"Num",optional =>1},
  settling_time => {isa =>"Num",optional =>1}, 
  integration_time=> {isa=>"Num",optional =>1},
  end_settling_time => {isa =>"Num",optional =>1},
  maximum_slew_rate =>{isa =>"Num",optional =>1}
  );
  # NOTE : Here some validation may be necessary, Nanonis does not returrn error if Value is invalid 
  if(!exists($params{initial_settling_time})){
      $params{initial_settling_time} = $self->sweep_timing_configuration()->{initial_settling_time};
  };
  if(!exists($params{settling_time})){
      $params{settling_time} = $self->sweep_timing_configuration()->{settling_time};
  };
  if(!exists($params{integration_time})){
      $params{integration_time} = $self->sweep_timing_configuration()->{integration_time};
  };
  if(!exists($params{end_settling_time})){
      $params{end_settling_time} = $self->sweep_timing_configuration()->{end_settling_time};
  };
  if(!exists($params{maximum_slew_rate})){
      $params{maximum_slew_rate} = $self->sweep_timing_configuration()->{maximum_slew_rate};
  };
  $self->reset_swp_timing;
  $self->threeDSwp_SwpChTimingSet( $params{initial_settling_time},
                                   $params{settling_time},
                                   $params{integration_time},
                                   $params{end_settling_time}, 
                                   $params{maximum_slew_rate})

}

sub step1_timing_configure {
  my ($self, %params) =  validated_hash(
  \@_,
  initial_settling_time =>{isa=>"Num",optional =>1},
  end_settling_time => {isa =>"Num",optional =>1},
  maximum_slew_rate =>{isa =>"Num",optional =>1}
  );
  # NOTE : Here some validation may be necessary, Nanonis does not returrn error if Value is invalid 
  if(!exists($params{initial_settling_time})){
      $params{initial_settling_time} = $self->step1_timing_configuration()->{initial_settling_time};
  };
  if(!exists($params{end_settling_time})){
      $params{end_settling_time} = $self->step1_timing_configuration()->{end_settling_time};
  };
  if(!exists($params{maximum_slew_rate})){
      $params{maximum_slew_rate} = $self->step1_timing_configuration()->{maximum_slew_rate};
  };
  $self->reset_stp1_timing;
  $self->threeDSwp_StpCh1TimingSet( $params{initial_settling_time},
                                   $params{end_settling_time}, 
                                   $params{maximum_slew_rate})
}

sub step2_timing_configure {
  my ($self, %params) =  validated_hash(
  \@_,
  initial_settling_time =>{isa=>"Num",optional =>1},
  end_settling_time => {isa =>"Num",optional =>1},
  maximum_slew_rate =>{isa =>"Num",optional =>1}
  );
  # NOTE : Here some validation may be necessary, Nanonis does not returrn error if Value is invalid 
  if(!exists($params{initial_settling_time})){
      $params{initial_settling_time} = $self->step2_timing_configuration()->{initial_settling_time};
  };
  if(!exists($params{end_settling_time})){
      $params{end_settling_time} = $self->step2_timing_configuration()->{end_settling_time};
  };
  if(!exists($params{maximum_slew_rate})){
      $params{maximum_slew_rate} = $self->step2_timing_configuration()->{maximum_slew_rate};
  };
  $self->reset_stp2_timing;
  $self->threeDSwp_StpCh1TimingSet( $params{initial_settling_time},
                                   $params{end_settling_time}, 
                                   $params{maximum_slew_rate})
}




sub sweep_prop_configure {
  my $self= shift;
  my %params =  validated_hash(
  \@_,
  point_number =>{isa=>"Int", optional=>1},
  number_of_sweeps =>{isa =>"Int", optional =>1}, 
  backwards =>{isa=>"Int", optional =>1},
  at_end=> {isa => "Int", optional =>1}, 
  at_end_val =>{isa =>"Num", optional =>1},
  save_all =>{isa=>"Num",optional =>1}
  );

  if(!exists($params{point_number})){
    $params{point_number}=$self->sweep_prop_configuration()->{point_number};
  }
  if(!exists($params{number_of_sweeps})){
    $params{number_of_sweeps}=$self->sweep_prop_configuration()->{number_of_sweeps};
  }
  if(!exists($params{backwards})){
    $params{backwards}=$self->sweep_prop_configuration()->{backwards};
  }
  if(!exists($params{at_end})){
    $params{at_end}=$self->sweep_prop_configuration()->{at_end};
  }
  if(!exists($params{at_end_val})){
    $params{at_end_val}=$self->sweep_prop_configuration()->{at_end_val};
  }
  if(!exists($params{save_all})){
    $params{save_all}=$self->sweep_prop_configuration()->{save_all};
  }

  if($params{point_number}<0){
    die "Invalid point_number value in sweep_prop_configure: value must be greater or equal to 0!";
  }
  if($params{number_of_sweeps}<0){
    die "Invalid sweep_number value  in sweep_prop_configure: value must be greater or equal to 0!";
  }
  if($params{backwards}!=-1 && $params{backwards}!=0 && $params{backwards}!=1){
    die "Invalid backwards value in sweep_prop_configure: value -1,0 or 1";
  }
  if($params{at_end}!=-1 && $params{at_end}!=0 && $params{at_end}!=1 && $params{at_end}!=2){
    die "Invalid backwards value in sweep_prop_configure: value -1,0,1 or 2";
  }
  if($params{save_all}!=-1 && $params{save_all}!=0 && $params{save_all}!=1){
    die "Invalid backwards value in sweep_prop_configure: value -1,0 or 1";
  }
  $self->_sweep_prop_configuration(\%params);
  $self->threeDSwp_SwpChPropsSet($params{point_number},
                                 $params{number_of_sweeps},
                                 $params{backwards},
                                 $params{at_end},
                                 $params{at_end_val},
                                 $params{save_all});  
}

sub step1_prop_configure {
  my $self= shift;
  my %params =  validated_hash(
  \@_,
  point_number =>{isa=>"Int", optional=>1},
  backwards =>{isa=>"Int", optional =>1},
  at_end=> {isa => "Int", optional =>1}, 
  at_end_val =>{isa =>"Num", optional =>1}
  );

  if(!exists($params{point_number})){
    $params{point_number}=$self->step1_prop_configuration()->{point_number};
  }
  if(!exists($params{backwards})){
    $params{backwards}=$self->step1_prop_configuration()->{backwards};
  }
  if(!exists($params{at_end})){
    $params{at_end}=$self->step1_prop_configuration()->{at_end};
  }
  if(!exists($params{at_end_val})){
    $params{at_end_val}=$self->step1_prop_configuration()->{at_end_val};
  }

  if($params{point_number}<0){
    die "Invalid point_number value in step1_prop_configure: value must be greater or equal to 0!";
  }
  if($params{backwards}!=-1 && $params{backwards}!=0 && $params{backwards}!=1){
    die "Invalid backwards value in step1_prop_configure: value -1,0 or 1";
  }
  if($params{at_end}!=-1 && $params{at_end}!=0 && $params{at_end}!=1 && $params{at_end}!=2){
    die "Invalid backwards value in step1_prop_configure: value -1,0,1 or 2";
  }

  $self->_step1_prop_configuration(\%params);
  $self->threeDSwp_StpCh1PropsSet($params{point_number},
                                  $params{backwards},
                                  $params{at_end},
                                  $params{at_end_val});  
}

sub step2_prop_configure {
  my $self= shift;
  my %params =  validated_hash(
  \@_,
  point_number =>{isa=>"Int", optional=>1},
  backwards =>{isa=>"Int", optional =>1},
  at_end=> {isa => "Int", optional =>1}, 
  at_end_val =>{isa =>"Num", optional =>1}
  );

  if(!exists($params{point_number})){
    $params{point_number}=$self->step1_prop_configuration()->{point_number};
  }
  if(!exists($params{backwards})){
    $params{backwards}=$self->step1_prop_configuration()->{backwards};
  }
  if(!exists($params{at_end})){
    $params{at_end}=$self->step2_prop_configuration()->{at_end};
  }
  if(!exists($params{at_end_val})){
    $params{at_end_val}=$self->step2_prop_configuration()->{at_end_val};
  }

  if($params{point_number}<0){
    die "Invalid point_number value in step2_prop_configure: value must be greater or equal to 0!";
  }

  if($params{backwards}!=-1 && $params{backwards}!=0 && $params{backwards}!=1){
    die "Invalid backwards value in step2_prop_configure: value -1,0 or 1";
  }

  if($params{at_end}!=-1 && $params{at_end}!=0 && $params{at_end}!=1 && $params{at_end}!=2){
    die "Invalid backwards value in step2_prop_configure: value -1,0,1 or 2";
  }

  $self->_step2_prop_configuration(\%params);
  $self->threeDSwp_StpCh2PropsSet($params{point_number},
                                  $params{backwards},
                                  $params{at_end},
                                  $params{at_end_val});  
}

sub sweep {
  my ($self, %params) = validated_hash(
    \@_,
    sweep_channel => {isa => "Int"},
    step1_channel => {isa => "Int", optional=>1},
    step2_channel_idx => {isa => "Int", optional=>1},
    step2_channel_name => {isa => "Str", optional=>1},
    aquisition_channels => {isa=>"ArrayRef[Int]"},
    lower_limit_sweep =>{isa=>"Num"},
    upper_limit_sweep =>{isa=>"Num"},
    lower_limit_step1 =>{isa=>"Num",optional=>1},
    upper_limit_step1 =>{isa=>"Num",optional=>1},
    lower_limit_step2 =>{isa=>"Num",optional=>1},
    upper_limit_step2 =>{isa=>"Num",optional=>1},
    point_number_sweep =>{isa=>"Int", optional=>1},
    point_number_step1 =>{isa=>"Int", optional=>1},
    point_number_step2 =>{isa=>"Int", optional=>1},
    series_name => {isa=> "Str", optional=>1},
    comment => {isa=>"Str", optional =>1}
  );
  

  # PARAMETER CONTROLL FOR Sweep Channel, Need to check for maximum channel?

  if(exists($params{point_number_sweep}) && $params{point_number_sweep}!= $self->sweep_prop_configuration()->{point_number}){
    $self->sweep_prop_configure(point_number=>$params{point_number_sweep});
  }
  
  $self->threeDSwp_SwpChSignalSet($params{sweep_channel});
  
  $self->threeDSwp_SwpChLimitsSet($params{lower_limit_sweep},$params{upper_limit_sweep});
  # PARAMETER CONTROLL FOR Step channel 1
  if(exists($params{step1_channel}))
  {
    if($params{step1_channel}>=0)
     {
       if(exists($params{point_number_step1}) && $params{point_number_step1}!= $self->step1_prop_configuration()->{point_number})
       {
          $self->step1_prop_configure(point_number=>$params{point_number_step1});
       }

       if(exists($params{lower_limit_step1}))
       {

        if(exists($params{upper_limit_step1}))
        {
          $self->threeDSwp_StpCh1SignalSet($params{step1_channel});
          $self->threeDSwp_StpCh1LimitsSet($params{lower_limit_step1},$params{upper_limit_step1})
        }
        else
        {
          die "No upper limit supplied to Step Channel 1, upper_limit_step1";  
        }

       }
       else
       {
        die "No lower limit supplied to Step Channel 1, lower_limit_step1";
       }
     }
    else
    {
      die "Invalid value for step1_channel, value must be greter or equal  to 0!"
    }     
  }
  else
  {
    $self->threeDSwp_StpCh1SignalSet(-1);
  }


  # PARAMETER CONTROLL FOR Step channel 2
  if(exists($params{step2_channel_idx}) && exists($params{step2_channel_name}))
  {
    croak "Supply either step2_channel_idx or step2_channel_name";
  }
  elsif(exists($params{step2_channel_idx}) or exists($params{step2_channel_name}))
  { 
    if (exists($params{step2_channel_idx}))
    {
      $params{step2_channel_name}=" ";
    }
    elsif(exists($params{step2_channel_name}))
    {
      $params{step2_channel_idx}=-1;
    }
    if($params{step2_channel_idx}>=0 or $params{step2_channel_name} ne " ")
     { 
       if(exists($params{point_number_step2}) && $params{point_number_step2}!= $self->step2_prop_configuration()->{point_number})
       {
          $self->step2_prop_configure(point_number=>$params{point_number_step2});
       }

       if(exists($params{lower_limit_step2}))
       {

        if(exists($params{upper_limit_step2}))
        { 
          if($params{step2_channel_idx}>=0)
          {
            $self->threeDSwp_StpCh2SignalSet($self->outputs->{$params{step2_channel_idx}});
          }
          elsif($params{step2_channel_name} ne " ")
          {
            $self->threeDSwp_StpCh2SignalSet($params{step2_channel_name});
          }
          $self->threeDSwp_StpCh2LimitsSet($params{lower_limit_step2},$params{upper_limit_step2})
        }
        else
        {
          die "No upper limit supplied to Step Channel 2, upper_limit_step2";  
        }

       }
       else
       {
        die "No lower limit supplied to Step Channel 2, lower_limit_step2";
       }
     }
    else
    {
      die "Invalid value for step2_channel_idx, value must be greter or equal  to 0!"
    }     
  }
  else
  {
    $self->threeDSwp_StpCh2SignalSet(" ");
  }

  if(exists($params{series_name})&& $params{series_name} ne $self->sweep_save_configuration()->{series_name}){
    $self->sweep_save_configure(series_name=>$params{series_name});
  }

  if(exists($params{comment})&& ($params{comment} ne $self->sweep_save_configuration()->{comment})){
    $self->sweep_save_configure(comment=>$params{comment});
  }
  $self->threeDSwp_AcqChsSet($params{aquisition_channels});
  #Still unclear what is happenig here  ://///// 
  sleep(1);
  $self->threeDSwp_Start();

  while($self->threeDSwp_StatusGet()!=0 && $self->threeDSwp_StatusGet()!=2)
  {
    sleep(0.1);
  }
}

sub to_pdl_1D{
    my ($self,%params) =  validated_hash(
      \@_,
      file_name=>{isa => "Str"},
      session_path=>{isa => "Str", optional =>1},
    );

    #check for file existence
    if(exists($params{session_path}))
    {
      $self->set_Session_Path(value=>$params{session_path});
    } 
    if($self->Session_Path() ne '')
    {
      if(-s $self->Session_Path().'/'.$params{file_name})
      {
        my $startdata = 0;
        my @x_col = ();
        my @y_col  = ();
        my $EOF=1; 
        my $buffer_line;
        my @col_names;
        my @cols;
        open(my $fa,'<',$self->Session_Path().'/'.$params{file_name});
        while($EOF)
        {
          $buffer_line=<$fa>;
          if($buffer_line)
          {
              if ($buffer_line =~ /(\[DATA])/){
                  $buffer_line = <$fa>;
                  @col_names = (split "\t",$buffer_line);
                  $buffer_line=<$fa>;
                  $startdata = 1;
              }
              if ($startdata==1){ 
                  my @buffer = split(" ",$buffer_line);

                  for(my $index=0;$index<scalar(@buffer);$index++)
                  {
                    push(@{$cols[$index]},$buffer[$index]);
                  }
              }
          }
          else
          {
              $EOF=0;
          }
        }
        close($fa);
        #my $new_pdl = pdl(pdl(@x_col),pdl(@y_col));
        my $new_pdl = pdl(@cols);
        return $new_pdl,@col_names; 
      }
      else
      {
        die "File not found at ".$self->Session_Path()."/".$params{file_name};
      }
    }
    else
    {
      die "Error: Session_Path is not set";
    }
  return 0;
  }
 
__PACKAGE__->meta()->make_immutable();

1;
