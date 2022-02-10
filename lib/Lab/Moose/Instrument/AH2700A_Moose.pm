package Lab::Moose::Instrument::AH2700A;
#ABSTRACT: Andeen-Hagerling AH2700A ultra-precision capacitance bridge

use v5.20;

use strict;
use Time::HiRes qw (usleep);
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    setter_params
/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time usleep/;
use Lab::Moose 'linspace';

extends 'Lab::Moose::Instrument';


sub BUILD {
    my $self = shift;
    $self->get_id();
}

sub set_frq {
	my ( $self, $frq, %args ) = validated_setter( \@_,
        frq  => { isa => enum(50..20000) },
    );

	$self->write( command => sprintf("FREQ %d", $freq), %args ); 
}

sub get_frq {
    my $self = shift;

    my $result = $self->query( command => sprintf("SH FR") );

    $result =~ /(\D+)(\d+\.\d+)(\D+)/;

    return $result;
}

sub set_aver {
	my ( $self, $aver, %args ) = validated_setter( \@_,
        aver => { isa => enum(0..15) },
    );

    $self->write( command => sprintf( "AV %d", $aver ), %args );
}

sub get_aver {
    my $self = shift;

    my $result = $self->query( command => sprintf("SH AV") );

    $result =~ /(\D+)(\D+\=)(\d+)/;

    return $3;
}

sub set_bias {
	my ( $self, $bias, %args ) = validated_setter( \@_,
        bias => { isa => enum([qw/ OFF IHIGH ILOW /]) },
    );
    
    $self->write( command => sprintf( "BI %s", $bias ), %args );
}

sub get_bias {
    my $self = shift;

    my $result = $self->query( command => sprintf("SH BI") );

    $result =~ /(\D+\s)(\D+)/;

    return $result;
}

sub set_bright {
	my ( $self, $bias, %args ) = validated_setter( \@_,
        bright1 => { isa => enum([qw/ ALL C LOS OT /]) },
        bright2 => { isa => enum(0..9) },
    );

    if ( $bright1 eq 'ALL' ) {
        $self->write( command => sprintf( "BR %s %d", $bright1, $bright2 ), %args );
    }
    elsif ( $bright1 eq 'C' ) {
        $self->write( command => sprintf( "BR %s %d", $bright1, $bright2 ), %args );
    }
    elsif ( $bright1 eq 'LOS' ) {
        $self->write( command => sprintf( "BR %s %d", $bright1, $bright2 ), %args );
    }
    elsif ( $bright1 eq 'OT' ) {
        $self->write( command => sprintf( "BR %s %d", $bright1, $bright2 ), %args );
    }
}

sub get_bright {
    my $self = shift;

    my $result = $self->query( command => sprintf("SH BR") );

    $result =~ /(\D+\s)(\D\=\d\s\D\=\d\s\D\=\d)/;

    return $result;
}

sub set_cable {
	my ( $self, $bias, %args = validated_setter( \@_,
        cab1 => { isa => enum([qw/ L RES I C /]) },
        cab2 => { isa => 'Str' },
    );

    $self->write( command => sprintf( "CAB %s %d", $cab1, $cab2 ), %args );
}

sub get_cable {
    my $self = shift;

    my $result = $self->write( command => sprintf("SH CAB") );

    my @results;

    for ( my $i = 0; $i < 4; $i++ ) {
        my $result = $self->read();
        push( @results, $result );
    }

    print " @results ";

    return @results;
}

# What?
# Does this function get everything the device can return and 
# gives only a single one to get_value()?
# Is self->request() still available in Moose?
# What is $tail and can it be simply substituted by %args?
sub get_single {
	my $self = shift;

	# Implement cache; just use Lab::Moose::Instrument::Cache
	# and write cache id => (getter => 'get_id') for all get
	# functions?
    my $average  = $self->get_aver();
    my $frequency = $self->get_frq();

	# Rewrite with hash
    my $time_table_highf = {
        0  => [ 0.28,  80 ],
        1  => [ 0.29,  110 ],
        2  => [ 0.30,  150 ],
        3  => [ 0.33,  200 ],
        4  => [ 0.37,  260 ],
        5  => [ 0.44,  350 ],
        6  => [ 0.58,  520 ],
        7  => [ 3.2,   3200 ],
        8  => [ 4.8,   5200 ],
        9  => [ 7.2,   8800 ],
        10 => [ 12.0,  16000 ],
        11 => [ 20.0,  28000 ],
        12 => [ 36.0,  56000 ],
        13 => [ 68.0,  108000 ],
        14 => [ 140.0, 220000 ],
        15 => [ 280.0, 480000 ],
    };

    my $timeout = @{ $time_table_highf->{$average} }[0]
        + @{ $time_table_highf->{$average} }[1] / $frequency;

    if ( exists($args{'timeout'}) ) {
        $args{'timeout'} = 100;
    }

    my $result = $self->write( command => sprintf("SI"), %args );
    
    # Rewrite with hash
    my %values;
    while ( $result =~ /([A-Z])=\s(\d+\.\d+)/g ) {
        $values{"$1"} = $2;
    }
    $values{E} = 00;
    if ( $result =~ /^(\d+)/ and $result != /00/ ) {
        $values{"E"} = $1;
        warn ("AH2700A: Error in get_single. Errorcode = "
                . $values{"E"} . "\n" );
    }
    
    $values{"C"} = $values{"C"}*1e-12;
    $values{"L"} = $values{"L"}*1e-9;

    return %values;
}

sub get_value {
    my $self = shift;

    return $self->get_single(@_);
}

sub set_wait {
    my ( $self, $wait, %args ) = validated_setter( \@_,
        wait => { isa => 'Num' },
    );

    $self->write( command => sprintf( "WAIT DELAY %d", $wait ), %args );

}

# controls which fields are sent to GPIB port
sub set_field {
    my ( $self, $wait, %args ) = validated_setter( \@_,
		fi1 => { isa => 'Str' },
    	fi2 => { isa => 'Str' },
		fi3 => { isa => 'Num' },
		fi4 => { isa => 'Num' },
		fi5 => { isa => 'Str' },
		fi6 => { isa => 'Str' },
    );

    $self->write( command => 
        sprintf(
            "FIELD %s,%s,%d,%d,%s,%s", $fi1, $fi2, $fi3, $fi4, $fi5, $fi6
        ), %args
    );
}

sub set_volt {
    my ( $self, $wait, %args ) = validated_setter( \@_,
        volt => { isa => 'Num' },
    );

    $self->write( command => sprintf( "V %2.2f", $volt ), %args );
}

