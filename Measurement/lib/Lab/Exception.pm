#!/usr/bin/perl -w


package Lab::Exception::Base;
our $VERSION = '2.91';

#
# This is for comfy optional adding of custom methods via our own exception base class later
#


our @ISA = ("Exception::Class::Base");

#use Carp;
use Data::Dumper;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	return $self;
}

#
# convenience routine - receives __LINE__, __PACKAGE__, __FILE__, subroutine (typically) and returns a uniform appendix made up from this information
#
sub Appendix {	# $line, $file, $package
	shift if( ref($_[0]) eq 'HASH' ); # omit $self
	my $line=undef;
	my $package=undef;
	my $file=undef;
	my $subroutine=undef;
	if(scalar(@_) > 0) {
		($line, $package, $file, $subroutine) = ( shift, shift, shift, shift);
	}
	else {
		# looks like the "line"-feedback of caller($i) is the line where the function of level $i is called
		# so to get the line where the exception occured, query the line of caller(0)
		($line, $package, $file, $subroutine) = ( (caller(0))[2], (caller(1))[0,1,3] );
	}

	my $appendix = "";
	$appendix .= "   Subroutine:    $subroutine\n" if defined($subroutine);
	$appendix .= "   Line:    $line\n" if defined($line);
	$appendix .= "   File:    $file\n" if defined($file);
	$appendix = "\n" . $appendix if($appendix ne "");

	return $appendix;
}






package Lab::Exception;
our $VERSION = '2.91';


#
# un/comment the following BEGIN clause to slap in the custom base class above
#
BEGIN { $Exception::Class::BASE_EXC_CLASS = 'Lab::Exception::Base'; }

use Exception::Class (

	Lab::Exception::Error => {
		description => 'An error.'
	},

	#
	# general errors
	#
	Lab::Exception::CorruptParameter => {
		isa 		=> 'Lab::Exception::Error',
		description	=> "A provided method parameter was of wrong type or otherwise corrupt.",
		fields		=> [
							'invalid_parameter',	# put the invalid parameter here
		],
	},

	Lab::Exception::Timeout => {
		isa 		=> 'Lab::Exception::Error',
		description	=> "A timeout occured. If any data was received nontheless, you can read it off this exception object if you care for it.",
		fields		=> [
							'data',	# this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
		],
	},


	#
	# errors and warnings specific to Lab::Connection::GPIB
	#
	Lab::Exception::GPIBError => {
		isa			=> 'Lab::Exception::Error',
		description	=> 'An error occured in the GPIB connection (linux-gpib).',
		fields		=> [
              				'ibsta',	# the raw ibsta status byte received from linux-gpib
							'ibsta_hash', 	# the ibsta bit values in a named, easy-to-read hash ( 'DCAS' => $val, 'DTAS' => $val, ...
											# use Lab::Connection::GPIB::VerboseIbstatus() to get a nice string representation
		],
	},

	Lab::Exception::GPIBTimeout => {
		isa			=> 'Lab::Exception::GPIBError',
		description	=> 'A timeout occured in the GPIB connection (linux-gpib).',
		fields		=> [
							'data',	# this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
		],
	},


	#
	# errors and warnings specific to VISA / Lab::VISA
	#

	Lab::Exception::VISAError => {
		isa			=> 'Lab::Exception::Error',
		description	=> 'An error occured with NI VISA or the Lab::VISA interface',
		fields		=> [
							'status', # the status returned from Lab::VISA, if any
		]
	},

	Lab::Exception::VISATimeout => {
		isa			=> 'Lab::Exception::VISAError',
		description	=> 'A timeout occured while reading/writing through NI VISA / Lab::VISA',
		fields		=> [
							'status', # the status returned from Lab::VISA, if any
							'command', # the command that led to the timeout
							'data', # the data read up to the abort
		]
	},


	#
	# errors and warnings specific to VISA / Lab::VISA
	#

	Lab::Exception::RS232Error => {
		isa			=> 'Lab::Exception::Error',
		description	=> 'An error occured with the native RS232 interface',
		fields		=> [
							'status', # the returned status
		]
	},

	Lab::Exception::RS232Timeout => {
		isa			=> 'Lab::Exception::RS232Error',
		description	=> 'A timeout occured while reading/writing through native RS232 interface',
		fields		=> [
							'status', # the status returned
							'command', # the command that led to the timeout
							'data', # the data read up to the abort
		]
	},


	#
	# general warnings
	#
	Lab::Exception::Warning => {
		description => 'A warning.'
	},

	Lab::Exception::UndefinedField => {
		isa 		=> 'Lab::Exception::Warning',
		description	=> "AUTOLOAD couldn't find requested field in object",
	},
);


1;
