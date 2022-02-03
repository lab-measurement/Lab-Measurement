package Lab::Moose::Instrument::MCL1_540;

#ABSTRACT: Synctek MCL1-540 Lock-in Amplifier

use v5.20;

use strict;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    setter_params
/;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time usleep/;
use LWP::Simple;

extends 'Lab::Moose::Instrument';

# TODO
# ====
# - how is ip address and port configured? 
#   --> port 8002 is fixed
#   --> ip is required for init
# - type checks for write arguments - done
# - URL structure                   - done
# - names of outputs
# - which functions to implement?

has ip => (
	is  => 'ro',
	isa => 'Str',
	required => 1,
);

my $url = "http://$self->ip():8002/MCL/api?";

sub request {
    my ( $self, %args ) = validated_setter( \@_,
        type    => {isa => enum([qw/config data/])},
        id      => {isa => 'Str'},
        action  => {isa => enum([qw/get set/])},
        path    => {isa => 'Str'},
    );
    
    return get($self->url()."type=$type&id=$id&action=$action&path=$path");
}

sub get_L1_DC_0 {
    return $self->request(
        type    => "data",
        id      => "L1",
        action  => "get",
        path    => "/output_cluster/DataReadings/DC[0]/"
    );
}
sub get_L1_X_0 {
    return $self->request(
        type    => "data",
        id      => "L1",
        action  => "get",
        path    => "/output_cluster/DataReadings/X[0]/"
    );
}
sub get_L1_Y_0 {
    return $self->request(
        type    => "data",
        id      => "L1",
        action  => "get",
        path    => "/output_cluster/DataReadings/Y[0]/"
    );
}


    my $i_dc_A = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/DC[10]/");
    my $i_AC_x_A = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/X[10]/"); 
 
    my $i_AC_y_A = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/Y[10]/");
    
    my $i_AC_R_A = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/R[10]/");
    my $i_AC_Theta_A = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/theta_(deg)[10]/");
    
    my $u_osc_A = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/GeneralReadings/Module_data[0]/Module/Amplitude_(Vrms)"); 

    my $output_offset_A = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/GeneralReadings/Module_data[0]/Module/Output_offset_(V)");

    my $u_sample_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/DC[2]/"); 	 #entspricht V1 DC
    
    my $u_AC_sample_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/X[2]/"); #ist das hier dann das u_x? 
    my $u_AC_sample_y_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/Y[2]/"); #ist das hier dann das u_y? 
    
    my $i_dc_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/DC[11]/");
    my $i_AC_x_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/X[11]/"); 

    my $i_AC_y_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/Y[11]/");
    
    my $i_AC_R_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/R[11]/");
    my $i_AC_Theta_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/theta_(deg)[11]/");

    
    my $u_osc_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/GeneralReadings/Module_data[1]/Module/Amplitude_(Vrms)"); 

    my $output_offset_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/GeneralReadings/Module_data[1]/Module/Output_offset_(V)");
	 
