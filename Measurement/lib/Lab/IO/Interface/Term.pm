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
	
	# Terminal size
	my @size = GetTerminalSize(STDOUT);
	$self->{cols} = $size[0] - 1;
	$self->{rows} = $size[1];
		
	$self->{last_header} = '';	
	$self->{last_ln} = 1;
	
	$self->{sticky_rows} = {};
	
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
		
	print ${Lab::GenericIO::STDOUT} $string;	
		
	$self->{last_ln} = ($string =~ m/\n\r?$/ ? 1 : 0);		
}

# -----------------------------------------------
sub message {
  my $self = shift;	
	my $DATA = shift;
	my $chan = 'MESSAGE';	
	
  $self->header($DATA, $chan, 'bold blue on white');	
	$self->process_common($DATA);	
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

# -----------------------------------------------
sub new_sticky {
  my $self = shift;
	my $id = shift;
	my $content = shift;
		
	$self->{sticky_rows}->{$id} = $content;
}

1;
