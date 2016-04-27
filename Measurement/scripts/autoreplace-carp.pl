#!/usr/bin/env perl

# run from Measurement dir

use 5.010;
use warnings;
use strict;
use File::Find;
use Regexp::Common;
use autodie;

my @files;

File::Find::find({
	wanted => sub {-f $_ && /\.pm$/ and push @files, $_},
	no_chdir => 1
		 }, 'lib');

my $use_regex = qr/\s*use\s+Lab::Exception;/;

my $remainder = qr/\(\s*(error\s*=>\s*)?(?<msg>[^;]*)/; 
my $exception_regex = qr/(do\s+)?Lab::Exception::\w+->throw\s*$remainder;/;

my $warning = qr/Lab::Exception::\w+->new|new\s+Lab::Exception::\w+/;
my $print_exception_regex = 
    qr/print\s+$warning\s*$remainder;/;
my $genericIO_warning = qr/\$self->out_(warning|debug|message)\s*$remainder;/;
my $genericIO_error = qr/\$self->out_error\s*$remainder;/;

my $newline_regex = qr/(carp|croak)\s*\([^;]*?\K\s*(\\n)+(?=(\'|\"))/;

my $i = 0;
for my $file (@files) {
	open my $fh, "<", $file;
	
	my $text = do {local $/ = <$fh>};
	
	close $fh;

	$text =~ s{(^[^#\n]*(croak|carp)[^;]*=>[^;]*)}{
	my $before = $`;
	++$i;
	say "\n\nfile: $file, text: ", $1 =~ s/^\s*//r;
	say "in line: ", ($before =~ tr/\n//) + 1;

}gme
	
	# if ($text !~ /use Lab::Generic/ && $text !~ /package Lab::Generic;/) {
	# 	if ($text =~ /^our \$VERSION.*/m) {
	# 		$text =~ s{^our \$VERSION.*;\s*\K}{use Lab::Generic;\n}m;
	# 	}
	# 	else {
	# 		$text =~ s/package.*;\s*\K/\n\nuse Lab::Generic;\n/;
	# 	}
	# }
# 	# kill 'use Lab::Exception;'
# 	$text =~ s/$use_regex//;

	
		
# 	$text =~ s/$exception_regex|$genericIO_error/
# "croak($+{msg};";
# /ge;
# 	$text =~ s/$print_exception_regex|$genericIO_warning/
# "carp($+{msg};";
# /ge;
# 	$text =~ s/$newline_regex/
# ++$i;
# "";
# /ge;
# 	$text =~ s/\.\s*""//g;
# 	$text =~ s/use Lab::Generic$/use Lab::Generic;/m;
# 	if ($text =~ /(use Lab::Generic.*){2}/s) {
# 		warn "file: $file";
# 	}
	# open $fh, ">", $file;
	# print {$fh} $text;
	# close $fh;
	
}

say "number: $i";
# Lab::Exception::DeviceError->throw("Read. (caller(0))[3] ...

# Lab::Exception::CorruptParameter->throw( error => 'Lab::Bus::GPIB::VerboseIbstatus.', InvalidParameter => $ibstatus );

# Lab::Exception::Warning->throw( error => "\n\nMultiChannel

# print Lab::Exception::CorruptParameter->new( error => "no values given in
# print new Lab::Exception::Warning("DataFile $file is not defined! \n");

# Keithley2400, Multimeter
# Lab::Exception::CorruptParameter->throw("$value is not a valid output status (on = 1 | off = 0)");

# GenericIO system:

# $self->out_debug("Function: _setconnection\n");
# $self->out_warning('State has to be 0 (local), 1 (remo
# $self->out_error('Please give either a time OR rate. Not both!');
