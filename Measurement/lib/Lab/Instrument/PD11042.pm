package Lab::Instrument::PD11042;
our $VERSION = '3.00';

use strict;
use Time::HiRes qw/usleep/, qw/time/;
use Lab::Instrument;

# Opcodes of all TMCL commands that can be used in direct mode
use constant {
  TMCL_ROR  => 1
 ,TMCL_ROL  => 2
 ,TMCL_MST  => 3
 ,TMCL_MVP  => 4
 ,TMCL_SAP  => 5
 ,TMCL_GAP  => 6
 ,TMCL_STAP => 7
 ,TMCL_RSAP => 8
 ,TMCL_SGP  => 9
 ,TMCL_GGP  => 10
 ,TMCL_STGP => 11
 ,TMCL_RSGP => 12
 ,TMCL_RFS  => 13
 ,TMCL_SIO  => 14
 ,TMCL_GIO  => 15
 ,TMCL_SCO  => 30
 ,TMCL_GCO  => 31
 ,TMCL_CCO  => 32
 # Options for MVP commandds
 ,MVP_ABS   => 0
 ,MVP_REL   => 1
 ,MVP_COORD => 2
 # Options for RFS command
 ,RFS_START  => 0
 ,RFS_STOP   => 1
 ,RFS_STATUS => 2
 # Result codes for GetResult
 ,TMCL_RESULT_OK => 0
 ,TMCL_RESULT_NOT_READY => 1
 ,TMCL_RESULT_CHECKSUM_ERROR => 2
 # axis paramter for SAP and GAP
 ,target_position => 0
 ,actual_position => 1
 ,target_speed => 2
 ,actual_speed => 3
 ,maximum_positioning_speed => 4
 ,maximum_acceleration => 5
 ,absolut_max_current => 6
 ,standby_current => 7
 ,minimum_speed => 130
 ,ramp_mode => 138
 ,microstep_resolution => 140
 ,ramp_divisor => 153
 ,puls_divisor => 154
 ,freewheeling => 204
 ,stall_detection_threshold => 211
 ,power_down_dely => 214
};


our %limits;
our $RESOLUTION = 32;
our $GETRIEBEMULTIPLIKATOR = 43;

our @ISA = ("Lab::Instrument");

our %fields = (
	supported_connections => [ 'VISA', 'VISA_RS232', 'RS232', 'DEBUG' ],
	baudrate => 9600,
	databits => 8,
	stopbits => 1,
	parity => 'none',
	handshake => 'none',
	timeout => 500,
	inipath => '',
	logpath => '',
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__); 

	# my $status;
	# termchar is imho disabled by default
	# $status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr}, $Lab::VISA::VI_ATTR_TERMCHAR_EN, $Lab::VISA::VI_FALSE);
	# if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting termchar enabled: $status";}	
	# not sure what the echo setting by default is, let's test
	# $self->{vi}->{config}->{RS232_Echo} = 'OFF';

	
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, maximum_positioning_speed, 10);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, ramp_mode, 0);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, microstep_resolution, 5);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, absolut_max_current, 745);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, standby_current, 1400);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, stall_detection_threshold, 2040);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, power_down_dely, 0);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, ramp_divisor, 7);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, puls_divisor, 3);
	# print $result."\n";
	# my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, freewheeling, 100);
	# print $result."\n";
	# exit;
		
	my ($result, $errcode);				
	# set initial motor parameters (reference point, speed, microstep resolution, etc.
	# 1.) speed:
		$limits{'maximum_positioning_speed'} = 120;		
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, target_speed, 0);
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, maximum_positioning_speed, $self->steps2angle($limits{'maximum_positioning_speed'}/2.4)); #HIER ANSETZEN!!!
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, ramp_mode, 2);	
		
	# 2.) microstep resolution:
		# 0 = full step (don't use), 
		# 1 = half step (don't use), 
		# 2 = 4 microsteps, 
		# 3 = 8 microsteps, 
		# 4 = 16 microsteps, 
		# 5 = 32 microsteps, 
		# 6 = 64 microsteps		
		$RESOLUTION = 32;
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, microstep_resolution, 5);
			
	# 3.) motor current settings:
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, absolut_max_current, 745); # 469 mA
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, standby_current, 1400); # 117 mA
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, stall_detection_threshold, 2040);
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, power_down_dely, 0);
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, ramp_divisor, 7);
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, puls_divisor, 3);
		($result, $errcode) = $self->exec_cmd(TMCL_SAP, freewheeling, 100);
		
		# ($result, $errcode) = $self->exec_cmd(TMCL_SAP, actual_position, $self->angle2steps(-330));
		# print $self->get_position()."\n";;
		# exit;

	# 4.) set some reference point and limits for motor movements:			
		$self->init_limits();
		
	return $self;		
}



# Execute command: exec_cmd(cmd, type, value)
sub exec_cmd {
	my $self = shift;
	
	my $addr = 1;
	my $cmd = shift;
	my $type = shift;
	my $motor = 0;
	my $value = shift;
	
	if ( $value < 0 )
		{
		$value = 4244897281 + $value;
		}
	
	my $v4 = int($value / 255**3);	
	$v4 = ( $v4 > 255 ) ? 255 : $v4;		
	$value -= (255**3)*$v4;
	my $v3 = int($value / 255**2);
	$v3 = ( $v3 > 255 ) ? 255 : $v3;	
	$value -= (255**2)*$v3;
	my $v2 = int($value / 255);
	$v2 = ( $v2 > 255 ) ? 255 : $v2;	
	$value -= 255*$v2;
	
	
	my $checksum = ($addr + $cmd + $type + $motor + $v4 + $v3 + $v2 + $value) % 256;
			
	my $query = pack("C9", $addr, $cmd, $type, $motor, $v4, $v3, $v2, $value, $checksum);
	my $result=0;
	my $errcode=0;
	my $i = 0;
	while($errcode != 100 && $i < 10) {
	  #print $addr."-".$cmd."-".$type."-".$motor."-".$v4."-".$v3."-".$v2."-".$value."-".$checksum." (".$i.")\n";
	  $self->write($query);
	  ($result, $errcode) = $self->get_reply();
	  $i++;
	}
		
	return $result, $errcode;	
}

sub get_reply {
	my $self = shift;	
	my @result;
	foreach (1..9) {
		push(@result,unpack("C",$self->connection()->BrutalRead(read_length => 1)));
	}
	
	my $value =  (255**3)*$result[4] + (255**2)*$result[5] + 255*$result[6] + $result[7];
	if ( $value > 2122448640 ) {
		$value =  -(4244897281 - $value); 
	}

	return $value, $result[2];	
}

sub move{
	my $self = shift;
	my $mode = shift; # ABS --> absolut \n REL --> relative
	my $position = shift; 
	my $speed = shift;
	
	
	if ( not defined $mode )
		{
		warn "too view paramters given in sub move. Paramters are <MODE> = ABS | REL and <POSITION> = $limits{'LOWER'} ... $limits{'UPPER'}, <SPEED> = 0 ... $limits{'maximum_positioning_speed'}";
		return ;
		}
	if ( not $mode =~/ABS|abs|REL|rel/  )
		{
		if ( not defined $speed )
			{
			$speed = $position;
			$position = $mode;
			$mode = "REL";
			}
		else
			{
			warn "unexpected value for <MODE> in sub move. expected values are ABS and REL.";
			return ;
			}
		}
	if ( not defined $speed )
		{
		$speed = $limits{'maximum_positioning_speed'};
		}
	
	# this sets the upper limit for the positioning speed:
	$speed = abs($speed);
	if ( $speed <= $limits{'maximum_positioning_speed'})
		{
		$speed = $speed/2.4;
		my ($result, $errcode) = $self->exec_cmd(TMCL_SAP, maximum_positioning_speed, $speed);
		}
	else
		{
		warn "Warning in sub move: <SPEED> = $speed is too high. Reduce <SPEED> to its maximum value defined by internal limit settings of $limits{'maximum_positioning_speed'}";
		$speed = $speed/2.4;
		my ($result, $errcode) = $self->exec_cmd(TMCL_SAP, maximum_positioning_speed, $limits{'maximum_positioning_speed'});
		}
	
	# Moving in ABS or REL mode:
	my $CP = $self->get_position();
	if ( $mode eq "ABS" or $mode eq "abs" or $mode eq "ABSOLUTE" or $mode eq "absolute")
		{
		if ($position < $limits{'LOWER'} or $position > $limits{'UPPER'})
			{
			die "unexpected value for NEW POSITION in sub move. Expected values are between $limits{'LOWER'} ... $limits{'UPPER'}";
			}
		$self->_save_motorlog($CP, $position);
		$self->exec_cmd(TMCL_MVP, MVP_ABS, $self->angle2steps($position));
		}
	elsif ( $mode eq "REL" or $mode eq "rel" or $mode eq "RELATIVE" or $mode eq "relative") {
		if($CP+$position < $limits{'LOWER'} or $CP+$position > $limits{'UPPER'})
			{
			die "ERROR in sub move.Can't execute move; TARGET POSITION (".($CP+$position).") is out of valid limits (".$limits{'LOWER'}." ... ".$limits{'UPPER'}.")";
			}
		$self->_save_motorlog($CP, $CP+$position);
		$self->exec_cmd(TMCL_MVP, MVP_REL, $self->angle2steps($position));
	}
	return 1;
}

sub active {
	my $self = shift;
	
	my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, actual_speed, 0);
	$self->get_position();
	return abs($result);
			
}

sub wait {
	my $self = shift;
	my $flag = 1;
	local $| = 1;
	
	
	while ( $self->active())
			{
			if ( $flag <= 1.1 and $flag >= 0.9 )
				{
				print "$self->{id} is sweeping\r";
				}
			elsif ( $flag <= 0 )
				{
				print "$self->{id} is         \r";
				$flag = 2;
				}
			$flag -= 0.1;
			usleep(5e3);
			}
	
	print "\t\t\t\t\t\t\t\t\t\r";
	$| = 0;	
	
	return 1;
	
}

sub abort {
	my $self = shift;
	$self->exec_cmd(TMCL_MST, 0, 0);
	print "Motor stoped at $self->get_position()\n";
	return;
}

sub init_limits {
	my $self = shift;
	my $lowerlimit;
	my $upperlimit;
	
	if (! $self->read_motorinitdata())
	{
		
	my ($result, $errcode) = $self->exec_cmd(TMCL_MST, 0, 0); # Motor stop, to prevent unexpected motor activity
	($result, $errcode) = $self->exec_cmd(TMCL_SAP, target_position, 0);
	($result, $errcode) = $self->exec_cmd(TMCL_SAP, actual_position, 0);
	$limits{'LOWER'} = -360;
	$limits{'UPPER'} = 360;
	print "\n\n";
	print "----------------------------------------------\n";
	print "----------- Init Motor PDx-110-42 ------------\n";
	print "----------------------------------------------\n";
	print "\n";
	print "This procedure will help you to initialize the Motor PDx-110-42 correctly.\n\n";
	print "Steps to go:\n";
	print "  1.) Define the REFERENCE POINT.\n";
	print "  2.) Define the LOWER and UPPER LIMITS for rotation.\n";
	print "  3.) Confirm the LOWER and UPPER LIMITS.\n";
	print "\n\n";
	
	print "----------------------------\n";
	print "1.) Define the REFERENCE POINT:\n\n";
	print "--> Move the motor position to the REFERENCE POINT.\n";
	print "--> Enter an angle between -180 ... +180 deg.\n";
	print "--> Repeat until you have reached the position you want to define as the REFERENCE POINT.\n";
	print "--> Enter 'REF' to confirm the actual position as the REFERENCE POINT.\n\n";
	
	while (1)
		{
		print "MOVE: ";
		my $value = <>;
		chomp $value;
		if ($value eq "REF" or $value eq "ref")
			{
			# set actual position as reference point Zero
			$limits{'POSITION'} = 0;# for testing only
			my ($result, $errcode) = $self->exec_cmd(TMCL_MST, 0, 0); # Motor stop, to prevent unexpected motor activity
			($result, $errcode) = $self->exec_cmd(TMCL_SAP, target_position, 0);
			($result, $errcode) = $self->exec_cmd(TMCL_SAP, actual_position, 0);
			last;
			}
		elsif ($value =~ /^[+-]?\d+$/ and $value >= -180 and $value <= 180)
			{
			$self->move("REL",$value);
			while (1)
				{
				my $result = $self->get_position();
				print $result."\n";
				if ( $self->active() == 0 ){ last;}			
				}
			}
		else
			{
			print "Please move the motor position to the REFERENCE POINT. Enter an angle between -188° ... +180°.\n";
			}		
		}
		
		
	print "----------------------------\n";
	print "2.) Define the LOWER and UPPER LIMITS for rotation:\n\n";
	print "--> Enter LOWER LIMIT\n";
	print "--> Enter UPPER LIMIT\n\n";
	
	while(1)
		{
		print "LOWER LIMIT: ";
		my $value = <>;
		chomp $value;
		$lowerlimit = $value;
		$limits{'LOWER'} = $lowerlimit;
		print "UPPER LIMIT: ";
		my $value = <>;
		chomp $value;
		$upperlimit = $value;
		$limits{'UPPER'} = $upperlimit;
		if ($lowerlimit < $upperlimit)
			{
			last;
			}
		else
			{
			print "LOWER LIMIT >= UPPER LIMIT. Try again!\n";
			}
		}
		
	
	
	print "----------------------------\n";
	print "3.) Confirm the LOWER and UPPER LIMITS:\n\n";
	print "--> Motor will move to LOWER LIMIT in steps of 10 deg\n";
	print "--> Motor will move to UPPER LIMIT in steps of 10 deg\n";
	print "--> Confirm each step with ENTER or type <STOP> to take the actual position as the limit value. \n\n";
	
	print "Moving to LOWER LIMIT ...\n";
	while(1)
		{
		print "MOVE +/-10: Please press <ENTER> to confirm.";
		my $input = <>;	
		chomp $input;
		if ( $input =~ /stop|STOP/ )
			{
			$lowerlimit = $self->get_position();
			last;
			}
		if (abs($self->get_position() - $lowerlimit) >= 10)
			{
			if ( $lowerlimit <= 0 )
				{
				$self->move("REL",-10);
				while (1)
					{
					my $result = $self->get_position();
					print $result."\n";
					if ( $self->active() == 0 ){ last;}			
					}
				}
			else
				{
				$self->move("REL",10);
				while (1)
					{
					my $result = $self->get_position();
					print $result."\n";
					if ( $self->active() == 0 ){ last;}			
					}
				}
			}
		else
			{
			$self->move("ABS",$lowerlimit);
			while (1)
				{
				my $result = $self->get_position();
				print $result."\n";
				if ( $self->active() == 0 ){ last;}			
				}
			last;
			}
			
		}
	print "Reached LOWER LIMIT\n";
	print "Please confirm the position of the LOWER LIMIT: "; <>;
	$limits{'LOWER'} = $lowerlimit;
	print "\n\n";
	print "Moving to REFERENCE POINT ... \n";
	print $self->move("ABS",0)."\n";
	$self->wait();
	print "Moving to UPPER LIMIT ...\n";	
	while(1)
		{
		print "MOVE +/-10: Please press <ENTER> to confirm.";
		my $input = <>;	
		chomp $input;
		if ( $input =~ /stop|STOP/ )
			{
			$upperlimit = $self->get_position();
			last;
			}		
		if ( abs($upperlimit - $self->get_position()) >= 10)
			{
			$self->move("REL",10);
			while (1)
				{
				my $result = $self->get_position();
				print $result."\n";
				if ( $self->active() == 0 ){ last;}			
				}
			}
		else
			{
			$self->move("ABS",$upperlimit);
			while (1)
				{
				my $result = $self->get_position();
				print $result."\n";
				if ( $self->active() == 0 ){ last;}			
				}
			last;
			}
			
		}
	print "Reached UPPER LIMIT\n";
	print "Please confirm the position of the UPPER LIMIT: "; <>;
	$limits{'UPPER'} = $upperlimit;
	print "\n\n";
	$self->save_motorinitdata();
	
	print "moving to the reference point.\n";
	$self->move("ABS",0);
			while (1)
				{
				my $result = $self->get_position();
				print $result."\n";
				if ( $self->active() == 0 ){ last;}			
				}
	print "------------------------------------------------------\n";
	print "------------ Motor PDx-110-42 initialized ------------\n";
	print "------------------------------------------------------\n";
	print "\n\n";
		
	}
}

sub _set_REF {
	my $self = shift;
	my $new_ref = shift;
	
	
	my $old_ref = $self->get_position();
	
	if (not open(DUMP, ">>C:\\Perl\\site\\lib\\Lab\\Instrument\\PD11042.log"))
		{
		print "cant open logfile\n";
		}
	
	print "Set actual position from $old_ref to $new_ref\n";	
	my ($result, $errcode) = $self->exec_cmd(TMCL_SAP, target_position, $self->angle2steps($new_ref));
	($result, $errcode) = $self->exec_cmd(TMCL_SAP, actual_position, $self->angle2steps($new_ref));
	print DUMP (my_timestamp())."\t set new REF: $old_ref -> $new_ref \n";
	close(DUMP);
	
	
	# this writes the new position to the ini-file.
	$self->get_position();
	
	return 
}

sub steps2angle {
	my $self = shift;
	my $steps = shift;
	my $angle = $steps/(200*$RESOLUTION/360)/$GETRIEBEMULTIPLIKATOR; 
	return $angle;
}

sub angle2steps {
	my $self = shift;
	my $angle = shift;
	my $steps =  $angle*(200*$RESOLUTION/360)*$GETRIEBEMULTIPLIKATOR;  
	return sprintf("%0.f",$steps);

}

sub get_value {
	my $self = shift;
	return $self->get_position();
}

sub get_position{
	my $self = shift;
	
	my ($result, $errcode) = $self->exec_cmd(TMCL_GAP, actual_position, 0);
	$limits{POSITION} = $self->steps2angle($result);
	$self->save_motorinitdata;
	$self->{value} = $limits{POSITION};
	return $limits{POSITION};
	
}

sub save_motorinitdata {
	my $self = shift;
	
	open(DUMP, ">PD11042.ini"); #open for write, overwrite
	while( my ($key, $value) = each %limits ) 
		{
		print DUMP "$key, $value\n";
		}
	close(DUMP);
}

sub _save_motorlog {
	my $self = shift;
	my $init_pos = shift;
	my $end_pos = shift;
	
	open(DUMP, ">>PD11042.log"); #open for write, overwrite

	print DUMP (my_timestamp())."\t move: $init_pos -> $end_pos \n";
		
	close(DUMP);
}

sub read_motorinitdata {
	my $self = shift;
	
	if (not open(DUMP, "<PD11042.ini"))
		{
		return 0;
		}
	while(<DUMP>)
		{
		chomp ($_);
		my @line = split(/, /,$_);
		$limits{$line[0]} = $line[1];
		}
	
	print "\nread MOTOR-INIT-DATA\n";
	print "--------------------\n";
	while( my ($key, $value) = each %limits ) 
		{
		print "$key: $value\n";
		}
	print "--------------------\n";
	return 1;
}

sub my_timestamp {

my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat,
    $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime(time);
	
$Monat+=1;
$Jahrestag+=1;
$Monat = $Monat < 10 ? $Monat = "0".$Monat : $Monat;
$Monatstag = $Monatstag < 10 ? $Monatstag = "0".$Monatstag : $Monatstag;
$Stunden = $Stunden < 10 ? $Stunden = "0".$Stunden : $Stunden;
$Minuten = $Minuten < 10 ? $Minuten = "0".$Minuten : $Minuten;
$Sekunden = $Sekunden < 10 ? $Sekunden = "0".$Sekunden : $Sekunden;
$Jahr+=1900;
	
return "$Stunden:$Minuten:$Sekunden  $Monatstag.$Monat.$Jahr\n";

}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::PD11042 - 42mm stepper motor with integrated controller/driver

=head1 SYNOPSIS

    use Lab::Instrument::PD11042;
    
    ...
    
=head1 DESCRIPTION

The Lab::Instrument::PD11042 class implements an interface to the
Trinamic PD-110-42 low-cost 42mm stepper motor with integrated
controller/driver.

=head1 CONSTRUCTOR

   ...

=head1 METHODS

=head2 ...

  ...

...

=head1 CAVEATS/BUGS

None known so far. :)

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=item
<Lhttp://www.trinamic.com/index.php?option=com_content&view=article&id=243&
Itemid=355>


=back

=head1 AUTHOR/COPYRIGHT

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

  (c) 2011 Stefan Geissler

=cut
