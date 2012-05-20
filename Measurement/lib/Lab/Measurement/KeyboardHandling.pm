#!/usr/bin/perl -w

package Lab::Measurement::KeyboardHandling;
our $VERSION = '2.96';

use Term::ReadKey;

sub labkey_safe_exit {
  ReadMode('normal');
  exit(@_);
}

sub labkey_init {
  $SIG{'INT'} = \&labkey_safe_exit;
  $SIG{'QUIT'} = \&labkey_safe_exit;
  $SIG{__DIE__} = \&labkey_safe_exit;
  END { labkey_safe_exit(); }
  ReadMode( 'raw' );
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

  if ( defined ( my $key = ReadKey( -1 ) ) ) {
    # input waiting; it's in $key
    if ($key eq 'q') { 
      print "Terminating on keyboard request\n";
      exit; 
    };
  };
}


1;
