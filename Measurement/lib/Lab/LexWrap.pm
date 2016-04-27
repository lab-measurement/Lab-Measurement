# patched version of Hook::LexWrap, without this patch Carp put error messages
# into it's stack traces.
# Patch: rt.cpan.org/Public/Bug/Display.html?id=103186

# Once this is fixed in the CPAN we can delete this module.

use strict;
use warnings;
package Lab::LexWrap;


use Lab::Generic;
# git description: v0.24-8-gd2290ba
$Lab::LexWrap::VERSION = '0.25';
# ABSTRACT: Lexically scoped subroutine wrappers

use Carp;

{
no warnings 'redefine';
*CORE::GLOBAL::caller = sub (;$) {
	my ($height) = ($_[0]||0);
	my $i=1;
	my $name_cache;
	while (1) {
		my @caller = CORE::caller() eq 'DB' 
		    ? do { package DB; CORE::caller($i++) } :
		    CORE::caller($i++) 
		    or return; 
		$caller[3] = $name_cache if $name_cache;
		$name_cache = $caller[0] eq 'Lab::LexWrap' ? $caller[3] : '';
		next if $name_cache || $height-- != 0;
		return wantarray ? @_ ? @caller : @caller[0..2] : $caller[0];
	}
};
}

sub import { no strict 'refs'; *{caller()."::wrap"} = \&wrap }

sub wrap (*@) {  ## no critic Prototypes
	my ($typeglob, %wrapper) = @_;
	$typeglob = (ref $typeglob || $typeglob =~ /::/)
		? $typeglob
		: caller()."::$typeglob";
	my $original;
	{
	        no strict 'refs';
	        $original = ref $typeglob eq 'CODE' && $typeglob
		     || *$typeglob{CODE}
		     || croak "Can't wrap non-existent subroutine ", $typeglob;
	}
	croak "'$_' value is not a subroutine reference"
		foreach grep {$wrapper{$_} && ref $wrapper{$_} ne 'CODE'}
			qw(pre post);
	no warnings 'redefine';
	my ($caller, $unwrap) = *CORE::GLOBAL::caller{CODE};
	my $imposter = sub {
		if ($unwrap) { goto &$original }
		my ($return, $prereturn);
		if (wantarray) {
			$prereturn = $return = [];
			() = $wrapper{pre}->(@_,$return) if $wrapper{pre};
			if (ref $return eq 'ARRAY' && $return == $prereturn && !@$return) {
				$return = [ &$original ];
				() = $wrapper{post}->(@_, $return)
					if $wrapper{post};
			}
			return ref $return eq 'ARRAY' ? @$return : ($return);
		}
		elsif (defined wantarray) {
			$return = bless sub {$prereturn=1}, 'Lab::LexWrap::Cleanup';
			my $dummy = $wrapper{pre}->(@_, $return) if $wrapper{pre};
			unless ($prereturn) {
				$return = &$original;
				$dummy = scalar $wrapper{post}->(@_, $return)
					if $wrapper{post};
			}
			return $return;
		}
		else {
			$return = bless sub {$prereturn=1}, 'Lab::LexWrap::Cleanup';
			$wrapper{pre}->(@_, $return) if $wrapper{pre};
			unless ($prereturn) {
				&$original;
				$wrapper{post}->(@_, $return)
					if $wrapper{post};
			}
			return;
		}
	};
	ref $typeglob eq 'CODE' and return defined wantarray
		? $imposter
		: carp "Uselessly wrapped subroutine reference in void context";
	{
	        no strict 'refs';
	        *{$typeglob} = $imposter;
	}
	return unless defined wantarray;
	return bless sub{ $unwrap=1 }, 'Lab::LexWrap::Cleanup';
}

package Lab::LexWrap::Cleanup;
# git description: v0.24-8-gd2290ba
$Lab::LexWrap::Cleanup::VERSION = '0.25';

sub DESTROY { $_[0]->() }
use overload 
	q{""}   => sub { undef },
	q{0+}   => sub { undef },
	q{bool} => sub { undef },
	q{fallback}=>1; #fallback=1 - like no overloading for other operations

1;
