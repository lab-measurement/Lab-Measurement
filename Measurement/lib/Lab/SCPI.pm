package Lab::SCPI;

use 5.010;
use warnings;
use strict;

use Lab::Generic;
use Carp;
use Exporter qw(import);

our @EXPORT = qw(scpi_match);

=head1 NAME

Lab::SCPI - Match L<SCPI|http://www.ivifoundation.org/scpi/> headers and
parameters against keywords. 

This module exports a single function:

=head2 scpi_match($header, @keywords)

Return true, if C<$header> matches any of the SCPI keywords given in C<@keywords>.

=head3 Examples

The calls

 scpi_match($header, 'voltage[:APERture]')
 scpi_match($header, qw/voltage CURRENT resistance/)
 scpi_match($header, '[:abcdef]:ghi[:jkl]')

are convenient replacements for

 $header =~ /^(voltage:aperture|voltage:aper|voltage|volt:aperture|volt:aper|volt)$/i
 $header =~ /^(voltage|volt|current|curr|resistance|res)$/i
 $header =~ /^(:abcdef:ghi:jkl|:abcdef:ghi|:abcd:ghi:jkl|:abcd:ghi|:ghi:jkl|:ghi)$/i

respectively.

Leading and trailing whitespace is removed from the first argument, before
 matching against the keywords.

=head3 Keyword Structure

See Sec. 6 "Program Headers" in the SCPI spec. The colon is optional for the
first mnemonic. There must be at least one non-optional mnemonic in the
keyword.

C<scpi_match> will throw, if it is given an invalid keyword.

=cut

sub scpi_match {
	my $header = shift;
	for my $keyword (@_) {
		if (match_keyword($header, $keyword)) {
			return 1;
		}
	}
	return 0;
}


sub parse_keyword {
	my $keyword = shift;

	# For the first part, the colon is optional.
	my $start_mnemonic_regex = qr/(?<mnemonic>:?[a-z][a-z0-9_]*)/i;
	my $mnemonic_regex = qr/(?<mnemonic>:[a-z][a-z0-9_]*)/i;
	my $keyword_regex = qr/\[$mnemonic_regex\]|$mnemonic_regex/;
	my $start_regex = qr/\[$start_mnemonic_regex\]|$start_mnemonic_regex/;

	# check if keyword is valid
	if (length($keyword) == 0) {
		croak "keyword with empty length";
	}
	
	if ($keyword !~ /^${start_regex}${keyword_regex}*$/) {
		croak "invalid keyword: '$keyword'";
	}

	if ($keyword !~ /\[/) {
		# no more optional parts
		return $keyword;
	}

	#recurse
	return (parse_keyword($keyword =~ s/\[(.*?)\]/$1/r),
		parse_keyword($keyword =~ s/\[(.*?)\]//r));
}
       
sub scpi_shortform {
	my $string = shift;
	if (length($string) <= 4) {
		return $string;
	}
	
	if (substr($string, 3, 1) =~ /[aeiou]/i) {
		return substr($string, 0, 3);
	}
	else {
		return substr($string, 0, 4);
	}
}

# Return 1 for equal, 0 if not.
sub compare_headers {
	my $a = shift;
	my $b = shift;
	
	my @a = split(/:/, $a, -1);
	my @b = split(/:/, $b, -1);

	if (@a != @b) {
		return 0;
	}
	while (@a) {
		my $a = shift @a;
		my $b = shift @b;
		$a = "\L$a";
		$b = "\L$b";
		if ($b ne $a and $b ne scpi_shortform($a)) {
			return 0;
		}
	}
	return 1;
}

# Return 1 for match, 0 for no match.
sub match_keyword {
	my $header = shift;
	my $keyword = shift;

	# strip leading and trailing whitespace
	$header =~ s/^\s*//;
	$header =~ s/\s*$//;
	
	my @combinations = parse_keyword($keyword);
	for my $combination (@combinations) {
		if (compare_headers($combination, $header)) {
			return 1;
		}
	}
	return 0;
}

1;
