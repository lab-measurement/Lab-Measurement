#!/usr/bin/perl

use strict;
use Lab::VISA;

# Initialize VISA system and
# Open default resource manager
my ($status,$default_rm)=Lab::VISA::viOpenDefaultRM();
if ($status != $Lab::VISA::VI_SUCCESS) {
    die "Cannot open resource manager: $status";
}

# Open one resource (an instrument)
my $gpib=21;            # we want to open the instrument
my $board=0;            # with GPIB address 21
                        # connected to GPIB board 0 in our computer

my $resource_name=sprintf("GPIB%u::%u::INSTR",$board,$gpib);

($status, my $instr)=Lab::VISA::viOpen(
    $default_rm,        # the resource manager session
    $resource_name,     # a string describing the 
    $Lab::VISA::VI_NULL,# access mode (no special mode)
    $Lab::VISA::VI_NULL # time out for open (no time out)
);

if ($status != $Lab::VISA::VI_SUCCESS) {
    die "Cannot open instrument $resource_name. status: $status";
}

# We set a time out for communication with this instrument
$status=Lab::VISA::viSetAttribute(
    $instr,             # the session identifier
    $Lab::VISA::VI_ATTR_TMO_VALUE,  # which attribute to modify
    3000                # the new value
);
if ($status != $Lab::VISA::VI_SUCCESS) {
    die "Error while setting timeout value: $status";
}

# Clear the instrument
my $status=Lab::VISA::viClear($instr);
if ($status != $Lab::VISA::VI_SUCCESS) {
    die "Error while clearing instrument: $status";
}

# Now we are going to send one command and read the result.

# We send the simple SCPI command "*IDN?" which asks the instrument
# to identify itself. Of course the instrument must support this
# command, in order to make this example work.
my $cmd="*IDN?";
($status, my $write_cnt)=Lab::VISA::viWrite(
    $instr,             # the session identifier 
    $cmd,               # the command to send
    length($cmd)        # the length of the command in bytes
);
if ($status != $Lab::VISA::VI_SUCCESS) {
    die "Error while writing: $status";
}

# Now we will read the instruments reply
($status,               # indicates if the operation was successful
 my $result,            # the answer string
 my $read_cnt)=         # the length of the answer in bytes
    Lab::VISA::viRead(
       $instr,          # the session identifier
       300              # read 300 bytes
    );
if ($status != $Lab::VISA::VI_SUCCESS) {
    die "Error while reading: $status";
}
# The result string will be 300 bytes long, but only $read_cnt
# bytes are part of the answer. We cut away the rest.
$result=substr($result,0,$read_cnt);

print $result;

# As good citizens we'll cleanup now.
# Close the instrument
$status=Lab::VISA::viClose($instr);
# And the resource manager
$status=Lab::VISA::viClose($default_rm);
