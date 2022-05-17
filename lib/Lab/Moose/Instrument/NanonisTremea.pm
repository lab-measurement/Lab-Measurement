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
  print(join(",",@intArray));
  #return @intArray;
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