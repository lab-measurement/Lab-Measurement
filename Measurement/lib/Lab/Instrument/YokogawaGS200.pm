package Lab::Instrument::YokogawaGS200;
our $VERSION = '2.93';

use strict;
use Switch;
use Lab::Instrument;
use Lab::Instrument::Source;


our @ISA=('Lab::Instrument::Source');

my %fields = (
	supported_connections => [ 'VISA_GPIB', 'GPIB', 'VISA', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => 0,
		gpib_address => 22,
	},

	device_settings => {
		gate_protect            => 1,
		gp_equal_level          => 1e-5,
		gp_max_volt_per_second  => 0.05,
		gp_max_volt_per_step    => 0.005,
		gp_max_step_per_second  => 10,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,
	},
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__, \%fields);

	# already called in Lab::Instrument::Source, but call it again to respect default values in local channel_defaultconfig
	$self->configure($self->config());
    
    return $self;
}

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub _set_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    $self->_set_auto($voltage);
}

sub set_current {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub _set {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf(":SOURce:LEVel %e",$value);
	$self->connection()->Write( command  => $cmd );
}

sub _set_auto {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf(":SOURce:LEVel:AUTO %e",$value);
	$self->connection()->Write( command  => $cmd );
}

sub set_setpoint {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("S%+.4e",$value);
	$self->connection()->Write( command  => $cmd );
}

sub set_time {
    my $self=shift;
    my $sweep_time=shift; #sec.
    my $interval_time=shift;
    if ($sweep_time<$self->device_settings('min_sweep_time')) {
        warn "Warning Sweep Time: $sweep_time smaller than ${\$self->device_settings('min_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('min_sweep_time')} sec";
        $sweep_time=$self->device_settings('min_sweep_time')}
    elsif ($sweep_time>$self->device_settings('max_sweep_time')) {
        warn "Warning Sweep Time: $sweep_time> ${\$self->device_settings('max_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('max_sweep_time')} sec";
        $sweep_time=$self->device_settings('max_sweep_time')
    };
    if ($interval_time<$self->device_settings('min_sweep_time')) {
        warn "Warning Interval Time: $interval_time smaller than ${\$self->device_settings('min_sweep_time')} sec!\n Interval time set to ${\$self->device_settings('min_sweep_time')} sec";
        $interval_time=$self->device_settings('min_sweep_time')}
    elsif ($interval_time>$self->device_settings('max_sweep_time')) {
        warn "Warning Interval Time: $interval_time> ${\$self->device_settings('max_sweep_time')} sec!\n Interval time set to ${\$self->device_settings('max_sweep_time')} sec";
        $interval_time=$self->device_settings('max_sweep_time')
    };
    my $cmd=sprintf("PI%.1f",$interval_time);
	$self->connection()->Write( command  => $cmd );
    $cmd=sprintf("SW%.1f",$sweep_time);
	$self->connection()->Write( command  => $cmd );
}

sub start_program {
    my $self=shift;
    my $cmd=sprintf("PRS");
	$self->connection()->Write( command  => $cmd );
}

sub end_program {
    my $self=shift;
    my $cmd=sprintf("PRE");
	$self->connection()->Write( command  => $cmd );
}
sub execute_program {
    # 0 HALT
    # 1 STEP
    # 2 RUN
    #3 Continue
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("RU%d",$value);
	$self->connection()->Write( command  => $cmd );
    
}

sub sweep {
    my $self=shift;
    my $stop=shift;
    my $rate=shift;
    my $return_rate=$rate;
    $self->execute_program(0);
    my $output_now=$self->_get();
    #Test if $stop in range
    my $range=$self->get_range();
    #Start Programming-----
    $self->start_program();
    if ($stop>$range){
        $stop=$range;
    }
    elsif ($stop< -$range) {
        $stop=-$range;
    }
    $self->set_setpoint($stop);
    $self->end_program();

    my $time=abs($output_now -$stop)/$rate;
    if ($time<$self->device_settings('min_sweep_time')) {
        warn "Warning Sweep Time: $time smaller than ${\$self->device_settings('min_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('min_sweep_time')} sec";
        $time=$self->device_settings('min_sweep_time');
        $return_rate=abs($output_now -$stop)/$time;
    }
    elsif ($time>$self->device_settings('max_sweep_time')) {
        warn "Warning Interval Time: $time> ${\$self->device_settings('max_sweep_time')} sec!\n Sweep time set to ${\$self->device_settings('max_sweep_time')} sec";
        $time=$self->device_settings('max_sweep_time');
        $return_rate=abs($output_now -$stop)/$time;
    }
    $self->set_time($time,$time);
    $self->execute_program(2);
    return $return_rate;
}

sub _get_voltage {
    my $self=shift;
    return $self->_get();
}

sub get_current {
    my $self=shift;
    return $self->_get();
}

sub _get {
    my $self=shift;
    my $cmd=":SOURce:LEVel?";
    my $result=$self->connection()->Query( command  => $cmd );
    return $result;
}

sub set_current_mode {
    my $self=shift;
    my $cmd="F5";
    $self->connection()->Write( command  => $cmd );
}

sub set_voltage_mode {
    my $self=shift;
    my $cmd="F1";
    $self->connection()->Write( command  => $cmd );
}

sub set_range {
    my $self=shift;
    my $range=shift;
    my $cmd="R$range";
      #fixed voltage mode
      # 2   10mV
      # 3   100mV
      # 4   1V
      # 5   10V
      # 6   30V
      #fixed current mode
      # 4   1mA
      # 5   10mA
      # 6   100mA
    $self->connection()->Write( command  => $cmd );
}

sub get_info {
    my $self=shift;
    $self->connection()->Write( command  => "OS" );
    my @info;
    for (my $i=0;$i<=10;$i++){
        my $line=$self->connection()->Read( read_length => 300 );
        if ($line=~/END/){last};
        chomp $line;
        $line=~s/\r//;
        push(@info,sprintf($line));
    };
    return @info;
}

sub get_range{
    my $self=shift;
    my @info=$self->get_OS();
    my $result=$info[1];
    my $func_nr=0;
    my $range_nr=0;
    my $range=0;
    #printf "$result\n";
    if ($result=~/F(\d)R(\d)/){
    $func_nr=$1;
    #printf "funcnr=$func_nr\n";
    $range_nr=$2;
    #    printf "rangenr=$range_nr\n";
    }
    if ($func_nr==1){ # DC V
        switch ($range_nr) {
            case 2 {$range=10e-3} #10mV
            case 3 {$range=100e-3} #100mV
            case 4 {$range=1} #1V
            case 5 {$range=10} #10V
            case 6 {$range=30} #30V
            else { Lab::Exception::CorruptParameter->throw( error=>"Range $range_nr not defined\n" . Lab::Exception::Base::Appendix() ); }
        }
    }
    elsif ($func_nr==5){
        switch ($range_nr) {
            case 4 {$range=1e-3} #1mA
            case 5 {$range=10e-3} #10mA
            case 6 {$range=100e-3} #100mA
            else { Lab::Exception::CorruptParameter->throw( error=>"Range $range_nr not defined\n" . Lab::Exception::Base::Appendix() ); }
        }
    }
    else { Lab::Exception::CorruptParameter->throw( error=>"Function not defined: $func_nr\n" . Lab::Exception::Base::Appendix() ); }
    #printf "$range\n";
    return $range
    
}

sub set_run_mode {
    my $self=shift;
    my $value=shift;
    if ($value!=0 and $value!=1) { Lab::Exception::CorruptParameter->throw( error=>"Run Mode $value not defined\n" . Lab::Exception::Base::Appendix() ); }
    my $cmd=sprintf("M%u",$value);
    $self->connection()->Write( command  => $cmd );
}

sub output_on {
    my $self=shift;
    $self->connection()->Write( command  => ':OUTP 1' );
}
    
sub output_off {
    my $self=shift;
    $self->connection()->Write( command  => ':OUTP 0' );
}

sub get_output {
    my $self=shift;
    my %res=$self->get_status();
    return $res{output};
}

sub initialize {
    my $self=shift;
    $self->connection()->Write( command  => 'RC' );
}

sub set_voltage_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LV%e",$value);
    $self->connection()->Write( command  => $cmd );
}

sub set_current_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LA%e",$value);
    $self->connection()->Write( command  => 'RC' );
}

sub get_status {
    my $self=shift;
    my $status=$self->connection()->Write( command  => 'OC' );
    
    $status=~/STS1=(\d*)/;
    $status=$1;
    my @flags=qw/
        CAL_switch  memory_card calibration_mode    output
        unstable    error   execution   setting/;
    my %result;
    for (0..7) {
        $result{$flags[$_]}=$status&128;
        $status<<=1;
    }
    return %result;
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::YokogawaGS200 - Yokogawa GS200 DC source

=head1 SYNOPSIS

    use Lab::Instrument::YokogawaGS200;
    
    my $gate14=new Lab::Instrument::YokogawaGS200(
      connection_type => 'LinuxGPIB',
      gpib_address => 22,
    );
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::YokogawaGS200 class implements an interface to the
discontinued voltage and current source GS200 by Yokogawa. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_range($range)

    Fixed voltage mode
    2   10mV
    3   100mV
    4   1V
    5   10V
    6   30V

    Fixed current mode
    4   1mA
    5   10mA
    6   100mA

=head2 get_info()

Returns the information provided by the instrument's 'OS' command, in the form of an array
with one entry per line. For display, use join(',',$yoko->get_info()); or similar.

=head2 output_on()

Sets the output switch to on.

=head2 output_off()

Sets the output switch to off. The instrument outputs no voltage
or current then, no matter what voltage you set.

=head2 get_output()

Returns the status of the output switch (0 or 1).

=head2 initialize()

=head2 set_voltage_limit($limit)

=head2 set_current_limit($limit)

=head2 get_status()

Returns a hash with the following keys:

    CAL_switch
    memory_card
    calibration_mode
    output
    unstable
    error
    execution
    setting

The value for each key is either 0 or 1, indicating the status of the instrument.

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4


=item * Lab::Instrument

The YokogawaGP200 class is a Lab::Instrument (L<Lab::Instrument>).

=item * Lab::Instrument::Source

The YokogawaGP200 class is a Source (L<Lab::Instrument::Source>)

=back

=head1 AUTHOR/COPYRIGHT

 (c) 2004-2006 Daniel Schröer
 (c) 2007-2010 Daniel Schröer, Daniela Taubert, Andreas K. Hüttel, and others
 (c) 2011 Florian Olbrich, Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
