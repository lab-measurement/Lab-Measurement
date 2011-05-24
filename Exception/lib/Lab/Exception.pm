#!/usr/bin/perl -w


package Lab::Exception::Base;

#
# This is for comfy optional adding of custom methods via our own exception base class later
#


our @ISA = ("Exception::Class::Base");

#use Carp;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	return $self;
}





package Lab::Exception;

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
		description	=> 'A timeout occured while reading/wrting through NI VISA / Lab::VISA',
		fields		=> [
							'status', # the status returned from Lab::VISA, if any
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
