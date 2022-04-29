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


sub threeDSwp_Start{
  my $self = shift;
  my $command_name= "3dswp.start";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub threeDSwp_Stop{
  my $self = shift;
  my $command_name= "3dswp.stop";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub threeDSwp_Open{
  my $self = shift;
  my $command_name= "3dswp.open";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub threeDSwp_StatusGet{
  my $self = shift;
  my $command_name= "3dswp.statusget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Status= substr $return,40,4;
  $Status= unpack("N",$Status);
  return($Status);
}
sub threeDSwp_SwpChSignalSet{
  my $self = shift;
  my $command_name= "3dswp.swpchsignalset";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Sweep_channel_index= substr $return,40,4;
  $Sweep_channel_index= unpack("N!",$Sweep_channel_index);
  return($Sweep_channel_index);
}
sub threeDSwp_SwpChLimitsSet{
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.swpchlimitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
}
sub threeDSwp_SwpChLimitsGet{
  my $self = shift;
  my $command_name= "3dswp.swpchlimitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Start= substr $return,40,4;
  $Start= unpack("f>",$Start);
  my $Stop= substr $return,44,4;
  $Stop= unpack("f>",$Stop);
  return($Start,$Stop);
}
sub threeDSwp_SwpChPropsSet{
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
sub threeDSwp_SwpChPropsGet{
  my $self = shift;
  my $command_name= "3dswp.swpchpropsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
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
sub threeDSwp_SwpChTimingSet{
  my $self = shift;
  my ($Initial_settling_time_s,$Settling_time_s,$Integration_time_s,$End_settling_time_s,$s)= @_;
  my $command_name= "3dswp.swpchtimingset";
  my $bodysize = 20;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($Settling_time_s);
  $body=$body.nt_float32($Integration_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($s);
  $self->write(command=>$head.$body);
}
sub threeDSwp_SwpChTimingGet{
  my $self = shift;
  my $command_name= "3dswp.swpchtimingget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Initial_settling_time_s= substr $return,40,4;
  $Initial_settling_time_s= unpack("f>",$Initial_settling_time_s);
  my $Settling_time_s= substr $return,44,4;
  $Settling_time_s= unpack("f>",$Settling_time_s);
  my $Integration_time_s= substr $return,48,4;
  $Integration_time_s= unpack("f>",$Integration_time_s);
  my $End_settling_time_s= substr $return,52,4;
  $End_settling_time_s= unpack("f>",$End_settling_time_s);
  my $s= substr $return,56,4;
  $s= unpack("f>",$s);
  return($Initial_settling_time_s,$Settling_time_s,$Integration_time_s,$End_settling_time_s,$s);
}
sub threeDSwp_StpCh1SignalSet{
  my $self = shift;
  my $command_name= "3dswp.stpch1signalset";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Step_channel_1_index= substr $return,40,4;
  $Step_channel_1_index= unpack("N!",$Step_channel_1_index);
  return($Step_channel_1_index);
}
sub threeDSwp_StpCh1LimitsSet{
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.stpch1limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
}
sub threeDSwp_StpCh1LimitsGet{
  my $self = shift;
  my $command_name= "3dswp.stpch1limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Start= substr $return,40,4;
  $Start= unpack("f>",$Start);
  my $Stop= substr $return,44,4;
  $Stop= unpack("f>",$Stop);
  return($Start,$Stop);
}
sub threeDSwp_StpCh1PropsSet{
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
sub threeDSwp_StpCh1PropsGet{
  my $self = shift;
  my $command_name= "3dswp.stpch1propsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
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
sub threeDSwp_StpCh1TimingSet{
  my $self = shift;
  my ($Initial_settling_time_s,$End_settling_time_s,$s)= @_;
  my $command_name= "3dswp.stpch1timingset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($s);
  $self->write(command=>$head.$body);
}
sub threeDSwp_StpCh1TimingGet{
  my $self = shift;
  my $command_name= "3dswp.stpch1timingget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Initial_settling_time_s= substr $return,40,4;
  $Initial_settling_time_s= unpack("f>",$Initial_settling_time_s);
  my $End_settling_time_s= substr $return,44,4;
  $End_settling_time_s= unpack("f>",$End_settling_time_s);
  my $s= substr $return,48,4;
  $s= unpack("f>",$s);
  return($Initial_settling_time_s,$End_settling_time_s,$s);
}
sub threeDSwp_StpCh2LimitsSet{
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.stpch2limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
}
sub threeDSwp_StpCh2LimitsGet{
  my $self = shift;
  my $command_name= "3dswp.stpch2limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Start= substr $return,40,4;
  $Start= unpack("f>",$Start);
  my $Stop= substr $return,44,4;
  $Stop= unpack("f>",$Stop);
  return($Start,$Stop);
}
sub threeDSwp_StpCh2PropsSet{
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
sub threeDSwp_StpCh2PropsGet{
  my $self = shift;
  my $command_name= "3dswp.stpch2propsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
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
sub threeDSwp_StpCh2TimingSet{
  my $self = shift;
  my ($Initial_settling_time_s,$End_settling_time_s,$s)= @_;
  my $command_name= "3dswp.stpch2timingset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($s);
  $self->write(command=>$head.$body);
}
sub threeDSwp_StpCh2TimingGet{
  my $self = shift;
  my $command_name= "3dswp.stpch2timingget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Initial_settling_time_s= substr $return,40,4;
  $Initial_settling_time_s= unpack("f>",$Initial_settling_time_s);
  my $End_settling_time_s= substr $return,44,4;
  $End_settling_time_s= unpack("f>",$End_settling_time_s);
  my $s= substr $return,48,4;
  $s= unpack("f>",$s);
  return($Initial_settling_time_s,$End_settling_time_s,$s);
}
sub threeDSwp_TimingRowLimitSet{
  my $self = shift;
  my ($Row_index,$Maximum_time_seconds,$Channel_index)= @_;
  my $command_name= "3dswp.timingrowlimitset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Row_index);
  $body=$body.nt_float32($Maximum_time_seconds);
  $body=$body.nt_int($Channel_index);
  $self->write(command=>$head.$body);
}
sub threeDSwp_TimingRowMethodsSet{
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
sub threeDSwp_TimingRowMethodsGet{
  my $self = shift;
  my ($Row_index)= @_;
  my $command_name= "3dswp.timingrowmethodsget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Row_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
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
sub threeDSwp_TimingRowValsSet{
  my $self = shift;
  my ($Row_index,$_from,$_value,$_to)= @_;
  my $command_name= "3dswp.timingrowvalsset";
  my $bodysize = 16;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Row_index);
  $body=$body.nt_float32($_from);
  $body=$body.nt_float32($_value);
  $body=$body.nt_float32($_to);
  $self->write(command=>$head.$body);
}
sub threeDSwp_TimingRowValsGet{
  my $self = shift;
  my ($Row_index)= @_;
  my $command_name= "3dswp.timingrowvalsget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Row_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $_from= substr $return,40,4;
  $_from= unpack("f>",$_from);
  my $_value= substr $return,44,4;
  $_value= unpack("f>",$_value);
  my $_to= substr $return,48,4;
  $_to= unpack("f>",$_to);
  return($_from,$_value,$_to);
}
sub threeDSwp_TimingEnable{
  my $self = shift;
  my ($Enable)= @_;
  my $command_name= "3dswp.timingenable";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint32($Enable);
  $self->write(command=>$head.$body);
}
sub threeDSwp_TimingSend{
  my $self = shift;
  my $command_name= "3dswp.timingsend";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub oneDSwp_LimitsSet{
  my $self = shift;
  my ($Lower_limit,$Upper_limit)= @_;
  my $command_name= "1dswp.limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Lower_limit);
  $body=$body.nt_float32($Upper_limit);
  $self->write(command=>$head.$body);
}
sub oneDSwp_LimitsGet{
  my $self = shift;
  my $command_name= "1dswp.limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Lower_limit= substr $return,40,4;
  $Lower_limit= unpack("f>",$Lower_limit);
  my $Upper_limit= substr $return,44,4;
  $Upper_limit= unpack("f>",$Upper_limit);
  return($Lower_limit,$Upper_limit);
}
sub oneDSwp_PropsSet{
  my $self = shift;
  my ($Initial_Settling_time_ms,$s,$Number_of_steps,$Period_ms,$Autosave,$Save_dialog_box,$Settling_time_ms)= @_;
  my $command_name= "1dswp.propsset";
  my $bodysize = 26;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_Settling_time_ms);
  $body=$body.nt_float32($s);
  $body=$body.nt_int($Number_of_steps);
  $body=$body.nt_uint16($Period_ms);
  $body=$body.nt_int($Autosave);
  $body=$body.nt_int($Save_dialog_box);
  $body=$body.nt_float32($Settling_time_ms);
  $self->write(command=>$head.$body);
}
sub oneDSwp_PropsGet{
  my $self = shift;
  my $command_name= "1dswp.propsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
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
sub oneDSwp_Stop{
  my $self = shift;
  my $command_name= "1dswp.stop";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub oneDSwp_Open{
  my $self = shift;
  my $command_name= "1dswp.open";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub Signals_InSlotSet{
  my $self = shift;
  my ($Slot,$RT_signal_index)= @_;
  my $command_name= "signals.inslotset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Slot);
  $body=$body.nt_int($RT_signal_index);
  $self->write(command=>$head.$body);
}
sub Signals_CalibrGet{
  my $self = shift;
  my ($Signal_index)= @_;
  my $command_name= "signals.calibrget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Signal_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Calibration_per_volt= substr $return,40,4;
  $Calibration_per_volt= unpack("f>",$Calibration_per_volt);
  my $Offset_in_physical_units= substr $return,44,4;
  $Offset_in_physical_units= unpack("f>",$Offset_in_physical_units);
  return($Calibration_per_volt,$Offset_in_physical_units);
}
sub Signals_RangeGet{
  my $self = shift;
  my ($Signal_index)= @_;
  my $command_name= "signals.rangeget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Signal_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Maximum_limit= substr $return,40,4;
  $Maximum_limit= unpack("f>",$Maximum_limit);
  my $Minimum_limit= substr $return,44,4;
  $Minimum_limit= unpack("f>",$Minimum_limit);
  return($Maximum_limit,$Minimum_limit);
}
sub Signals_ValGet{
  my $self = shift;
  my ($Signal_index,$Wait_for_newest_data)= @_;
  my $command_name= "signals.valget";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Signal_index);
  $body=$body.nt_uint32($Wait_for_newest_data);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Signal_value= substr $return,40,4;
  $Signal_value= unpack("f>",$Signal_value);
  return($Signal_value);
}
sub Signals_AddRTSet{
  my $self = shift;
  my ($Additional_RT_signal_1,$Additional_RT_signal_2)= @_;
  my $command_name= "signals.addrtset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Additional_RT_signal_1);
  $body=$body.nt_int($Additional_RT_signal_2);
  $self->write(command=>$head.$body);
}
sub UserIn_CalibrSet{
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
sub UserOut_ModeSet{
  my $self = shift;
  my ($Output_index,$Output_mode)= @_;
  my $command_name= "userout.modeset";
  my $bodysize = 6;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_uint16($Output_mode);
  $self->write(command=>$head.$body);
}
sub UserOut_ModeGet{
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.modeget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Output_mode= substr $return,40,2;
  $Output_mode= unpack("n",$Output_mode);
  return($Output_mode);
}
sub UserOut_MonitorChSet{
  my $self = shift;
  my ($Output_index,$Monitor_channel_index)= @_;
  my $command_name= "userout.monitorchset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_int($Monitor_channel_index);
  $self->write(command=>$head.$body);
}
sub UserOut_MonitorChGet{
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.monitorchget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Monitor_channel_index= substr $return,40,4;
  $Monitor_channel_index= unpack("N!",$Monitor_channel_index);
  return($Monitor_channel_index);
}
sub UserOut_ValSet{
  my $self = shift;
  my ($Output_index,$Output_value)= @_;
  my $command_name= "userout.valset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_float32($Output_value);
  $self->write(command=>$head.$body);
}
sub UserOut_CalibrSet{
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
sub UserOut_CalcSignalConfigSet{
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
sub UserOut_CalcSignalConfigGet{
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.calcsignalconfigget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
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
sub UserOut_LimitsSet{
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
sub UserOut_LimitsGet{
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.limitsget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Upper_limit= substr $return,40,4;
  $Upper_limit= unpack("f>",$Upper_limit);
  my $Lower_limit= substr $return,44,4;
  $Lower_limit= unpack("f>",$Lower_limit);
  return($Upper_limit,$Lower_limit);
}
sub UserOut_SlewRateSet{
  my $self = shift;
  my ($Output_index,$Slew_Rate)= @_;
  my $command_name= "userout.slewrateset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Output_index);
  $body=$body.nt_float64($Slew_Rate);
  $self->write(command=>$head.$body);
}
sub UserOut_SlewRateGet{
  my $self = shift;
  my ($Output_index)= @_;
  my $command_name= "userout.slewrateget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Output_index);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Slew_Rate= substr $return,40,8;
  $Slew_Rate= unpack("d>",$Slew_Rate);
  return($Slew_Rate);
}
sub DigLines_PropsSet{
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
sub DigLines_OutStatusSet{
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
sub DataLog_Open{
  my $self = shift;
  my $command_name= "datalog.open";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub DataLog_Start{
  my $self = shift;
  my $command_name= "datalog.start";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub DataLog_Stop{
  my $self = shift;
  my $command_name= "datalog.stop";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub TCPLog_Start{
  my $self = shift;
  my $command_name= "tcplog.start";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub TCPLog_Stop{
  my $self = shift;
  my $command_name= "tcplog.stop";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub TCPLog_OversamplSet{
  my $self = shift;
  my $command_name= "tcplog.oversamplset";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Oversampling_value= substr $return,40,4;
  $Oversampling_value= unpack("N!",$Oversampling_value);
  return($Oversampling_value);
}
sub TCPLog_StatusGet{
  my $self = shift;
  my $command_name= "tcplog.statusget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Status= substr $return,40,4;
  $Status= unpack("N!",$Status);
  return($Status);
}
sub OsciHR_ChSet{
  my $self = shift;
  my $command_name= "oscihr.chset";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Channel_index= substr $return,40,4;
  $Channel_index= unpack("N!",$Channel_index);
  return($Channel_index);
}
sub OsciHR_ChGet{
  my $self = shift;
  my $command_name= "oscihr.chget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Channel_index= substr $return,40,4;
  $Channel_index= unpack("N!",$Channel_index);
  return($Channel_index);
}
sub OsciHR_OversamplSet{
  my $self = shift;
  my $command_name= "oscihr.oversamplset";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Oversampling_index= substr $return,40,4;
  $Oversampling_index= unpack("N!",$Oversampling_index);
  return($Oversampling_index);
}
sub OsciHR_OversamplGet{
  my $self = shift;
  my $command_name= "oscihr.oversamplget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Oversampling_index= substr $return,40,4;
  $Oversampling_index= unpack("N!",$Oversampling_index);
  return($Oversampling_index);
}
sub OsciHR_CalibrModeSet{
  my $self = shift;
  my $command_name= "oscihr.calibrmodeset";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Calibration_mode= substr $return,40,2;
  $Calibration_mode= unpack("n",$Calibration_mode);
  return($Calibration_mode);
}
sub OsciHR_CalibrModeGet{
  my $self = shift;
  my $command_name= "oscihr.calibrmodeget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Calibration_mode= substr $return,40,2;
  $Calibration_mode= unpack("n",$Calibration_mode);
  return($Calibration_mode);
}
sub OsciHR_SamplesSet{
  my $self = shift;
  my ($Number_of_samples)= @_;
  my $command_name= "oscihr.samplesset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Number_of_samples);
  $self->write(command=>$head.$body);
}
sub OsciHR_SamplesGet{
  my $self = shift;
  my $command_name= "oscihr.samplesget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Number_of_samples= substr $return,40,4;
  $Number_of_samples= unpack("N!",$Number_of_samples);
  return($Number_of_samples);
}
sub OsciHR_PreTrigSet{
  my $self = shift;
  my ($Trigger_samples,$Trigger_s)= @_;
  my $command_name= "oscihr.pretrigset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint32($Trigger_samples);
  $body=$body.nt_float64($Trigger_s);
  $self->write(command=>$head.$body);
}
sub OsciHR_PreTrigGet{
  my $self = shift;
  my $command_name= "oscihr.pretrigget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Trigger_samples= substr $return,40,4;
  $Trigger_samples= unpack("N!",$Trigger_samples);
  return($Trigger_samples);
}
sub OsciHR_Run{
  my $self = shift;
  my $command_name= "oscihr.run";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub OsciHR_TrigModeSet{
  my $self = shift;
  my ($Trigger_mode)= @_;
  my $command_name= "oscihr.trigmodeset";
  my $bodysize = 2;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint16($Trigger_mode);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigModeGet{
  my $self = shift;
  my $command_name= "oscihr.trigmodeget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Trigger_mode= substr $return,40,2;
  $Trigger_mode= unpack("n",$Trigger_mode);
  return($Trigger_mode);
}
sub OsciHR_TrigLevChSet{
  my $self = shift;
  my ($Level_trigger_channel_index)= @_;
  my $command_name= "oscihr.triglevchset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Level_trigger_channel_index);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigLevChGet{
  my $self = shift;
  my $command_name= "oscihr.triglevchget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Level_trigger_channel_index= substr $return,40,4;
  $Level_trigger_channel_index= unpack("N!",$Level_trigger_channel_index);
  return($Level_trigger_channel_index);
}
sub OsciHR_TrigLevValSet{
  my $self = shift;
  my ($Level_trigger_value)= @_;
  my $command_name= "oscihr.triglevvalset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float64($Level_trigger_value);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigLevValGet{
  my $self = shift;
  my $command_name= "oscihr.triglevvalget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Level_trigger_value= substr $return,40,8;
  $Level_trigger_value= unpack("d>",$Level_trigger_value);
  return($Level_trigger_value);
}
sub OsciHR_TrigLevHystSet{
  my $self = shift;
  my ($Level_trigger_Hysteresis)= @_;
  my $command_name= "oscihr.triglevhystset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float64($Level_trigger_Hysteresis);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigLevHystGet{
  my $self = shift;
  my $command_name= "oscihr.triglevhystget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Level_trigger_Hysteresis= substr $return,40,8;
  $Level_trigger_Hysteresis= unpack("d>",$Level_trigger_Hysteresis);
  return($Level_trigger_Hysteresis);
}
sub OsciHR_TrigLevSlopeSet{
  my $self = shift;
  my ($Level_trigger_slope)= @_;
  my $command_name= "oscihr.triglevslopeset";
  my $bodysize = 2;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint16($Level_trigger_slope);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigLevSlopeGet{
  my $self = shift;
  my $command_name= "oscihr.triglevslopeget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Level_trigger_slope= substr $return,40,2;
  $Level_trigger_slope= unpack("n",$Level_trigger_slope);
  return($Level_trigger_slope);
}
sub OsciHR_TrigDigChSet{
  my $self = shift;
  my ($Digital_trigger_channel_index)= @_;
  my $command_name= "oscihr.trigdigchset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Digital_trigger_channel_index);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigDigChGet{
  my $self = shift;
  my $command_name= "oscihr.trigdigchget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Digital_trigger_channel_index= substr $return,40,4;
  $Digital_trigger_channel_index= unpack("N!",$Digital_trigger_channel_index);
  return($Digital_trigger_channel_index);
}
sub OsciHR_TrigArmModeSet{
  my $self = shift;
  my ($Trigger_arming_mode)= @_;
  my $command_name= "oscihr.trigarmmodeset";
  my $bodysize = 2;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint16($Trigger_arming_mode);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigArmModeGet{
  my $self = shift;
  my $command_name= "oscihr.trigarmmodeget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Trigger_arming_mode= substr $return,40,2;
  $Trigger_arming_mode= unpack("n",$Trigger_arming_mode);
  return($Trigger_arming_mode);
}
sub OsciHR_TrigDigSlopeSet{
  my $self = shift;
  my ($Digital_trigger_slope)= @_;
  my $command_name= "oscihr.trigdigslopeset";
  my $bodysize = 2;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint16($Digital_trigger_slope);
  $self->write(command=>$head.$body);
}
sub OsciHR_TrigDigSlopeGet{
  my $self = shift;
  my $command_name= "oscihr.trigdigslopeget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Digital_trigger_slope= substr $return,40,2;
  $Digital_trigger_slope= unpack("n",$Digital_trigger_slope);
  return($Digital_trigger_slope);
}
sub OsciHR_TrigRearm{
  my $self = shift;
  my $command_name= "oscihr.trigrearm";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub OsciHR_PSDShow{
  my $self = shift;
  my ($Show_PSD_section)= @_;
  my $command_name= "oscihr.psdshow";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint32($Show_PSD_section);
  $self->write(command=>$head.$body);
}
sub OsciHR_PSDWeightSet{
  my $self = shift;
  my ($PSD_Weighting)= @_;
  my $command_name= "oscihr.psdweightset";
  my $bodysize = 2;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint16($PSD_Weighting);
  $self->write(command=>$head.$body);
}
sub OsciHR_PSDWeightGet{
  my $self = shift;
  my $command_name= "oscihr.psdweightget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $PSD_Weighting= substr $return,40,2;
  $PSD_Weighting= unpack("n",$PSD_Weighting);
  return($PSD_Weighting);
}
sub OsciHR_PSDWindowSet{
  my $self = shift;
  my ($PSD_window_type)= @_;
  my $command_name= "oscihr.psdwindowset";
  my $bodysize = 2;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint16($PSD_window_type);
  $self->write(command=>$head.$body);
}
sub OsciHR_PSDWindowGet{
  my $self = shift;
  my $command_name= "oscihr.psdwindowget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $PSD_window_type= substr $return,40,2;
  $PSD_window_type= unpack("n",$PSD_window_type);
  return($PSD_window_type);
}
sub OsciHR_PSDAvrgTypeSet{
  my $self = shift;
  my $command_name= "oscihr.psdavrgtypeset";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $PSD_averaging_type= substr $return,40,2;
  $PSD_averaging_type= unpack("n",$PSD_averaging_type);
  return($PSD_averaging_type);
}
sub OsciHR_PSDAvrgTypeGet{
  my $self = shift;
  my $command_name= "oscihr.psdavrgtypeget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $PSD_averaging_type= substr $return,40,2;
  $PSD_averaging_type= unpack("n",$PSD_averaging_type);
  return($PSD_averaging_type);
}
sub OsciHR_PSDAvrgCountSet{
  my $self = shift;
  my ($PSD_averaging_count)= @_;
  my $command_name= "oscihr.psdavrgcountset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($PSD_averaging_count);
  $self->write(command=>$head.$body);
}
sub OsciHR_PSDAvrgCountGet{
  my $self = shift;
  my $command_name= "oscihr.psdavrgcountget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $PSD_averaging_count= substr $return,40,4;
  $PSD_averaging_count= unpack("N!",$PSD_averaging_count);
  return($PSD_averaging_count);
}
sub OsciHR_PSDAvrgRestart{
  my $self = shift;
  my $command_name= "oscihr.psdavrgrestart";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub Script_Deploy{
  my $self = shift;
  my ($Script_index)= @_;
  my $command_name= "script.deploy";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Script_index);
  $self->write(command=>$head.$body);
}
sub Script_Undeploy{
  my $self = shift;
  my ($Script_index)= @_;
  my $command_name= "script.undeploy";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Script_index);
  $self->write(command=>$head.$body);
}
sub Script_Run{
  my $self = shift;
  my ($Script_index,$Wait_until_script_finishes)= @_;
  my $command_name= "script.run";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Script_index);
  $body=$body.nt_uint32($Wait_until_script_finishes);
  $self->write(command=>$head.$body);
}
sub Script_Stop{
  my $self = shift;
  my $command_name= "script.stop";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub Script_DataGet{
  my $self = shift;
  my ($Acquire_buffer,$Sweep_number)= @_;
  my $command_name= "script.dataget";
  my $bodysize = 6;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_uint16($Acquire_buffer);
  $body=$body.nt_int($Sweep_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Data_rows= substr $return,40,4;
  $Data_rows= unpack("N!",$Data_rows);
  my $Data_columns= substr $return,44,4;
  $Data_columns= unpack("N!",$Data_columns);
  return($Data_rows,$Data_columns);
}
sub Script_Autosave{
  my $self = shift;
  my ($Acquire_buffer,$Sweep_number,$All_sweeps_to_same_file)= @_;
  my $command_name= "script.autosave";
  my $bodysize = 10;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_uint16($Acquire_buffer);
  $body=$body.nt_int($Sweep_number);
  $body=$body.nt_uint32($All_sweeps_to_same_file);
  $self->write(command=>$head.$body);
}
sub LockIn_ModOnOffSet{
  my $self = shift;
  my ($Modulator_number,$Off)= @_;
  my $command_name= "lockin.modonoffset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Modulator_number);
  $body=$body.nt_uint32($Off);
  $self->write(command=>$head.$body);
}
sub LockIn_ModOnOffGet{
  my $self = shift;
  my ($Modulator_number)= @_;
  my $command_name= "lockin.modonoffget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Modulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Off= substr $return,40,4;
  $Off= unpack("N",$Off);
  return($Off);
}
sub LockIn_ModSignalSet{
  my $self = shift;
  my ($Modulator_number,$Modulator_Signal_Index)= @_;
  my $command_name= "lockin.modsignalset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Modulator_number);
  $body=$body.nt_int($Modulator_Signal_Index);
  $self->write(command=>$head.$body);
}
sub LockIn_ModSignalGet{
  my $self = shift;
  my ($Modulator_number)= @_;
  my $command_name= "lockin.modsignalget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Modulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Modulator_Signal_Index= substr $return,40,4;
  $Modulator_Signal_Index= unpack("N!",$Modulator_Signal_Index);
  return($Modulator_Signal_Index);
}
sub LockIn_ModPhasRegSet{
  my $self = shift;
  my ($Modulator_number,$Phase_Register_Index)= @_;
  my $command_name= "lockin.modphasregset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Modulator_number);
  $body=$body.nt_int($Phase_Register_Index);
  $self->write(command=>$head.$body);
}
sub LockIn_ModPhasRegGet{
  my $self = shift;
  my ($Modulator_number)= @_;
  my $command_name= "lockin.modphasregget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Modulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Phase_Register_Index= substr $return,40,4;
  $Phase_Register_Index= unpack("N!",$Phase_Register_Index);
  return($Phase_Register_Index);
}
sub LockIn_ModHarmonicSet{
  my $self = shift;
  my ($Modulator_number,$Harmonic)= @_;
  my $command_name= "lockin.modharmonicset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Modulator_number);
  $body=$body.nt_int($Harmonic);
  $self->write(command=>$head.$body);
}
sub LockIn_ModHarmonicGet{
  my $self = shift;
  my ($Modulator_number)= @_;
  my $command_name= "lockin.modharmonicget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Modulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Harmonic= substr $return,40,4;
  $Harmonic= unpack("N!",$Harmonic);
  return($Harmonic);
}
sub LockIn_ModPhasSet{
  my $self = shift;
  my ($Modulator_number,$Phase_deg)= @_;
  my $command_name= "lockin.modphasset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Modulator_number);
  $body=$body.nt_float32($Phase_deg);
  $self->write(command=>$head.$body);
}
sub LockIn_ModPhasGet{
  my $self = shift;
  my ($Modulator_number)= @_;
  my $command_name= "lockin.modphasget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Modulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Phase_deg= substr $return,40,4;
  $Phase_deg= unpack("f>",$Phase_deg);
  return($Phase_deg);
}
sub LockIn_ModAmpSet{
  my $self = shift;
  my ($Modulator_number,$Amplitude)= @_;
  my $command_name= "lockin.modampset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Modulator_number);
  $body=$body.nt_float32($Amplitude);
  $self->write(command=>$head.$body);
}
sub LockIn_ModAmpGet{
  my $self = shift;
  my ($Modulator_number)= @_;
  my $command_name= "lockin.modampget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Modulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Amplitude= substr $return,40,4;
  $Amplitude= unpack("f>",$Amplitude);
  return($Amplitude);
}
sub LockIn_ModPhasFreqSet{
  my $self = shift;
  my ($Modulator_number,$Frequency_Hz)= @_;
  my $command_name= "lockin.modphasfreqset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Modulator_number);
  $body=$body.nt_float64($Frequency_Hz);
  $self->write(command=>$head.$body);
}
sub LockIn_ModPhasFreqGet{
  my $self = shift;
  my ($Modulator_number)= @_;
  my $command_name= "lockin.modphasfreqget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Modulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Frequency_Hz= substr $return,40,8;
  $Frequency_Hz= unpack("d>",$Frequency_Hz);
  return($Frequency_Hz);
}
sub LockIn_DemodSignalSet{
  my $self = shift;
  my ($Demodulator_number,$Demodulator_Signal_Index)= @_;
  my $command_name= "lockin.demodsignalset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_int($Demodulator_Signal_Index);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodSignalGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodsignalget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Demodulator_Signal_Index= substr $return,40,4;
  $Demodulator_Signal_Index= unpack("N!",$Demodulator_Signal_Index);
  return($Demodulator_Signal_Index);
}
sub LockIn_DemodHarmonicSet{
  my $self = shift;
  my ($Demodulator_number,$Harmonic)= @_;
  my $command_name= "lockin.demodharmonicset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_int($Harmonic);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodHarmonicGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodharmonicget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Harmonic= substr $return,40,4;
  $Harmonic= unpack("N!",$Harmonic);
  return($Harmonic);
}
sub LockIn_DemodHPFilterSet{
  my $self = shift;
  my ($Demodulator_number,$HP_Filter_Order,$HP_Filter_Cutoff_Frequency_Hz)= @_;
  my $command_name= "lockin.demodhpfilterset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_int($HP_Filter_Order);
  $body=$body.nt_float32($HP_Filter_Cutoff_Frequency_Hz);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodHPFilterGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodhpfilterget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $HP_Filter_Order= substr $return,40,4;
  $HP_Filter_Order= unpack("N!",$HP_Filter_Order);
  my $HP_Filter_Cutoff_Frequency_Hz= substr $return,44,4;
  $HP_Filter_Cutoff_Frequency_Hz= unpack("f>",$HP_Filter_Cutoff_Frequency_Hz);
  return($HP_Filter_Order,$HP_Filter_Cutoff_Frequency_Hz);
}
sub LockIn_DemodLPFilterSet{
  my $self = shift;
  my ($Demodulator_number,$LP_Filter_Order,$LP_Filter_Cutoff_Frequency_Hz)= @_;
  my $command_name= "lockin.demodlpfilterset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_int($LP_Filter_Order);
  $body=$body.nt_float32($LP_Filter_Cutoff_Frequency_Hz);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodLPFilterGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodlpfilterget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $LP_Filter_Order= substr $return,40,4;
  $LP_Filter_Order= unpack("N!",$LP_Filter_Order);
  my $LP_Filter_Cutoff_Frequency_Hz= substr $return,44,4;
  $LP_Filter_Cutoff_Frequency_Hz= unpack("f>",$LP_Filter_Cutoff_Frequency_Hz);
  return($LP_Filter_Order,$LP_Filter_Cutoff_Frequency_Hz);
}
sub LockIn_DemodPhasRegSet{
  my $self = shift;
  my ($Demodulator_number,$Phase_Register_Index)= @_;
  my $command_name= "lockin.demodphasregset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_int($Phase_Register_Index);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodPhasRegGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodphasregget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Phase_Register_Index= substr $return,40,4;
  $Phase_Register_Index= unpack("N!",$Phase_Register_Index);
  return($Phase_Register_Index);
}
sub LockIn_DemodPhasSet{
  my $self = shift;
  my ($Demodulator_number,$Phase_deg)= @_;
  my $command_name= "lockin.demodphasset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_float32($Phase_deg);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodPhasGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodphasget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Phase_deg= substr $return,40,4;
  $Phase_deg= unpack("f>",$Phase_deg);
  return($Phase_deg);
}
sub LockIn_DemodSyncFilterSet{
  my $self = shift;
  my ($Demodulator_number,$Sync_Filter)= @_;
  my $command_name= "lockin.demodsyncfilterset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_uint32($Sync_Filter);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodSyncFilterGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodsyncfilterget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $Sync_Filter= substr $return,40,4;
  $Sync_Filter= unpack("N",$Sync_Filter);
  return($Sync_Filter);
}
sub LockIn_DemodRTSignalsSet{
  my $self = shift;
  my ($Demodulator_number,$RT_Signals)= @_;
  my $command_name= "lockin.demodrtsignalsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Demodulator_number);
  $body=$body.nt_uint32($RT_Signals);
  $self->write(command=>$head.$body);
}
sub LockIn_DemodRTSignalsGet{
  my $self = shift;
  my ($Demodulator_number)= @_;
  my $command_name= "lockin.demodrtsignalsget";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body=nt_int($Demodulator_number);
  $self->write(command=>$head.$body);
  my $return = $self->read(); 
  my $RT_Signals= substr $return,40,4;
  $RT_Signals= unpack("N",$RT_Signals);
  return($RT_Signals);
}
sub LockInFreqSwp_Open{
  my $self = shift;
  my $command_name= "lockinfreqswp.open";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub LockInFreqSwp_SignalSet{
  my $self = shift;
  my ($Sweep_signal_index)= @_;
  my $command_name= "lockinfreqswp.signalset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($Sweep_signal_index);
  $self->write(command=>$head.$body);
}
sub LockInFreqSwp_SignalGet{
  my $self = shift;
  my $command_name= "lockinfreqswp.signalget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Sweep_signal_index= substr $return,40,4;
  $Sweep_signal_index= unpack("N!",$Sweep_signal_index);
  return($Sweep_signal_index);
}
sub LockInFreqSwp_LimitsSet{
  my $self = shift;
  my ($Lower_limit_Hz,$Upper_limit_Hz)= @_;
  my $command_name= "lockinfreqswp.limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Lower_limit_Hz);
  $body=$body.nt_float32($Upper_limit_Hz);
  $self->write(command=>$head.$body);
}
sub LockInFreqSwp_LimitsGet{
  my $self = shift;
  my $command_name= "lockinfreqswp.limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Lower_limit_Hz= substr $return,40,4;
  $Lower_limit_Hz= unpack("f>",$Lower_limit_Hz);
  my $Upper_limit_Hz= substr $return,44,4;
  $Upper_limit_Hz= unpack("f>",$Upper_limit_Hz);
  return($Lower_limit_Hz,$Upper_limit_Hz);
}
sub Util_Lock{
  my $self = shift;
  my $command_name= "util.lock";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub Util_UnLock{
  my $self = shift;
  my $command_name= "util.unlock";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}
sub Util_RTFreqSet{
  my $self = shift;
  my ($RT_frequency)= @_;
  my $command_name= "util.rtfreqset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($RT_frequency);
  $self->write(command=>$head.$body);
}
sub Util_RTFreqGet{
  my $self = shift;
  my $command_name= "util.rtfreqget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $RT_frequency= substr $return,40,4;
  $RT_frequency= unpack("f>",$RT_frequency);
  return($RT_frequency);
}
sub Util_AcqPeriodSet{
  my $self = shift;
  my ($Acquisition_Period_s)= @_;
  my $command_name= "util.acqperiodset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Acquisition_Period_s);
  $self->write(command=>$head.$body);
}
sub Util_AcqPeriodGet{
  my $self = shift;
  my $command_name= "util.acqperiodget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $Acquisition_Period_s= substr $return,40,4;
  $Acquisition_Period_s= unpack("f>",$Acquisition_Period_s);
  return($Acquisition_Period_s);
}
sub Util_RTOversamplSet{
  my $self = shift;
  my ($RT_oversampling)= @_;
  my $command_name= "util.rtoversamplset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_int($RT_oversampling);
  $self->write(command=>$head.$body);
}
sub Util_RTOversamplGet{
  my $self = shift;
  my $command_name= "util.rtoversamplget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read(); 
  my $RT_oversampling= substr $return,40,4;
  $RT_oversampling= unpack("N!",$RT_oversampling);
  return($RT_oversampling);
}


######

sub swp1d_AcqChsSet{
    my $self = shift;
    my @channels; 
    foreach(@_){
        push @channels,$_;
    }
    my $command_name="1dswp.acqchsset";
    my $bodysize= (2 + $#channels)*4;
    my $head= $self->nt_header($command_name,$bodysize,1);
    #Create body
    my $body= nt_int($#channels+1);
    foreach(@channels){
        $body= $body.nt_int($_);
    }
    $self->write(command=>$head.$body);


}

sub oneDSwp_LimitsSet{
  my $self = shift;
  my ($Lower_limit,$Upper_limit,)= @_;
  my $command_name= "1dswp.limitsset";
  my $bodysize = 8;
  my $head = $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Lower_limit);
  $body=$body.nt_float32($Upper_limit);
  $self->write(command=>$head.$body)
}

sub oneDSwp_LimitsGet{
  my $self = shift;
  my $command_name= "1dswp.limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read();
  my $Lower_limit= substr $return,40,4;
  $Lower_limit= unpack("f>",$Lower_limit);
  my $Upper_limit= substr $return,44,4;
  $Upper_limit= unpack("f>",$Upper_limit);
  return($Lower_limit,$Upper_limit);
}
sub threeDSwp_Start{
  my $self = shift;
  my $command_name= "3dswp.start";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,0);
  $self->write(command=>$head);
}

sub threeDSwp_StpCh1LimitsSet{
  my $self = shift;
  my ($Start,$Stop)= @_;
  my $command_name= "3dswp.stpch1limitsset";
  my $bodysize = 8;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Start);
  $body=$body.nt_float32($Stop);
  $self->write(command=>$head.$body);
}
sub threeDSwp_StpCh1LimitsGet{
  my $self = shift;
  my $command_name= "3dswp.stpch1limitsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read();
  my $Start= substr $return,40,4;
  $Start= unpack("f>",$Start);
  my $Stop= substr $return,44,4;
  $Stop= unpack("f>",$Stop);
  return($Start,$Stop);
}
sub threeDSwp_StpCh1PropsGet{
  my $self = shift;
  my $command_name= "3dswp.stpch1propsget";
  my $bodysize = 0;
  my $head= $self->nt_header($command_name,$bodysize,1);
  $self->write(command=>$head);
  my $return = $self->read();
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

sub threeDSwp_StpCh2TimingSet{
  my $self = shift;
  my ($Initial_settling_time_s,$End_settling_time_s,$s)= @_;
  my $command_name= "3dswp.stpch2timingset";
  my $bodysize = 12;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body=nt_float32($Initial_settling_time_s);
  $body=$body.nt_float32($End_settling_time_s);
  $body=$body.nt_float32($s);
  $self->write(command=>$head.$body);
}   

sub threeDSwp_SwpChSignalSet{
  my $self = shift;
  my $Sweep_channel_index= shift;
  my $command_name= "3dswp.swpchsignalset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,0);
  my $body = $self->nt_int($Sweep_channel_index);
  $self->write(command=>$head.$body);
}

sub threeDSwp_StpCh1SignalSet{
  my $self = shift;
  my $Step_channel_index= shift;
  my $command_name= "3dswp.stpch1signalset";
  my $bodysize = 4;
  my $head= $self->nt_header($command_name,$bodysize,1);
  my $body = $self->nt_int($Step_channel_index);
  $self->write(command=>$head);
}
__PACKAGE__->meta()->make_immutable();

1;