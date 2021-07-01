use Lab::Moose;
use Class::Unload;

Class::Unload->unload('Lab::Moose::Instrument::Rigol_DG5000');

use lib '/media/fabian/Volume/fabian/Documents/Uni/Bachelor Arbeit/Perl/lib';
use Lab::Moose::Instrument::Rigol_DG5000;
use Lab::Moose::Instrument::KeysightDSOS604A;

my $source = instrument(
    type            => 'Rigol_DG5000',
    connection_type => 'USB',
    connection_options => {host => '192.168.3.34'},
);

my $osc = instrument(
  type => 'KeysightDSOS604A',
  connection_type => 'VXI11',
  connection_options => {host => '192.168.3.33'},
);

my $delay = 0.000000300;
my $amp = 1;
my $scal = 2;
my $cycles = 1;


# falls das hier nur allgemeine Initialisierung ist, dann brauchst Du das nicht
# wirklich in $before_loop, sonder kannst es auch einfach direkt ins
# hauptprogramm schreiben
my $before_loop = sub {
  $source->output_toggle(channel => 1, value => 'OFF');
  $source->output_toggle(channel => 2, value => 'OFF');
  $source->source_function_shape(channel => 1, value => 'PULSE');
  $source->source_apply_pulse(channel => 1, freq => 1/$delay, amp => $amp, offset => $amp/2, delay => $delay);
  $source->output_toggle(channel => 1, value => 'ON');

  $osc->write(command => ":DIGitize CHANnel1");
  $osc->write(command => ":CHANnel1:DISPlay ON");

  #
  $osc->write(command => ":WAVeform:FORMat FLOat" ); # Setup transfer format
  $osc->write(command => ":WAVeform:BYTeorder LSBFirst" ); # Setup transfer of LSB first
  $osc->write(command => ":WAVeform:SOURce CHANnel1" ); # Waveform data ata source channel 1
  $osc->write(command => ":WAVeform:STReaming ON" ); # Turn on waveform streaming of data
  # einen Teil davon können wir soweit sinnvoll in die allgemeine Initialisierung des Geräts
  # in KeysightDSOS604A.pm stecken

  $osc->timebase_reference(value => 'LEFT');
  $osc->timebase_ref_perc(value => 5);
  $osc->channel_input(channel => 'CHANnel1', parameter => 'DC50');
  # $osc->acquire_points(value => 10000);
  $osc->write(command => ":TRIGger:EDGE:SOURce CHANnel1");
  $osc->write(command => ":TRIGger:EDGE:SLOPe POSitive");
};

my $sweep = sweep(
    type       => 'Step::Pulsewidth',
    instrument => $source,
    from => 0.000000005, to => 0.000000100, step => 0.000000005,
    before_loop => $before_loop,
);

my $datafile = sweep_datafile(columns => [qw/pulsewidth time voltage/]);

$datafile->add_plot(
   x => 'time',
   y => 'voltage',
);

my $meas = sub {
    my $sweep = shift;

    $osc->write(command => ':SINGle');
    # was macht das genau? 1) es löst eine "aufnahme" aus, d.h. warten auf trigger und
    # dann aufnehmen? oder 2) es schaltet in den single-trace modus um?
    # wenn 1) dann wäre das doch eigentlich besser in einer funktion "get_trace" oÄ im
    # KeysightDSOS604A.pm aufgehoben
    # wenn 2), dann "generelle Initialisierung" wie oben schon, muß nicht jedesmal hier
    # wiederholt werden!

    $osc->channel_offset(channel => 'CHANnel1', offset => $amp/(2*$scal));
    $osc->channel_range(channel => 'CHANnel1', range => 1.5*$amp/$scal);
    $osc->trigger_level(channel => 'CHANnel1', level => $amp/(2*$scal));
    my $pulsewidth = $source->get_pulsewidth();
    $osc->timebase_range(value => $cycles*($pulsewidth+$delay));
    # ist OK so, aber später wollen wir die verschiedenen spuren vielleicht miteinander
    # vergleichen, dh es wäre auch gut wenn sie mit gleichen parametern aufgenommen sind
    # -> i.d.R. einmal vorher ausrechnen und setzen, dann gleich lassen

    my $voltages = $osc->get_waveform_voltage();
    my $xOrg = $osc->query(command => ":WAVeform:XORigin?");
    my $xInc = $osc->query(command => ":WAVeform:XINCrement?");
    my @time;
    foreach (1..@$voltages) {@time[$_-1] = $_*$xInc+$xOrg}
    # das solltest Du auf jeden Fall in KeysightDSOS604A.pm verschieben, siehe auch
    # Kommentare dort
    # "Idee": das Modul soll uns alle "Standardvorgänge" abnehmen

    $sweep->log_block(
        prefix => {pulsewidth => $pulsewidth},
        block => [\@time, $voltages]
    );
};

$sweep->start(
    measurement => $meas,
    datafile    => $datafile,
    datafile_dim => 1,
    point_dim => 1,
);
