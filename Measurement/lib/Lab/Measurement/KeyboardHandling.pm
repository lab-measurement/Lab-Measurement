#!/usr/bin/perl -w

package Lab::Measurement::KeyboardHandling;
our $VERSION = '3.10';

use Term::ReadKey;

my $labkey_initialized=0;

sub labkey_safe_exit {
  ReadMode('normal');
  exit(@_);
}

sub labkey_safe_int {
    ReadMode('normal');
    exit(1);
}

sub labkey_safe_die {
    ReadMode('normal');
    # In order to print stack trace do not call exit(@_) here. 
}

sub labkey_init {
  $SIG{'INT'} = \&labkey_safe_int;
  $SIG{'QUIT'} = \&labkey_safe_exit;
  $SIG{__DIE__} = \&labkey_safe_die;
  END { labkey_safe_exit(); }
  ReadMode( 'raw' );
  $labkey_initialized=1;
};

# sub labkey_push_stop_handler
# sub labkey_pop_stop_handler

# sub labkey_push_pause_handler
# sub labkey_pop_pause_handler

# sub labkey_push_resume_handler
# sub labkey_pop_resume_handler

sub labkey_check {
  # handle as much as we can here directly
  # q - exit safely, if necessary using a given handler which stops sweeps
  # p - ?? pause, i.e. output "Measurement paused, press any key to continue"
  # t - output script timing info

  if (( $labkey_initialized == 1 ) && ( defined ( my $key = ReadKey( -1 ) ) )) {
    # input waiting; it's in $key
    if ($key eq 'q') { 
      print "Terminating on keyboard request\n";
      exit; 
    };
  };
}


1;
