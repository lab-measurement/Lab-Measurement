#!/usr/bin/perl -w

package Lab::Exception;

use Exception::Class (

	Lab::Exception::Error => {
		description => 'An error.'
	},

	Lab::Exception::CorruptParameter => {
		isa 		=> 'Lab::Exception::Error',
		description	=> "A provided method parameter was of wrong type or otherwise corrupt.",
	}

	Lab::Exception::Warning => {
		description => 'A warning.'
	},

	Lab::Exception::UndefinedField => {
		isa 		=> 'Lab::Exception::Warning',
		description	=> "AUTOLOAD couldn't find requested field in object",
	}
);

1;
