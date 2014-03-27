package Lab::IO::Interface::Term;

use Lab::IO::Interface;
use if ($^O eq "MSWin32"), Win32::Console::ANSI;
use Term::ReadKey;
use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;

our @ISA = ('Lab::IO::Interface');

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
	
	$self->{init_output} = 1;	
	
	$self->{CHANNELS} = {
		'MESSAGE' => \&message
	 ,'ERROR' => \&error
	 ,'WARNING' => \&warning
	 ,'DEBUG' => \&debug
	};
	return $self;
}

sub output {
  #if(ref(@_[0]) eq __PACKAGE__) {shift;}
	my $self = shift;
	my $string = join("", @_);

	if($self->{init_output}) {
	  print ${Lab::GenericIO::STDOUT} savepos;
		$self->{init_output} = 0;
	}
	
	print ${Lab::GenericIO::STDOUT} loadpos;
  print ${Lab::GenericIO::STDOUT} cldown;	
	print ${Lab::GenericIO::STDOUT} $string;	
  print ${Lab::GenericIO::STDOUT} savepos;	
	
	$self->{last_ln} = ($string =~ m/\n\r?$/ ? 1 : 0);	
  
	$self->sticky_rows();
}

# -----------------------------------------------
sub message {
  my $self = shift;	
	my $DATA = shift;
	my $chan = 'MESSAGE';	
	
	$common = $self->process_options($DATA, $chan);
	
	if($common) {
		$self->header($DATA, $chan, 'bold blue on white');	
		$self->process_common($DATA);
	}
}

sub error {
  my $self = shift;	
	my $DATA = shift;	
	my $chan = 'ERROR';
	
	$self->header($DATA, $chan, 'bold red on white');	
	$self->process_common($DATA);
}

sub warning {
  my $self = shift;	
	my $DATA = shift;	
	my $chan = 'WARNING';
	
	$self->header($DATA, $chan, 'bold yellow on white');	
	$self->process_common($DATA);
}

sub debug {
  my $self = shift;	
	my $DATA = shift;	
	my $chan = 'DEBUG';
		
	$self->header($DATA, $chan, 'green on white');
	$self->process_common($DATA);	
}

# -----------------------------------------------
sub process_options {
  my $self = shift;
	my $DATA = shift;
	my $chan = shift;
	
	if(exists $DATA->{options}) {
	  if(exists $DATA->{options}->{sticky_id}) {
		  $self->sticky_process($DATA, $chan);
			return 0;
		}
	}
	
	return 1;
}

sub header {
  my $self = shift;
	my $DATA = shift;
	my $chan = shift;
	my $style = shift;		
	
	my $object_ref = (defined $DATA->{object}) ? ref($DATA->{object}) : undef;
	my $object_name = (defined $DATA->{object} && $DATA->{object}->can('get_name')) ? $DATA->{object}->get_name() : undef;
	my $package = $DATA->{trace}->frame(0)->package();

	my $header_msg = "$chan";
		
	if ($package ne $object_ref) { $header_msg .= " in $package"; }
	if (defined $object_ref) { $header_msg .= " from $object_ref"; }
	if (defined $object_name) { $header_msg .= " ($object_name)"; }

	$header_msg .= ":";
	
	if($header_msg eq $self->{last_header}) {return;}
	$self->{last_header} = $header_msg;
		
	if(!$self->{last_ln}) {$self->output("\n");}
	$self->output("\n", Term::ANSIScreen::colored("$header_msg", $style), "\n");	
}

sub process_common {
  my $self = shift;
	my $DATA = shift;
	
	my $msg = $DATA->msg_parsed();
	$self->output($msg);
	
	if (exists $DATA->{options}) {
  	if (exists $DATA->{options}->{dump} && $DATA->{options}->{dump}) {
			$self->params_dump($DATA);
		}
	}		
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

# ---------- STICKY -----------------------------
sub sticky_process {
  my $self = shift;
	my $DATA = shift;
	my $chan = shift;
	
	my $id = $DATA->{options}->{sticky_id};
	if(exists $DATA->{options}->{sticky_cmd}) {
	  if($DATA->{options}->{sticky_cmd} eq 'finish') {
		  $self->sticky_remove($id, 1);
		}
		elsif($DATA->{options}->{sticky_cmd} eq 'remove') {
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
		}
	}
	if(defined $index) {splice @{$self->{sticky_order}}, $i, 1;}
  delete $self->{sticky_rows}->{$id};	
	
	if($make_inline) {
	  if(!$self->{last_ln}) {print ${Lab::GenericIO::STDOUT} "\n";}
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

1;
