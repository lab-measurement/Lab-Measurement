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
	#$self->{rowfill} = (" " x $self->{cols})."\r";
	
	$self->{CHANNELS} = {
		'MESSAGE' => \&message
	 ,'ERROR' => \&error
	 ,'WARNING' => \&warning
	 ,'DEBUG' => \&debug
	};
	return $self;
}

sub message {
  my $self = shift;	
	my $DATA = shift;
	
	#print "Same channel? ", ($self->same_channel('MESSAGE') ? 'Yes' : 'No'), "\n";
	#print "Same object? ", ($self->same_object($DATA) ? 'Yes' : 'No'), "\n";	
	
	if(!$self->same_object($DATA) || !$self->same_channel('MESSAGE')) {
	  $self->header("MESSAGE from ".ref($DATA->{object}).":", 'bold blue on white');
	}	
	$self->process_common($DATA);
}

sub error {
  my $self = shift;	
	my $DATA = shift;	
	
	#print "Same channel? ", ($self->same_channel('ERROR') ? 'Yes' : 'No'), "\n";
	#print "Same object? ", ($self->same_object($DATA) ? 'Yes' : 'No'), "\n";	
	
	if(!$self->same_object($DATA) || !$self->same_channel('ERROR')) {
	  $self->header("ERROR from ".ref($DATA->{object}).":", 'bold red on white');
	}	
	$self->process_common($DATA);
}

sub warning {
  my $self = shift;	
	my $DATA = shift;	
	
	$self->print("WARNING from ".ref($DATA->{object}).":\n", 'yellow on_white');
	$self->process_common($DATA);
}

sub debug {
  my $self = shift;	
	my $DATA = shift;	
	
	$self->print("DEBUG from ".ref($DATA->{object}).":\n", 'green on_white');
	$self->process_common($DATA);
}

sub header {
  my $self = shift;
	my $text = shift;
	my $style = shift;
	
	print STDOUT Term::ANSIScreen::colored("$text", $style);
	print STDOUT "\n";
}

sub process_common {
  my $self = shift;
	my $DATA = shift;
	
	my $msg = $DATA->msg_parsed();
	$self->print($msg);
	
	if (exists $DATA->{options}) {
  	if (exists $DATA->{options}->{dump} && $DATA->{options}->{dump}) {
			$self->params_dump($DATA);
		}
	}
	print "\n";
}

sub params_dump {
  my $self = shift;
	my $DATA = shift;
	if (not exists $DATA->{params}) {return;}
	
	my $string;
	for my $param (keys %{$DATA->{params}}) {
		$string = " - $param: ".$DATA->{params}->{$param};		
	  $self->print($string);
	}
}

sub print {
  my $self = shift;
	my $string = shift;
	my $style = shift;
	
	# if (defined $style) {
		# my $cols = $self->{cols};
		# while ($string =~ /(.{1,$cols})/g) {
			# print STDOUT Term::ANSIScreen::colored($self->{rowfill}, $style);
			# print STDOUT Term::ANSIScreen::colored("$1\n", $style);
		# }
	# }
	# else {
	  # print STDOUT "$string\n";
	# }
	print STDOUT "$string\n";
}

1;
