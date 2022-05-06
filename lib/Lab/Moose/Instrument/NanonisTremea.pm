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
#missing AcqChsGet
#1DSwp.SwpSignalSet
#1DSwp.SwpSignalGet

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

  my $return = $self->read(); 
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

#Start missing
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