#!/usr/bin/perl -w

package Lab::Bus::DEBUG::HumanInstrument;
our $VERSION = '3.00';

use strict;
use base "Wx::App";
use Wx qw(wxTE_MULTILINE wxDefaultPosition);

sub OnInit {

	my $frame = Wx::Frame->new( undef,           # parent window
		-1,              # ID -1 means any
		'wxPerl rules',  # title
		[-1, -1],         # default position
		[300, 300],       # size
	);

	my $textpane = new Wx::TextCtrl($frame, -1, "blablub", wxDefaultPosition, [300,300], wxTE_MULTILINE);
 	#my $textPane = Wx::StaticText->new($frame,   # Parent window
#                                     -1,       # no window id
#                                     'Welcome to the world of WxPerl!',
#                                     [20, 20], # Position
#                                    );


	$frame->Show( 1 );
}



1;


=pod

=encoding utf-8

=head1 NAME

Lab::Bus::DEBUG::HumanInstrument - interactive debug bus with WxWindow interface


=head1 DESCRIPTION

This will be an interactive debug bus, which prints out the commands sent by the 
measurement script, and lets you manually enter the instrument responses.

Unfinished, needs testing. 


=head1 AUTHOR/COPYRIGHT

 (c) Florian Olbrich 2011

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut


