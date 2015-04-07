package Lab::IO::Interface::Term;

our $VERSION='3.41';

use Lab::IO::Interface;
use if ($^O eq "MSWin32"), Win32::Console::ANSI;
use Term::ReadKey;
use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;

#our @ISA = ('Lab::IO::Interface');
use Lab::Generic;
use parent ("Lab::IO::Interface");

sub new { 
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);
	
	$|++;
	
	# Terminal size
	my @size = GetTerminalSize(STDOUT);
	$self->{cols} = $size[0] - 1;
	$self->{rows} = $size[1];
		
	$self->{last_header} = '';	
	$self->{last_ln} = 1;
	
	$self->{sticky_rows} = {};	
	$self->{sticky_order} = [];
	
	$self->{progress_bars} = {};
	$self->{progress_defaults} = {
	  'valueMin' => 0
	 ,'valueMax' => 100
	 ,'value'		 => 0
	 ,'unit'		 => '%'
	 ,'textBefore' => ''
	 ,'textAfter' => ''
	 ,'charBack' => '-'
	 ,'charFront' => '#'
	};
	
	$self->{init_output} = 1;	
	
	$self->{CHANNELS} = {
		'MESSAGE' => \&message
	 ,'ERROR' => \&error
	 ,'WARNING' => \&warning
	 ,'DEBUG' => \&debug
	 ,'PROGRESS' => \&progress
	};
	return $self;
}

sub output {  
	my $self = shift;
	my $string = join("", @_);

	$self->output_init();
	
	print ${Lab::GenericIO::STDOUT} loadpos;
  print ${Lab::GenericIO::STDOUT} cldown;	
	print ${Lab::GenericIO::STDOUT} $string;	
  print ${Lab::GenericIO::STDOUT} savepos;	
	
	$self->{last_ln} = ($string =~ m/\n\r?$/ ? 1 : 0);
  
	$self->sticky_rows();
}

sub output_init {
  my $self = shift;
	
	if($self->{init_output}) {
	  print ${Lab::GenericIO::STDOUT} savepos;
		$self->{init_output} = 0;
	}
}

# -----------------------------------------------
sub message {
  my $self = shift;	
	my $DATA = shift;		
	
	$self->process_common($DATA, {
	  'channel' => 'MESSAGE'
	 ,'header_style' => 'bold blue on white'
	});	
}

sub error {
  my $self = shift;	
	my $DATA = shift;		
	
	my $trace = "simple";
	if (${Lab::Generic::CLOptions::DEBUG} == 1) {
		$trace = "verbose";
	}

	$self->process_common($DATA, {
	  'channel' => 'ERROR'
	 ,'header_style' => 'bold red on white'
	 ,'trace' => $trace
	});	
}

sub warning {
  my $self = shift;	
	my $DATA = shift;

	my $trace = "simple";
	if (${Lab::Generic::CLOptions::DEBUG} == 1) {
		$trace = "verbose";
	}	
	
	$self->process_common($DATA, {
	  'channel' => 'WARNING'
	 ,'header_style' => 'yellow on white'
	 ,'trace' => $trace
	});	
}

sub debug {
  my $self = shift;	
	my $DATA = shift;		
		
	$self->process_common($DATA, {
	  'channel' => 'DEBUG'
	 ,'header_style' => 'green on white'
	});
}

sub progress {
	my $self = shift;
	my $DATA = shift;
		
	$self->progress_process($DATA->{data});
}

# -----------------------------------------------
sub process_common {
  my $self = shift;
	my $DATA = shift;
	my $cfg = shift;
	
	# options
	my $proceed = $self->process_options($DATA, $cfg);
	if(!$proceed) {return;}
	
	# header
	$self->header($DATA, $cfg);
	
	# body
	my $msg = $DATA->msg_parsed();
	$self->output($msg);
		
	# params dump
	if (defined $DATA->{data}->{dump} && $DATA->{data}->{dump}) {
		$self->params_dump($DATA);
	}

	# trace
	if ($cfg->{trace} eq "simple") {
		$self->output("\n\n");
		my $frame = $DATA->{trace}->prev_frame();

		$self->output($self->stackFrame_to_string($frame), "\n");
	}
	elsif ($cfg->{trace} eq "verbose") {
		$self->output("\n\n");
		$self->output("-- StackTrace: -- \n\n");
		my $pos = $DATA->{trace}->frame_count();
		while(my $frame = $DATA->{trace}->next_frame()) { 
			$self->output("#$pos)  ", $self->stackFrame_to_string($frame), "\n");
			$pos --;
		}
	}
		
}

sub process_options {
  my $self = shift;
	my $DATA = shift;
	my $cfg = shift;
		
	if(defined $DATA->{data}->{sticky}) {
		$self->sticky_process($DATA, $cfg);
		return 0;
	}
	
	return 1;
}

sub header {
  my $self = shift;
	my $DATA = shift;
	my $cfg = shift;	
	
	my $object_ref = (defined $DATA->{object}) ? ref($DATA->{object}) : undef;
	my $object_name = (defined $DATA->{object} && $DATA->{object}->can('get_name')) ? $DATA->{object}->get_name() : undef;
	my $package = $DATA->{trace}->frame(0)->package();

	my $header_msg = "\"".$cfg->{channel}."\"";
		
	if ($package ne $object_ref) { $header_msg .= " in $package"; }
	if (defined $object_ref) { $header_msg .= " from $object_ref"; }
	if (defined $object_name) { $header_msg .= " ($object_name)"; }

	$header_msg .= ":";
	
	if($header_msg eq $self->{last_header}) {return;}
	$self->{last_header} = $header_msg;
	
	my $style = (defined $cfg->{header_style} ? $cfg->{header_style} : 'black on white');
	
	if(!$self->{last_ln}) {$self->output("\n");}
	$self->output("\n", Term::ANSIScreen::colored("$header_msg", $style), "\n");	
}

sub params_dump {
  my $self = shift;
	my $DATA = shift;
	if (not exists $DATA->{params}) {return;}
	
	my $string;
	for my $param (keys %{$DATA->{params}}) {
		$string = " - $param: ".$DATA->{params}->{$param}."\n";		
	  $self->output($string);
	}
}

sub stackFrame_to_string {
  my $self = shift;
    my $frame = shift;

    my $string = $frame->subroutine()."(";
    my @args = $frame->args();
    foreach my $arg (@args) {
    	
    	if (ref($arg) ne "") {
    		$string .= ref($arg).", ";
    	}
    	else {
    		$string .= "'$arg', ";
    	}
    }

    $string .= ") ";
	$string .= "called at ".$frame->filename." line ".$frame->line;

	return $string;
}

# ---------- STICKY -----------------------------
sub sticky_process {
  my $self = shift;
	my $DATA = shift;
	my $cfg = shift;
	
	if(not defined $DATA->{data}->{sticky} || not defined $DATA->{data}->{sticky}->{id}) {return;}
	my $id = $DATA->{data}->{sticky}->{id};
	
	if(defined $DATA->{data}->{sticky}->{cmd}) {
	  if($DATA->{data}->{sticky}->{cmd} eq 'finish') {
		  $self->sticky_remove($id, 1);
		}
		elsif($DATA->{data}->{sticky}->{cmd} eq 'remove') {
		  $self->sticky_remove($id, 0);
		}
	}
	else {
	  my $msg = $DATA->msg_parsed();
		$self->sticky_set($id, $msg);
	}
}

sub sticky_set {
  my $self = shift;
	my $id = shift;
	my $content = shift;

	my $exists = exists $self->{sticky_rows}->{$id};	
  
	$content = $self->sticky_format($content);	
	$self->{sticky_rows}->{$id} = $content;
	
	if(!$exists) {
	  push @{$self->{sticky_order}}, \$self->{sticky_rows}->{$id};
	}
	
	$self->sticky_rows();		# refresh
}

sub sticky_remove {
  my $self = shift;
	my $id = shift;
	my $make_inline = shift;	
	
	if(!exists $self->{sticky_rows}->{$id}) {return;}	
	my $content = $self->{sticky_rows}->{$id};
		
	my $index;	
	for my $i (0 .. $#{$self->{sticky_order}}) {	  
	  if($self->{sticky_order}[$i] eq \$self->{sticky_rows}->{$id}) {
		  $index = $i;
			last;
		}
	}
	if(defined $index) {splice @{$self->{sticky_order}}, $index, 1;}
  delete $self->{sticky_rows}->{$id};	
	
	if($make_inline) {	  
	  if(!$self->{last_ln}) {$self->output("\n");}
	  $self->output($content, "\n");
	}
	else {
	  $self->sticky_rows();
	}
}

sub sticky_format {
  my $self = shift;
	my $content = shift;
	
	$content =~ s/\n//g;
	$content = substr $content, 0, $self->{cols};
	
	return $content;
}

sub sticky_rows {
  my $self = shift;
	
	my $rownum = scalar @{$self->{sticky_order}};
	if(!$rownum) {return;}		# nothing to do	
	
	$self->output_init();
	
	print ${Lab::GenericIO::STDOUT} loadpos;
	print ${Lab::GenericIO::STDOUT} cldown;
	
	if(!$self->{last_ln}) {print ${Lab::GenericIO::STDOUT} "\n";}
	
	print ${Lab::GenericIO::STDOUT} down($rownum);	
	
	foreach(@{$self->{sticky_order}}) {	  
	  print ${Lab::GenericIO::STDOUT} "\r";		
		print ${Lab::GenericIO::STDOUT} ${$_};		
		print ${Lab::GenericIO::STDOUT} up(1);
	}
	
	print ${Lab::GenericIO::STDOUT} down($rownum);
	print ${Lab::GenericIO::STDOUT} "\r";	
}

# ---------- PROGRESS BAR -----------------------
sub progress_process {
  my $self = shift;
	my $params = shift;
	
	if(not defined $params->{id}) {return;}
  my $id = $params->{id};
	
	if(defined $params->{cmd}) {
	  if($params->{cmd} eq 'finish') {
		  $self->progress_remove($id, 1);
		}
		elsif($params->{cmd} eq 'remove') {
		  $self->progress_remove($id, 0);
		}
	}
	else {
	  my $bar = $self->progress_build($id, $params);
		$self->progress_set($id, $bar);
	}
}

sub progress_config {
  my $self = shift;
	my $id = shift;
	my $config = shift;
	
	my $current_config = (defined $self->{progress_bars}->{$id} ? $self->{progress_bars}->{$id} : $self->{progress_defaults});	
	for my $option (keys %{$current_config}) {	  
		if(not defined $config->{$option}) {
		  $config->{$option} = $current_config->{$option};
		}
	}
	
	# CHECK VALUES HERE!!!
	
	# done
	$self->{progress_bars}->{$id} = $config;	
	return $config;
}

sub progress_build {
  my $self = shift;
	my $id = shift;	
	my $config = shift;
	
	$config = $self->progress_config($id, $config);	
	
	my $chars = $self->{cols};
	
	# static text
	$chars -= length($config->{textBefore});
	$chars -= length($config->{textAfter});
	
	# placeholder for "[valueMin|"
	my $valueMin_length = length($config->{valueMin});
	$chars -= ($valueMin_length + 2);	
	# placeholder for "|valueMax]"
	my $valueMax_length = length($config->{valueMax});
	$chars -= ($valueMax_length + 2);
			
	# $chars now holds number of chars available for the bar itself -> divide it into front/back according to value	
	my $lengthFront = sprintf("%d", $chars * $config->{value} / ($config->{valueMax} - $config->{valueMin}));
	my $lengthBack = $chars - $lengthFront;
	
	# value
	my $value = $config->{value}.$config->{unit};
	my $value_length = length($value);
	my $value_pos = sprintf("%d", ($chars - $value_length)/2);
	
	# build
	my $bar = '';	
	$bar .= $config->{textBefore};
	$bar .= "[".$config->{valueMin}."|";
  $bar .= $config->{charFront} x $lengthFront;
	$bar .= $config->{charBack} x $lengthBack;
	$bar .= "|".$config->{valueMax}."]";
	$bar .= $config->{textAfter};
	
	return $bar;
}

sub progress_set {
  my $self = shift;
	my $id = shift;
	my $bar = shift;
	
	$self->sticky_set($id, $bar);	
}

sub progress_remove {
  my $self = shift;
	my $id = shift;
	my $make_inline = shift;
	
	delete $self->{progress_bars}->{$id};		
	$self->sticky_remove($id, $make_inline);
}

1;
