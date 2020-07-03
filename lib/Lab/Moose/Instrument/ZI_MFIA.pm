package Lab::Moose::Instrument::ZI_MFIA;

#ABSTRACT: Zurich Instruments MFIA Impedance Analyzer.

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

use Lab::Moose::Instrument 'timeout_param';
use Lab::Moose::Instrument::Cache;

extends 'Lab::Moose::Instrument::ZI_MFLI';

=head1 SYNOPSIS

 use Lab::Moose;

 my $mfia = instrument(
     type => 'ZI_MFIA',
     connection_type => 'Zhinst',
     connection_options => {
         host => '132.188.12.13',
         port => 8004,
     });

 $mfia->set_frequency(value => 10000);

 # Get impedance sample
 my $sample = $mfia->get_impedance_sample();
 my $real = $sample->{realz};
 my $imag = $sample->{imagz};
 my $parameter_1 = $sample->{param0};
 my $parameter_2 = $sample>{param1};

=head1 METHODS

Supports all methods provided by L<Lab::Moose::Instrument::ZI_MFLI>.

=head2 get_impedance_sample

 my $sample = $mfia->get_impedance_sample(timeout => $timeout);
 # keys in $sample: timeStamp, realz, imagz, frequency, phase, flags, trigger,
 # param0, param1, drive, bias
 
Return impedance sample as hashref. C<$timeout> argument is optional.

=cut

sub get_impedance_sample {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
    );
    return $self->sync_poll(
        path => $self->device() . "/imps/0/sample",
        %args
    );
}

# FIXME: warn/croak on AUTO freq, bw, ...

__PACKAGE__->meta()->make_immutable();

1;
