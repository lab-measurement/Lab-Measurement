#!/usr/bin/env perl

# Ensure that Lab::Measurement::Manual contains links to all of our modules.
use 5.010;
use warnings;
use strict;
use File::Slurper 'read_binary';
use File::Find;
use Data::Dumper;

my $manual = read_binary('lib/Lab/Measurement/Manual.pod');

my @module_links = $manual =~ /L<(Lab::.*?)>/g;

# Create lookup table
my %module_links = map { $_ => 1 } @module_links;

my @source_files;

find(
    {
        wanted => sub {
            my $file = $_;
            if ( $file =~ /\.(pm|pod)$/ ) {
                push @source_files, $file;
            }
        },
        no_chdir => 1,
    },
    'lib'
);

@source_files = map {
    my $file = $_;
    $file =~ s{^lib/}{};
    $file =~ s{\.(pm|pod)$}{};
    $file =~ s{/}{::}g;
    $file;
} @source_files;

my %source_files = map { $_ => 1 } @source_files;

# The following legacy modules are not required in the manual
my @whitelist = qw/
    Lab::Measurement::Manual

    Lab::Moose::Connection::VISA_GPIB

    Lab::MultiChannelInstrument
    Lab::GenericSignals
    Lab::Generic
    Lab::Exception
    Lab::Generic::CLOptions
    Lab::Bus::VICP

    Lab::Data::Analysis::TekTDS
    Lab::Data::Analysis::WaveRunner

    Lab::Connection::Mock
    Lab::Connection::VICP
    Lab::Connection::LogMethodCall
    Lab::Connection::Trace
    Lab::Connection::TCPraw
    Lab::Connection::Log
    Lab::Connection::VICP::Trace
    Lab::Connection::Socket::Trace
    Lab::Connection::DEBUG::Trace
    Lab::Connection::DEBUG::Log
    Lab::Connection::USBtmc::Trace
    Lab::Connection::VISA_GPIB::Trace
    Lab::Connection::VISA_GPIB::Log
    Lab::Connection::LinuxGPIB::Trace
    Lab::Connection::LinuxGPIB::Log

    Lab::Measurement::Developer::Write-A-Source-Driver

    Lab::MultiChannelInstrument::DeviceCache

    Lab::XPRESS::hub
    Lab::XPRESS::Utilities::Utilities
    Lab::XPRESS::Data::XPRESS_plotter
    Lab::XPRESS::Data::XPRESS_logger
    Lab::XPRESS::Data::XPRESS_DataFile
    Lab::XPRESS::Sweep::PulsePeriod
    Lab::XPRESS::Sweep::SweepND
    Lab::XPRESS::Sweep::Frequency
    Lab::XPRESS::Sweep::DietersCrazyTempSweep
    Lab::XPRESS::Sweep::VM_DIR
    Lab::XPRESS::Sweep::Dummy
    Lab::XPRESS::Sweep::Power

    Lab::Instrument::OI_IPS
    Lab::Instrument::MagnetSupply
    Lab::Instrument::TemperatureDiode
    Lab::Instrument::TemperatureDiode::RO600
    Lab::Instrument::TemperatureDiode::SI420
    Lab::Instrument::SpectrumSCPI
    Lab::Instrument::AH2700A
    Lab::Instrument::Agilent34420A
    Lab::Instrument::LabViewHeater
    Lab::Instrument::Vectormagnet
    Lab::Instrument::AgilentE8362A
    Lab::Instrument::Lakeshore224
    Lab::Instrument::IPSWeissDilfridge

    Lab::Exception::Base

    /;

for my $white (@whitelist) {
    delete $source_files{$white};
}

# FIXME: check that remaining modules actually contain pod (e.g. =head1 ...)

my $have_dead_links;

# Check for dead module links
say "Dead links:";
for my $link ( keys %module_links ) {
    if ( not exists $source_files{$link} ) {
        say $link;
        $have_dead_links = 1;
    }
}

my $have_unlinked_modules;

say "Unlinked modules:";
for my $source ( keys %source_files ) {
    if ( not exists $module_links{$source} ) {
        say $source;
        $have_unlinked_modules = 1;
    }
}

if ( $have_dead_links || $have_unlinked_modules ) {
    die "Error\n";
}

